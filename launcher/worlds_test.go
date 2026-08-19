package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func setupGameRoot(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	worldsDir := filepath.Join(root, "worlds")
	if err := os.MkdirAll(worldsDir, 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("BETACRAFT_GAME_DIR", root)
	return root
}

func TestSanitizeName(t *testing.T) {
	cases := map[string]string{
		"  My World  ":          "My World",
		"a/b\\c:d*e?f\"g<h>i|j": "abcdefghij",
		"  ":                    "New World",
		"...x...":               "x",
		"no#change=":            "nochange",
	}
	for in, want := range cases {
		if got := sanitizeName(in); got != want {
			t.Errorf("sanitizeName(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestSeedString(t *testing.T) {
	if s, err := seedString("123"); err != nil || s != "123" {
		t.Errorf("seedString(123) = %q, %v", s, err)
	}
	if s, err := seedString("-42"); err != nil || s != "-42" {
		t.Errorf("seedString(-42) = %q, %v", s, err)
	}
	if _, err := seedString("abc"); err == nil {
		t.Error("expected error for non-numeric seed")
	}
	if _, err := seedString(""); err != nil {
		t.Errorf("empty seed should produce a random one, got error %v", err)
	}
}

func TestCreateWorldFilesAndSeed(t *testing.T) {
	root := setupGameRoot(t)

	name, err := createWorld("Alpha World", "12345")
	if err != nil {
		t.Fatal(err)
	}
	if name != "Alpha World" {
		t.Fatalf("created name = %q, want %q", name, "Alpha World")
	}

	dir := filepath.Join(root, "worlds", name)
	for _, f := range []string{"world.mt", "map_meta.txt"} {
		if _, err := os.Stat(filepath.Join(dir, f)); err != nil {
			t.Errorf("missing %s in new world: %v", f, err)
		}
	}

	worldMt, _ := os.ReadFile(filepath.Join(dir, "world.mt"))
	if !strings.Contains(string(worldMt), "gameid = "+filepath.Base(root)) {
		t.Errorf("world.mt missing gameid = %s:\n%s", filepath.Base(root), worldMt)
	}
	if !strings.Contains(string(worldMt), "world_name = Alpha World") {
		t.Errorf("world.mt missing world_name:\n%s", worldMt)
	}

	meta, _ := os.ReadFile(filepath.Join(dir, "map_meta.txt"))
	s := string(meta)
	if !strings.Contains(s, "seed = 12345") {
		t.Errorf("map_meta.txt seed not set:\n%s", s)
	}
	// Nested noise parameters must keep their own seeds.
	for _, block := range []string{"seed = 90003", "seed = 13", "seed = 5349", "seed = 842"} {
		if !strings.Contains(s, block) {
			t.Errorf("map_meta.txt lost block seed %q:\n%s", block, s)
		}
	}
}

func TestCreateWorldRandomSeedAndDedup(t *testing.T) {
	setupGameRoot(t)

	first, err := createWorld("New World", "")
	if err != nil {
		t.Fatal(err)
	}
	if first != "New World" {
		t.Fatalf("first = %q", first)
	}
	second, err := createWorld("New World", "")
	if err != nil {
		t.Fatal(err)
	}
	if second != "New World (1)" {
		t.Fatalf("second = %q, want %q", second, "New World (1)")
	}
	third, err := createWorld("New World", "")
	if err != nil {
		t.Fatal(err)
	}
	if third != "New World (2)" {
		t.Fatalf("third = %q, want %q", third, "New World (2)")
	}

	meta, _ := os.ReadFile(filepath.Join(gameRoot(), "worlds", first, "map_meta.txt"))
	if strings.Contains(string(meta), "seed = 17553435335444202355") {
		t.Errorf("default template seed should have been replaced by a random one:\n%s", meta)
	}
}

func TestScanAndDeleteWorlds(t *testing.T) {
	setupGameRoot(t)

	if worlds := scanWorlds(); len(worlds) != 0 {
		t.Fatalf("expected no worlds, got %d", len(worlds))
	}
	if _, err := createWorld("One", "1"); err != nil {
		t.Fatal(err)
	}
	if _, err := createWorld("Two", "2"); err != nil {
		t.Fatal(err)
	}

	// "One" gets touched later, so recency sorting puts it on top.
	now := time.Now()
	if err := os.Chtimes(filepath.Join(gameRoot(), "worlds", "One", "world.mt"), now, now); err != nil {
		t.Fatal(err)
	}

	worlds := scanWorlds()
	if len(worlds) != 2 {
		t.Fatalf("expected 2 worlds, got %d", len(worlds))
	}
	if worlds[0].Name != "One" || worlds[1].Name != "Two" {
		t.Fatalf("unexpected order: %v", worlds)
	}
	if worlds[0].Path != filepath.Join(gameRoot(), "worlds", "One") {
		t.Errorf("unexpected path: %q", worlds[0].Path)
	}
	if worlds[0].LastPlayed < worlds[1].LastPlayed {
		t.Errorf("expected One to have a more recent LastPlayed, got %d vs %d",
			worlds[0].LastPlayed, worlds[1].LastPlayed)
	}

	if err := deleteWorld("One"); err != nil {
		t.Fatal(err)
	}
	if worlds := scanWorlds(); len(worlds) != 1 {
		t.Fatalf("expected 1 world after delete, got %d", len(worlds))
	}
}
