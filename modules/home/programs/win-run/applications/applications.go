// Package applications discovers shortcuts and reconciles prefix-owned desktop files.
// It also owns shared watcher leases and path canonicalization.
package applications

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// Registry provides the paths needed to publish prefix-owned applications.
type Registry struct{ Prefix, DataHome, Executable string }

var managedDesktopName = regexp.MustCompile(`^win-run-wr1-[0-9a-f]{24}\.desktop$`)

func desktopWriteLocales(output *strings.Builder, key string, values map[string]string, prefix string) {
	var locales []string
	for locale := range values {
		if locale != "" {
			locales = append(locales, locale)
		}
	}
	sort.Strings(locales)
	for _, locale := range locales {
		fmt.Fprintf(output, "%s%s=%s\n", key, locale, escapeDesktopValue(prefix+values[locale]))
	}
}

func desktopRender(cfg Registry, item entry) []byte {
	var output strings.Builder
	output.WriteString("[Desktop Entry]\nType=Application\nCategories=Utility;\nX-Win-Run-Managed=true\n")
	fmt.Fprintf(&output, "X-Win-Run-Prefix=%s\n", escapeDesktopValue(cfg.Prefix))
	fmt.Fprintf(&output, "Name=%s\n", escapeDesktopValue("win-run: "+item.Name))
	desktopWriteLocales(&output, "Name", item.Names, "win-run: ")
	if item.Description != "" {
		fmt.Fprintf(&output, "Comment=%s\n", escapeDesktopValue(item.Description))
	}
	desktopWriteLocales(&output, "Comment", item.Descriptions, "")
	if item.Icon != "" {
		fmt.Fprintf(&output, "Icon=%s\n", escapeDesktopValue(item.Icon))
	}
	if item.StartupWMClass != "" {
		fmt.Fprintf(&output, "StartupWMClass=%s\n", escapeDesktopValue(item.StartupWMClass))
	}
	fmt.Fprintf(&output, "Exec=%s launch %s --prefix %s\nTerminal=false\n", execArgument(cfg.Executable), item.ID, execArgument(cfg.Prefix))
	return []byte(output.String())
}

func desktopOwned(cfg Registry, path string) (bool, error) {
	if !managedDesktopName.MatchString(filepath.Base(path)) {
		return false, nil
	}
	info, err := os.Lstat(path)
	if os.IsNotExist(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if !info.Mode().IsRegular() {
		return false, nil
	}
	values, err := readDesktopEntry(path)
	if os.IsNotExist(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	prefix, err := decodeDesktopValue(values["X-Win-Run-Prefix"])
	return err == nil && values["X-Win-Run-Managed"] == "true" && prefix == cfg.Prefix, nil
}

func desktopAtomic(path string, data []byte, exists bool) error {
	temporary, err := os.CreateTemp(filepath.Dir(path), ".win-run-*")
	if err != nil {
		return err
	}
	defer os.Remove(temporary.Name())
	if err = temporary.Chmod(0644); err == nil {
		_, err = temporary.Write(data)
	}
	if err == nil {
		err = temporary.Sync()
	}
	closeErr := temporary.Close()
	if err != nil {
		return err
	}
	if closeErr != nil {
		return closeErr
	}
	if !exists {
		// Link publishes atomically without clobbering an arriving unrelated file.
		return os.Link(temporary.Name(), path)
	}
	return os.Rename(temporary.Name(), path)
}

func desktopSyncEntry(cfg Registry, applicationsDir string, item entry) error {
	path := filepath.Join(applicationsDir, "win-run-"+item.ID+".desktop")
	_, err := os.Lstat(path)
	exists := err == nil
	if err != nil && !os.IsNotExist(err) {
		return err
	}
	if exists {
		owned, err := desktopOwned(cfg, path)
		if err != nil {
			return err
		}
		if !owned {
			return nil
		}
	}
	contents := desktopRender(cfg, item)
	if exists {
		previous, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if bytes.Equal(previous, contents) {
			return nil
		}
	}
	return desktopAtomic(path, contents, exists)
}

func desktopRemoveStale(cfg Registry, applicationsDir string, desiredNames map[string]bool) error {
	files, err := os.ReadDir(applicationsDir)
	if err != nil {
		return err
	}
	for _, file := range files {
		if desiredNames[file.Name()] {
			continue
		}
		path := filepath.Join(applicationsDir, file.Name())
		owned, err := desktopOwned(cfg, path)
		if err != nil {
			return err
		}
		if owned {
			if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
				return err
			}
		}
	}
	return nil
}

// Sync reconciles desktop files owned by this prefix.
func (cfg Registry) Sync() error {
	if !filepath.IsAbs(cfg.Prefix) || !filepath.IsAbs(cfg.DataHome) || !filepath.IsAbs(cfg.Executable) {
		return fmt.Errorf("win-run configuration paths must be absolute")
	}
	// Finish discovery before modifying applications: filesystem errors must not
	// turn an incomplete catalog into deletion of valid managed entries.
	entries, err := Scan(cfg.Prefix)
	if err != nil {
		return err
	}
	applicationsDir := filepath.Join(cfg.DataHome, "applications")
	if err := os.MkdirAll(applicationsDir, 0755); err != nil {
		return err
	}
	desiredNames := map[string]bool{}
	for _, item := range entries {
		desiredNames["win-run-"+item.ID+".desktop"] = true
		if err := desktopSyncEntry(cfg, applicationsDir, item); err != nil {
			return err
		}
	}
	return desktopRemoveStale(cfg, applicationsDir, desiredNames)
}
