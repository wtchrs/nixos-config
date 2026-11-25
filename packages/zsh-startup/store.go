package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

// reportDir is where reports go when --save does not name a file:
// $XDG_CACHE_HOME/zsh-startup, or ~/.cache/zsh-startup.
func reportDir() (string, error) {
	cache, err := os.UserCacheDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(cache, "zsh-startup"), nil
}

// reportFileName sorts by time, so the newest report sorts last. The name
// uses UTC, so that the order holds across time zone and DST changes.
func reportFileName(report Report) string {
	host := strings.Map(func(r rune) rune {
		if r == '/' || r == ' ' {
			return '-'
		}
		return r
	}, report.Meta.Host)
	return report.Meta.Time.UTC().Format("20060102T150405Z") + "-" + host + ".json"
}

// encodeJSON is the one JSON encoding for saved reports and for --json, so
// that both produce the same bytes.
func encodeJSON(value any) ([]byte, error) {
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(data, '\n'), nil
}

// saveReport writes the report to path, or to the report directory when path
// is empty, and returns the file it wrote.
func saveReport(report Report, path string) (string, error) {
	if path == "" {
		dir, err := reportDir()
		if err != nil {
			return "", err
		}
		err = os.MkdirAll(dir, 0o755)
		if err != nil {
			return "", err
		}
		path = filepath.Join(dir, reportFileName(report))
	}

	data, err := encodeJSON(report)
	if err != nil {
		return "", err
	}

	err = os.WriteFile(path, data, 0o644)
	if err != nil {
		return "", err
	}
	return path, nil
}

func loadReport(path string) (Report, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Report{}, err
	}

	var report Report
	err = json.Unmarshal(data, &report)
	if err != nil {
		return Report{}, fmt.Errorf("%s: %w", path, err)
	}
	if report.Schema != schemaVersion {
		return Report{}, fmt.Errorf("%s: report schema %d, expected %d", path, report.Schema, schemaVersion)
	}
	return report, nil
}

// latestReport returns the newest report in dir.
func latestReport(dir string) (string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return "", err
	}

	var names []string
	for _, entry := range entries {
		if entry.Type().IsRegular() && strings.HasSuffix(entry.Name(), ".json") {
			names = append(names, entry.Name())
		}
	}
	if len(names) == 0 {
		return "", fmt.Errorf("no saved report in %s; run zsh-startup first", dir)
	}

	slices.Sort(names)
	return filepath.Join(dir, names[len(names)-1]), nil
}
