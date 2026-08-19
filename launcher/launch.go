package main

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
)

var (
	gameMu      sync.Mutex
	gameRunning bool
)

// startGame launches the bundled engine directly into the given world without
// blocking. The process keeps running in the background until the player quits.
func startGame(w World, nick string) error {
	gameMu.Lock()
	if gameRunning {
		gameMu.Unlock()
		return errors.New("game is already running")
	}
	gameMu.Unlock()

	args := []string{"--go", "--world", w.Path}
	if nick != "" {
		args = append(args, "--name", nick)
	}

	cmd := exec.Command(engineBinary(), args...)
	cmd.Dir = gameRoot()
	cmd.Env = append(os.Environ(), "LUANTI_GAME_PATH="+filepath.Dir(gameRoot()))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		return err
	}

	gameMu.Lock()
	gameRunning = true
	gameMu.Unlock()

	go func() {
		cmd.Wait()
		gameMu.Lock()
		gameRunning = false
		gameMu.Unlock()
	}()

	return nil
}

// gameStatus reports whether the engine is currently running.
func gameStatus() bool {
	gameMu.Lock()
	defer gameMu.Unlock()
	return gameRunning
}
