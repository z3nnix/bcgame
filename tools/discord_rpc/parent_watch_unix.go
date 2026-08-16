//go:build !windows

package main

import (
	"os"
	"syscall"
	"time"
)

// processAlive reports whether a process with the given PID is still running.
// A zero PID is never watched (returns true so the watchdog stays idle).
func processAlive(pid int) bool {
	if pid <= 0 {
		return true
	}
	err := syscall.Kill(pid, 0)
	return err == nil
}

// watchParent polls the game process until it is gone, then exits the
// companion so it never outlives the game.
func watchParent(cfg config) {
	for {
		if !processAlive(cfg.parentPID) {
			logf(cfg, "parent process %d is gone, exiting", cfg.parentPID)
			if cfg.pidfile != "" {
				_ = os.Remove(cfg.pidfile)
			}
			os.Exit(0)
		}
		time.Sleep(time.Second)
	}
}