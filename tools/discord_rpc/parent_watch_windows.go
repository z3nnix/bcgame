//go:build windows

package main

import (
	"os"
	"syscall"
	"time"
)

// PROCESS_QUERY_LIMITED_INFORMATION lets us check whether a process is alive.
const processQueryLimitedInformation = 0x1000

// processAlive reports whether a process with the given PID is still running.
// A zero PID is never watched (returns true so the watchdog stays idle).
func processAlive(pid int) bool {
	if pid <= 0 {
		return true
	}
	handle, err := syscall.OpenProcess(processQueryLimitedInformation, false, uint32(pid))
	if err != nil {
		return false
	}
	_ = syscall.CloseHandle(handle)
	return true
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