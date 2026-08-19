package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// launch_test.go verifies the engine command line construction and environment
// using a fake engine binary that records what it was called with.
func TestLaunchGameArgsAndEnv(t *testing.T) {
	root := t.TempDir()
	binDir := filepath.Join(root, "bin")
	if err := os.MkdirAll(binDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, "worlds"), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("BETACRAFT_GAME_DIR", root)

	record := filepath.Join(root, "record.txt")
	t.Setenv("BETACRAFT_LAUNCH_RECORD", record)

	script := "#!/bin/sh\nprintf '%s\\n' \"$@\" \"$LUANTI_GAME_PATH\" \"$PWD\" > \"$BETACRAFT_LAUNCH_RECORD\"\nsleep 2\n"
	if err := os.WriteFile(filepath.Join(binDir, "luanti"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}

	if _, err := createWorld("My World", "99"); err != nil {
		t.Fatal(err)
	}
	w := World{Name: "My World", Path: filepath.Join(root, "worlds", "My World")}

	// The engine script exits immediately; startGame must finish fast and
	// report the process as running while it is alive.
	if err := startGame(w, "Player One"); err != nil {
		t.Fatal(err)
	}
	if !gameStatus() {
		t.Error("expected gameStatus() == true right after start")
	}

	// Wait for the script to exit and confirm the runner tracks it.
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		if !gameStatus() {
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	if gameStatus() {
		t.Error("expected gameStatus() == false after the engine exited")
	}

	data, err := os.ReadFile(record)
	if err != nil {
		t.Fatal(err)
	}
	lines := strings.Split(strings.TrimSpace(string(data)), "\n")
	if len(lines) != 7 {
		t.Fatalf("expected 7 lines (5 args + env + pwd), got %d: %q", len(lines), lines)
	}
	// args[0] is the world path flag pair: --go, --world, <path>, --name, <nick>
	want := []string{"--go", "--world", w.Path, "--name", "Player One"}
	for i := 0; i < 5; i++ {
		if lines[i] != want[i] {
			t.Errorf("arg[%d] = %q, want %q", i, lines[i], want[i])
		}
	}
	if lines[5] != filepath.Dir(root) {
		t.Errorf("LUANTI_GAME_PATH = %q, want %q", lines[5], filepath.Dir(root))
	}
	if lines[6] != root {
		t.Errorf("PWD = %q, want %q", lines[6], root)
	}
}
