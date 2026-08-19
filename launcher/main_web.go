//go:build !wails

package main

// main is the browser fallback build (no webkit2gtk needed). It serves the
// same frontend and backend over a local HTTP server and opens the browser.
func main() {
	runWebServer()
}
