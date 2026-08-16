//go:build windows

package main

import (
	"context"
	"fmt"
	"net"
	"time"

	"github.com/Microsoft/go-winio"
)

// ipcPaths returns the candidate Discord IPC named pipes for this system.
func ipcPaths() []string {
	paths := make([]string, 0, 10)
	for i := 0; i < 10; i++ {
		paths = append(paths, fmt.Sprintf(`\\.\pipe\discord-ipc-%d`, i))
	}
	return paths
}

// dialIPC opens the given Discord IPC named pipe.
func dialIPC(path string) (net.Conn, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	return winio.DialPipeContext(ctx, path)
}

// dial tries each candidate pipe and returns the first working connection
// together with the pipe path that succeeded.
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