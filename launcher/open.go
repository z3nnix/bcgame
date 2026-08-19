package main

import (
	"os/exec"
	"runtime"
)

// openFolder opens the given directory in the system file manager.
func openFolder(path string) error {
	if runtime.GOOS == "windows" {
		return exec.Command("explorer", path).Start()
	}
	return exec.Command("xdg-open", path).Start()
}
