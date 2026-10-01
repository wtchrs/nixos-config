package applications

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// AbsolutePath expands a leading home abbreviation and returns an absolute path.
func AbsolutePath(path, home string) (string, error) {
	if path == "~" {
		path = home
	} else if strings.HasPrefix(path, "~/") {
		path = filepath.Join(home, path[2:])
	}
	return filepath.Abs(path)
}

// CanonicalPath resolves symlinks even when the final path does not exist yet.
func CanonicalPath(path string) (string, error) {
	return canonicalAtDepth(path, 0)
}

func canonicalAtDepth(path string, depth int) (string, error) {
	if depth > 40 {
		return "", fmt.Errorf("too many symbolic links resolving %s", path)
	}
	ancestor := path
	var suffix []string
	for {
		resolved, err := filepath.EvalSymlinks(ancestor)
		if err == nil {
			return appendSuffix(resolved, suffix), nil
		}
		if !errors.Is(err, os.ErrNotExist) || filepath.Dir(ancestor) == ancestor {
			return "", err
		}
		// Resolve a dangling link's target ancestry explicitly so mapped drives
		// retain their physical watch locations while moved away.
		info, statErr := os.Lstat(ancestor)
		if statErr == nil && info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Readlink(ancestor)
			if err != nil {
				return "", err
			}
			if !filepath.IsAbs(target) {
				target = filepath.Join(filepath.Dir(ancestor), target)
			}
			resolved, err := canonicalAtDepth(target, depth+1)
			if err != nil {
				return "", err
			}
			return appendSuffix(resolved, suffix), nil
		}
		if statErr != nil && !errors.Is(statErr, os.ErrNotExist) {
			return "", statErr
		}
		suffix = append(suffix, filepath.Base(ancestor))
		ancestor = filepath.Dir(ancestor)
	}
}

func appendSuffix(path string, suffix []string) string {
	for index := len(suffix) - 1; index >= 0; index-- {
		path = filepath.Join(path, suffix[index])
	}
	return path
}
