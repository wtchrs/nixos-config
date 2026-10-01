package applications

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"unicode"
)

// decodeDesktopValue decodes desktop string escapes.
func decodeDesktopValue(value string) (string, error) {
	var decoded strings.Builder
	for i := 0; i < len(value); i++ {
		if value[i] != '\\' {
			decoded.WriteByte(value[i])
			continue
		}
		i++
		if i == len(value) {
			return "", fmt.Errorf("trailing escape")
		}
		switch value[i] {
		case 's':
			decoded.WriteByte(' ')
		case 'n':
			decoded.WriteByte('\n')
		case 't':
			decoded.WriteByte('\t')
		case 'r':
			decoded.WriteByte('\r')
		case '\\':
			decoded.WriteByte('\\')
		case '"':
			decoded.WriteByte('"')
		default:
			return "", fmt.Errorf("invalid escape")
		}
	}
	return decoded.String(), nil
}

// readDesktopEntry returns raw values from the Desktop Entry section.
func readDesktopEntry(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	values := map[string]string{}
	active := false
	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 4096), 1024*1024)
	for scanner.Scan() {
		line := strings.TrimSpace(strings.TrimPrefix(scanner.Text(), "\ufeff"))
		if strings.HasPrefix(line, "[") {
			active = line == "[Desktop Entry]"
			continue
		}
		if !active || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if ok {
			values[strings.TrimSpace(key)] = strings.TrimSpace(value)
		}
	}
	return values, scanner.Err()
}

// escapeDesktopValue encodes a desktop string value.
func escapeDesktopValue(value string) string {
	return strings.NewReplacer("\\", `\\`, "\n", `\n`, "\r", `\r`, "\t", `\t`).Replace(value)
}

// execArgument encodes a single quoted literal Exec argument.
func execArgument(value string) string {
	value = strings.ReplaceAll(value, "%", "%%")
	value = strings.NewReplacer("\\", `\\`, `"`, `\"`, "`", "\\`", "$", `\$`).Replace(value)
	return escapeDesktopValue(`"` + value + `"`)
}

// parseExecArgument decodes one desktop Exec argument, including literal percent escapes.
func parseExecArgument(raw string) (string, error) {
	argument, err := decodeDesktopValue(strings.TrimSpace(raw))
	if err != nil {
		return "", err
	}
	if strings.HasPrefix(argument, `"`) {
		var decoded strings.Builder
		closed := false
		for i := 1; i < len(argument); i++ {
			c := argument[i]
			if c == '"' {
				if strings.TrimSpace(argument[i+1:]) != "" {
					return "", fmt.Errorf("extra Exec arguments")
				}
				closed = true
				break
			}
			if c == '\\' && i+1 < len(argument) && strings.ContainsRune("\\\"`$", rune(argument[i+1])) {
				i++
				c = argument[i]
			}
			decoded.WriteByte(c)
		}
		if !closed {
			return "", fmt.Errorf("unclosed Exec quote")
		}
		argument = decoded.String()
	} else if strings.IndexFunc(argument, unicode.IsSpace) >= 0 || strings.ContainsAny(argument, "\"'`$") {
		return "", fmt.Errorf("invalid Exec argument")
	}
	// Only literal percent escapes are permitted, never desktop field codes.
	var decoded strings.Builder
	for i := 0; i < len(argument); i++ {
		if argument[i] == '%' {
			if i+1 >= len(argument) || argument[i+1] != '%' {
				return "", fmt.Errorf("Exec field code")
			}
			i++
		}
		decoded.WriteByte(argument[i])
	}
	argument = decoded.String()
	return argument, nil
}
