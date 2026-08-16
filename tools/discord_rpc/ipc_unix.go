//go:build !windows

package main

import (
	"fmt"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"time"
)

// ipcPaths returns the candidate Discord IPC sockets for this system.
func ipcPaths() []string {
	var base string
	if runtime.GOOS == "darwin" {
		home, _ := os.UserHomeDir()
		base = filepath.Join(home, "Library", "Application Support", "discord")
		prefix := "pipe"
		paths := make([]string, 0, 10)
		for i := 0; i < 10; i++ {
			paths = append(paths, filepath.Join(base, fmt.Sprintf("%s-%d", prefix, i)))
		}
		return paths
	}
	base = os.Getenv("XDG_RUNTIME_DIR")
	if base == "" {
		base = "/tmp"
	}
	paths := make([]string, 0, 10)
	for i := 0; i < 10; i++ {
		paths = append(paths, filepath.Join(base, fmt.Sprintf("discord-ipc-%d", i)))
	}
	// Flatpak clients (e.g. Vesktop) run sandboxed and expose their IPC socket
	// to the host at $XDG_RUNTIME_DIR/.flatpak/<app-id>/xdg-run/discord-ipc-N.
	if entries, err := os.ReadDir(filepath.Join(base, ".flatpak")); err == nil {
		for _, entry := range entries {
			if !entry.IsDir() {
				continue
			}
			for i := 0; i < 10; i++ {
				paths = append(paths, filepath.Join(base, ".flatpak", entry.Name(),
					"xdg-run", fmt.Sprintf("discord-ipc-%d", i)))
			}
		}
	}
	return paths
}

// dialIPC opens the given Discord IPC socket.
func dialIPC(path string) (net.Conn, error) {
	return net.DialTimeout("unix", path, 2*time.Second)
}

// dial tries each candidate socket and returns the first working connection
// together with the path that succeeded.
func dial() (net.Conn, string, error) {
	var lastErr error
	for _, path := range ipcPaths() {
		conn, err := dialIPC(path)
		if err == nil {
			return conn, path, nil
		}
		lastErr = err
	}
	return nil, "", fmt.Errorf("could not connect to Discord IPC (is Discord running?): %w", lastErr)
}