package main

import (
	"errors"
	"os"
	"path/filepath"
	"runtime"
)

var errGameLayout = errors.New("invalid game layout")

// gameRoot returns the game folder root. The launcher is expected to live
// at the root of the game folder, so it treats its own directory as the
// root. BETACRAFT_GAME_DIR can override this for development/testing.
func gameRoot() string {
	if p := os.Getenv("BETACRAFT_GAME_DIR"); p != "" {
		return p
	}
	exe, err := os.Executable()
	if err != nil {
		return "."
	}
	return filepath.Dir(exe)
}

// gameID keeps world.mt's gameid in sync with the folder name so renaming the
// game folder does not break game discovery (same trick as start.sh).
func gameID() string {
	return filepath.Base(gameRoot())
}

// engineBinary returns the path to the bundled engine executable.
func engineBinary() string {
	name := "luanti"
	if runtime.GOOS == "windows" {
		name = "luanti.exe"
	}
	return filepath.Join(gameRoot(), "bin", name)
}

// gamePath is the parent of the game folder, where the engine scans for games.
func gamePath() string {
	return filepath.Dir(gameRoot())
}

// validateGame checks that the expected game layout exists next to the launcher.
func validateGame() error {
	worldsDir := filepath.Join(gameRoot(), "worlds")
	if fi, err := os.Stat(worldsDir); err != nil || !fi.IsDir() {
		return errGameLayout
	}
	if _, err := os.Stat(engineBinary()); err != nil {
		return errGameLayout
	}
	return nil
}
