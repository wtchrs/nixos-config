package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestLatestReportPicksTheNewestFile(t *testing.T) {
	dir := t.TempDir()

	older := Report{Schema: schemaVersion, Meta: Meta{Host: "box", Time: time.Date(2026, 11, 25, 9, 0, 0, 0, time.UTC)}}
	newer := Report{Schema: schemaVersion, Meta: Meta{Host: "box", Time: time.Date(2026, 11, 25, 10, 0, 0, 0, time.UTC)}}

	for _, report := range []Report{newer, older} {
		_, err := saveReport(report, filepath.Join(dir, reportFileName(report)))
		if err != nil {
			t.Fatal(err)
		}
	}
	err := os.WriteFile(filepath.Join(dir, "notes.txt"), []byte("not a report"), 0o644)
	if err != nil {
		t.Fatal(err)
	}

	latest, err := latestReport(dir)
	if err != nil {
		t.Fatal(err)
	}
	if filepath.Base(latest) != reportFileName(newer) {
		t.Errorf("latest = %s, want %s", filepath.Base(latest), reportFileName(newer))
	}

	loaded, err := loadReport(latest)
	if err != nil {
		t.Fatal(err)
	}
	if !loaded.Meta.Time.Equal(newer.Meta.Time) {
		t.Errorf("loaded time = %v, want %v", loaded.Meta.Time, newer.Meta.Time)
	}
}

func TestReportFileNamesSortAcrossTimeZones(t *testing.T) {
	// 10:00 in UTC+9 is 01:00 UTC, so it is earlier than 09:00 UTC.
	earlier := Report{Meta: Meta{Host: "box", Time: time.Date(2026, 11, 25, 10, 0, 0, 0, time.FixedZone("KST", 9*60*60))}}
	later := Report{Meta: Meta{Host: "box", Time: time.Date(2026, 11, 25, 9, 0, 0, 0, time.UTC)}}

	if reportFileName(earlier) >= reportFileName(later) {
		t.Errorf("%s should sort before %s", reportFileName(earlier), reportFileName(later))
	}
}

func TestReportJSONMatchesTheSavedFile(t *testing.T) {
	report := Report{
		Schema:    schemaVersion,
		Meta:      Meta{Host: "box", Time: time.Date(2026, 11, 25, 9, 0, 0, 0, time.UTC)},
		Startup:   computeStats([]float64{230, 240}),
		Functions: []FunctionCost{{Name: "compinit", Calls: 2, Self: 18, Total: 82}},
	}

	path, err := saveReport(report, filepath.Join(t.TempDir(), "report.json"))
	if err != nil {
		t.Fatal(err)
	}
	saved, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}

	printed, err := encodeJSON(report)
	if err != nil {
		t.Fatal(err)
	}
	if string(printed) != string(saved) {
		t.Error("--json output differs from the saved report")
	}
}

func TestLatestReportFailsWithoutReports(t *testing.T) {
	_, err := latestReport(filepath.Join(t.TempDir(), "missing"))
	if err == nil || !strings.Contains(err.Error(), "no saved report") {
		t.Errorf("err = %v, want a no saved report error", err)
	}
}

func TestLoadReportRejectsOtherSchemas(t *testing.T) {
	path := filepath.Join(t.TempDir(), "old.json")
	err := os.WriteFile(path, []byte(`{"schema": 0}`), 0o644)
	if err != nil {
		t.Fatal(err)
	}

	_, err = loadReport(path)
	if err == nil || !strings.Contains(err.Error(), "schema") {
		t.Errorf("err = %v, want a schema error", err)
	}
}
