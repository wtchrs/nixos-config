package applications

import (
	"crypto/sha256"
	"errors"
	"fmt"
	"image/png"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// entry is a discovered Windows shortcut and its desktop metadata.
type entry struct {
	ID             string
	Name           string
	Description    string
	Icon           string
	Shortcut       string
	ShortcutPath   string
	StartupWMClass string

	// Names and Descriptions use desktop locale suffix keys: "" for the default,
	// "[ko]", "[en_US]", etc. for localized values.
	Names        map[string]string
	Descriptions map[string]string
}

var errCatalogTraversal = errors.New("parent traversal")
var catalogThemeIcon = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_.-]*$`)
var catalogUninstall = regexp.MustCompile(`(?i)\b(uninstall(?:er)?|remove)\b`)
var catalogKoreanUninstall = regexp.MustCompile(`(^|[^\p{L}\p{N}_])(제거|삭제|언인스톨)($|[^\p{L}\p{N}_])`)

func catalogIsUninstall(value string) bool {
	return catalogUninstall.MatchString(value) || catalogKoreanUninstall.MatchString(value)
}

func catalogRoot(prefix string) string {
	return filepath.Join(prefix, "drive_c", "proton_shortcuts")
}

// Invalid candidates are isolated; directory/read failures remain visible to callers.
func catalogCandidates(prefix string) ([]string, error) {
	items, err := os.ReadDir(catalogRoot(prefix))
	if os.IsNotExist(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var paths []string
	for _, item := range items {
		if !item.IsDir() && strings.HasSuffix(item.Name(), ".desktop") {
			paths = append(paths, filepath.Join(catalogRoot(prefix), item.Name()))
		}
	}
	return paths, nil
}

// Candidates may disappear between listing the directory and opening the file.
func catalogReadCandidate(path string) (map[string]string, error) {
	values, err := readDesktopEntry(path)
	if os.IsNotExist(err) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read candidate %s: %w", path, err)
	}
	return values, nil
}

// Exec has two escape layers: desktop strings, then quoted argument syntax.
func catalogShortcut(raw string) (string, error) {
	argument, err := parseExecArgument(raw)
	if err != nil {
		return "", err
	}
	if len(argument) < 4 || !((argument[0] >= 'a' && argument[0] <= 'z') || (argument[0] >= 'A' && argument[0] <= 'Z')) || argument[1] != ':' || (argument[2] != '\\' && argument[2] != '/') || !strings.HasSuffix(strings.ToLower(argument), ".lnk") || strings.ContainsAny(argument, "\x00\r\n") {
		return "", fmt.Errorf("invalid Windows shortcut")
	}
	return argument, nil
}

// entryID returns the stable prefix-scoped identity of a valid Windows shortcut.
func entryID(prefix string, shortcut string) string {
	parts := strings.FieldsFunc(shortcut[2:], func(r rune) bool { return r == '\\' || r == '/' })
	var clean []string
	for _, part := range parts {
		if part == "." {
			continue
		}
		if part == ".." {
			if len(clean) > 0 {
				clean = clean[:len(clean)-1]
			}
			continue
		}
		clean = append(clean, strings.ToLower(part))
	}
	normalized := strings.ToLower(shortcut[:2]) + `\` + strings.Join(clean, `\`)
	sum := sha256.Sum256([]byte(prefix + "\x00" + normalized))
	return fmt.Sprintf("wr1-%x", sum[:12])
}

// Missing suffix components retain their requested spelling for the watcher.
func catalogResolve(prefix string, shortcut string) (string, error) {
	drive := strings.ToLower(shortcut[:1])
	root := filepath.Join(prefix, "dosdevices", drive+":")
	if _, err := os.Stat(root); err != nil {
		if !os.IsNotExist(err) {
			return "", err
		}
		if drive == "c" {
			root = filepath.Join(prefix, "drive_c")
		}
	}
	parts := strings.FieldsFunc(shortcut[2:], func(r rune) bool { return r == '\\' || r == '/' })
	for _, part := range parts {
		if part == "." {
			continue
		}
		if part == ".." {
			return "", errCatalogTraversal
		}
		items, err := os.ReadDir(root)
		if err != nil && !os.IsNotExist(err) {
			return "", err
		}
		actual := part
		for _, item := range items {
			if item.Name() == part {
				actual = part
				break
			}
			if strings.EqualFold(item.Name(), part) {
				actual = item.Name()
			}
		}
		root = filepath.Join(root, actual)
	}
	return root, nil
}

func catalogLocalized(values map[string]string, key string) map[string]string {
	out := map[string]string{}
	for k, v := range values {
		if k == key || (strings.HasPrefix(k, key+"[") && strings.HasSuffix(k, "]")) {
			if decoded, err := decodeDesktopValue(v); err == nil {
				out[strings.TrimPrefix(k, key)] = decoded
			}
		}
	}
	return out
}

func catalogIcon(prefix string, value string) string {
	value, err := decodeDesktopValue(value)
	if err != nil || value == "" {
		return ""
	}
	if filepath.IsAbs(value) {
		if info, err := os.Stat(value); err == nil && info.Mode().IsRegular() {
			return value
		}
		return ""
	}
	bestPath := ""
	var largestArea int64 = -1
	_ = filepath.WalkDir(filepath.Join(catalogRoot(prefix), "icons"), func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.EqualFold(filepath.Ext(d.Name()), ".png") {
			return nil
		}
		if d.Name() != value && d.Name() != value+".png" {
			return nil
		}
		file, err := os.Open(path)
		if err != nil {
			return nil
		}
		info, err := png.DecodeConfig(file)
		file.Close()
		if err != nil {
			return nil
		}
		score := int64(info.Width) * int64(info.Height)
		if score > largestArea {
			bestPath = path
			largestArea = score
		}
		return nil
	})
	if bestPath != "" {
		return bestPath
	}
	if catalogThemeIcon.MatchString(value) {
		return value
	}
	return ""
}

// Scan discovers valid shortcut entries under prefix.
func Scan(prefix string) ([]entry, error) {
	paths, err := catalogCandidates(prefix)
	if err != nil {
		return nil, err
	}
	result := []entry{}
	seen := map[string]bool{}
	for _, path := range paths {
		values, err := catalogReadCandidate(path)
		if values == nil && err == nil {
			continue
		}
		if err != nil {
			return nil, err
		}
		if values["Type"] != "" && values["Type"] != "Application" {
			continue
		}
		if strings.EqualFold(values["Hidden"], "true") || strings.EqualFold(values["NoDisplay"], "true") {
			continue
		}
		shortcut, err := catalogShortcut(values["Exec"])
		if err != nil {
			continue
		}
		resolved, err := catalogResolve(prefix, shortcut)
		if errors.Is(err, errCatalogTraversal) {
			continue
		}
		if err != nil {
			return nil, fmt.Errorf("resolve %s: %w", path, err)
		}
		info, err := os.Stat(resolved)
		if os.IsNotExist(err) {
			continue
		}
		if err != nil {
			return nil, fmt.Errorf("stat shortcut %s: %w", resolved, err)
		}
		if !info.Mode().IsRegular() {
			continue
		}
		names := catalogLocalized(values, "Name")
		descriptions := catalogLocalized(values, "Comment")
		if descriptions[""] == "" {
			descriptions = catalogLocalized(values, "GenericName")
		}
		name := names[""]
		if name == "" {
			continue
		}
		filtered := false
		for _, n := range names {
			if catalogIsUninstall(n) {
				filtered = true
			}
		}
		if filtered || catalogIsUninstall(shortcut) {
			continue
		}
		id := entryID(prefix, shortcut)
		if seen[id] {
			continue
		}
		seen[id] = true
		wmClass, _ := decodeDesktopValue(values["StartupWMClass"])
		result = append(result, entry{
			ID:             id,
			Name:           name,
			Description:    descriptions[""],
			Icon:           catalogIcon(prefix, values["Icon"]),
			Shortcut:       shortcut,
			ShortcutPath:   resolved,
			StartupWMClass: wmClass,
			Names:          names,
			Descriptions:   descriptions,
		})
	}
	sort.Slice(result, func(i, j int) bool {
		firstName := strings.ToLower(result[i].Name)
		secondName := strings.ToLower(result[j].Name)
		if firstName == secondName {
			return result[i].ID < result[j].ID
		}
		return firstName < secondName
	})
	return result, nil
}

// watchPaths includes candidate directories even for missing or filtered shortcuts.
func watchPaths(prefix string) ([]string, error) {
	paths, err := catalogCandidates(prefix)
	if err != nil {
		return nil, err
	}
	dirs := map[string]bool{
		catalogRoot(prefix):                         true,
		filepath.Join(catalogRoot(prefix), "icons"): true,
		filepath.Join(prefix, "dosdevices"):         true,
	}
	for _, path := range paths {
		values, err := catalogReadCandidate(path)
		if values == nil && err == nil {
			continue
		}
		if err != nil {
			return nil, err
		}
		shortcut, err := catalogShortcut(values["Exec"])
		if err != nil {
			continue
		}
		resolved, err := catalogResolve(prefix, shortcut)
		if errors.Is(err, errCatalogTraversal) {
			continue
		}
		if err != nil {
			return nil, fmt.Errorf("resolve %s: %w", path, err)
		}
		dirs[filepath.Dir(resolved)] = true
	}
	err = filepath.WalkDir(filepath.Join(catalogRoot(prefix), "icons"), func(path string, d fs.DirEntry, err error) error {
		if os.IsNotExist(err) {
			return nil
		}
		if err != nil {
			return err
		}
		if d.IsDir() {
			dirs[path] = true
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	result := make([]string, 0, len(dirs))
	for path := range dirs {
		result = append(result, path)
	}
	sort.Strings(result)
	return result, nil
}
