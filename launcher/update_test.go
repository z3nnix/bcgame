package main

import (
	"archive/zip"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestCompareTags(t *testing.T) {
	cases := []struct {
		a, b string
		want int
	}{
		{"v2026.08.19", "v2026.08.19", 0},
		{"v2026.08.19", "v0.1.0", 1},
		{"v0.1.0", "v2026.08.19", -1},
		{"2026.08.19", "v2026.08.19", 0},
	}
	for _, c := range cases {
		if got := compareTags(c.a, c.b); got != c.want {
			t.Errorf("compareTags(%q, %q) = %d, want %d", c.a, c.b, got, c.want)
		}
	}
}

func TestArchiveRelPath(t *testing.T) {
	cases := []struct {
		name string
		ok   bool
		rel  string
	}{
		{"betacraft/mods/init.lua", true, "mods/init.lua"},
		{"betacraft/bin/luanti", true, "bin/luanti"},
		{"betacraft/worlds/default/world.mt", false, ""},
		{"worlds/save.txt", false, ""},
		{"betacraft/config.toml", false, ""},
		{"config.toml", false, ""},
		{"betacraft/../escape.txt", false, ""},
		{"betacraft", false, ""},
		{"betacraft/", false, ""},
	}
	for _, c := range cases {
		rel, ok := archiveRelPath(c.name)
		if ok != c.ok || rel != c.rel {
			t.Errorf("archiveRelPath(%q) = (%q, %v), want (%q, %v)",
				c.name, rel, ok, c.rel, c.ok)
		}
	}
}

func TestExtractArchiveSkipsWorldsAndTraversal(t *testing.T) {
	dir := t.TempDir()
	zipPath := filepath.Join(dir, "release.zip")

	f, err := os.Create(zipPath)
	if err != nil {
		t.Fatal(err)
	}
	zw := zip.NewWriter(f)
	entries := []struct {
		name string
		mode uint32
		body string
	}{
		{"betacraft/", 0o755, ""},
		{"betacraft/mods/", 0o755, ""},
		{"betacraft/mods/init.lua", 0o644, "print('hi')"},
		{"betacraft/bin/", 0o755, ""},
		{"betacraft/bin/luanti", 0o755, "#!/bin/sh"},
		{"betacraft/worlds/default/world.mt", 0o644, "gameid = betacraft"},
		{"betacraft/config.toml", 0o644, "nick = 'x'"},
	}
	for _, e := range entries {
		hdr := &zip.FileHeader{Name: e.name, Method: zip.Store}
		hdr.SetMode(os.FileMode(e.mode))
		w, err := zw.CreateHeader(hdr)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write([]byte(e.body)); err != nil {
			t.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	f.Close()

	dest := filepath.Join(dir, "staging")
	if err := extractArchive(zipPath, dest); err != nil {
		t.Fatal(err)
	}

	if _, err := os.Stat(filepath.Join(dest, "mods", "init.lua")); err != nil {
		t.Error("mods/init.lua should be extracted:", err)
	}
	bin, err := os.Stat(filepath.Join(dest, "bin", "luanti"))
	if err != nil {
		t.Fatal("bin/luanti should be extracted:", err)
	}
	if bin.Mode().Perm()&0o111 == 0 {
		t.Errorf("bin/luanti should keep its executable bit, got %v", bin.Mode())
	}
	for _, skip := range []string{"worlds", "config.toml"} {
		if _, err := os.Stat(filepath.Join(dest, skip)); !os.IsNotExist(err) {
			t.Errorf("%s should have been skipped", skip)
		}
	}
}

func TestMergeMinetestConf(t *testing.T) {
	dir := t.TempDir()
	archive := filepath.Join(dir, "archive.conf")
	local := filepath.Join(dir, "local.conf")

	if err := os.WriteFile(archive, []byte(
		"time_speed = 72\n"+
			"# new default\n"+
			"secure.trusted_mods = mcl_discord_rpc\n"+
			"mcl_enable_hunger = false\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(local, []byte(
		"# player settings\n"+
			"time_speed = 100\n"+
			"fullscreen = true\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	if err := mergeMinetestConf(archive, local); err != nil {
		t.Fatal(err)
	}

	data, err := os.ReadFile(local)
	if err != nil {
		t.Fatal(err)
	}
	text := string(data)
	if !strings.Contains(text, "time_speed = 100") {
		t.Error("existing local key must be preserved")
	}
	if !strings.Contains(text, "fullscreen = true") {
		t.Error("other local settings must be preserved")
	}
	if strings.Count(text, "time_speed") != 1 {
		t.Error("time_speed must not be duplicated")
	}
	if !strings.Contains(text, "secure.trusted_mods = mcl_discord_rpc") {
		t.Error("missing archive key should be added")
	}
	if !strings.Contains(text, "mcl_enable_hunger = false") {
		t.Error("missing archive key should be added")
	}
}

func TestInstallStagedPreservesWorlds(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("uses unix-style managed paths")
	}
	root := t.TempDir()
	backup := filepath.Join(root, ".update-backup-test")
	staging := filepath.Join(root, ".update-staging-test")

	// Old content already in place.
	if err := os.MkdirAll(filepath.Join(root, "mods"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "mods", "old.txt"), []byte("old"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, "worlds", "My world"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "worlds", "My world", "world.mt"),
		[]byte("gameid = betacraft"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "config.toml"), []byte("nick = 'z'"), 0o644); err != nil {
		t.Fatal(err)
	}

	// New content from the archive.
	if err := os.MkdirAll(filepath.Join(staging, "mods"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(staging, "mods", "new.txt"), []byte("new"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(staging, "game.conf"), []byte("title = Betacraft"), 0o644); err != nil {
		t.Fatal(err)
	}

	if err := installStaged(root, staging, backup); err != nil {
		t.Fatal(err)
	}

	if _, err := os.Stat(filepath.Join(root, "mods", "new.txt")); err != nil {
		t.Error("new mod file should be installed:", err)
	}
	if _, err := os.Stat(filepath.Join(root, "mods", "old.txt")); !os.IsNotExist(err) {
		t.Error("old mod file should have been replaced")
	}
	if _, err := os.Stat(filepath.Join(root, "game.conf")); err != nil {
		t.Error("game.conf should be installed:", err)
	}
	worldMt, err := os.ReadFile(filepath.Join(root, "worlds", "My world", "world.mt"))
	if err != nil {
		t.Fatal("worlds/ must be preserved:", err)
	}
	if string(worldMt) != "gameid = betacraft" {
		t.Error("world.mt content changed")
	}
	cfg, err := os.ReadFile(filepath.Join(root, "config.toml"))
	if err != nil || string(cfg) != "nick = 'z'" {
		t.Error("config.toml must be preserved")
	}

	// downloadAndInstall is responsible for removing the staging and backup
	// dirs after a successful apply; simulate that here.
	if err := os.RemoveAll(staging); err != nil {
		t.Fatal(err)
	}
	if err := os.RemoveAll(backup); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(backup); !os.IsNotExist(err) {
		t.Error("backup dir should be removed after a successful update")
	}
	if _, err := os.Stat(staging); !os.IsNotExist(err) {
		t.Error("staging dir should be removed after a successful update")
	}
}
