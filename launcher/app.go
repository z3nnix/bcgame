package main

import (
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

type App struct {
	cfg *Config
}

func NewApp() *App {
	return &App{cfg: loadConfig()}
}

func (a *App) Config() Config {
	return *a.cfg
}

func (a *App) DefaultNick() string {
	return defaultNick()
}

func (a *App) SetNick(nick string) {
	a.cfg.Nick = nick
	_ = a.cfg.save()
}

// Worlds lists every save game in the worlds/ folder.
func (a *App) Worlds() []World {
	return scanWorlds()
}

// CreateWorld makes a new world from the embedded template and returns its
// final (deduplicated) name. An empty seed produces a random one.
func (a *App) CreateWorld(name, seed string) (string, error) {
	return createWorld(name, seed)
}

// DeleteWorld removes a world directory.
func (a *App) DeleteWorld(name string) error {
	return deleteWorld(name)
}

// LaunchGame starts the engine in the given world (non-blocking).
func (a *App) LaunchGame(worldName, nick string) error {
	for _, w := range scanWorlds() {
		if w.Name == worldName {
			if nick == "" {
				nick = defaultNick()
			}
			a.cfg.Nick = nick
			_ = a.cfg.save()
			return startGame(w, nick)
		}
	}
	return fmt.Errorf("world %q not found", worldName)
}

// GameRunning reports whether the engine is currently running.
func (a *App) GameRunning() bool {
	return gameStatus()
}

// CheckForUpdate queries GitHub for the latest release and records the version
// on first run so it does not nag fresh installs.
func (a *App) CheckForUpdate() (UpdateInfo, error) {
	info, err := checkForUpdate(a.cfg.Version)
	if err != nil {
		return UpdateInfo{}, err
	}
	if a.cfg.Version == "" {
		a.cfg.Version = info.Latest
		_ = a.cfg.save()
	}
	return info, nil
}

// UpdateProgress returns the snapshot of the running update.
func (a *App) UpdateProgress() UpdateState {
	return updateSnapshot()
}

// ApplyUpdate starts downloading and installing the latest release.
func (a *App) ApplyUpdate() error {
	if gameStatus() {
		return errors.New("quit the game before updating")
	}
	return startUpdate()
}

// OpenFolder opens the game folder in the system file manager.
func (a *App) OpenFolder() error {
	return openFolder(gameRoot())
}

// Logo returns the game logo (menu/header.png or icon.png) as a data URL.
func (a *App) Logo() string {
	for _, name := range []string{"header.png", "icon.png"} {
		path := filepath.Join(gameRoot(), "menu", name)
		data, err := os.ReadFile(path)
		if err == nil {
			return "data:image/png;base64," + base64.StdEncoding.EncodeToString(data)
		}
	}
	return ""
}
