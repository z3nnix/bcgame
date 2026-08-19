package main

import (
	"os"
	"os/user"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

// Config holds the player profile, persisted next to the launcher as config.toml.
type Config struct {
	Nick string `toml:"nick"`
}

var configPath string

func loadConfig() *Config {
	dir := gameRoot()
	configPath = filepath.Join(dir, "config.toml")

	cfg := &Config{}
	if data, err := os.ReadFile(configPath); err == nil {
		// A corrupt or partial file must not crash the launcher.
		_, _ = toml.Decode(string(data), cfg)
	}
	return cfg
}

func (c *Config) save() error {
	data, err := toml.Marshal(c)
	if err != nil {
		return err
	}
	return os.WriteFile(configPath, data, 0o644)
}

// defaultNick returns the OS user name, like the old Minecraft "Player" default.
func defaultNick() string {
	if u, err := user.Current(); err == nil && u.Username != "" {
		return u.Username
	}
	if u := os.Getenv("USER"); u != "" {
		return u
	}
	return "Player"
}
