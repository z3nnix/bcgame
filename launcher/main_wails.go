//go:build wails

package main

import (
	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

// main is the native Wails build (requires webkit2gtk on Linux, WebView2 on
// Windows). Pass --web or set BETACRAFT_WEB=1 for the browser fallback mode.
func main() {
	if webMode() {
		runWebServer()
		return
	}

	app := NewApp()
	err := wails.Run(&options.App{
		Title:     "Betacraft",
		Width:     680,
		Height:    560,
		MinWidth:  560,
		MinHeight: 460,
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		Bind: []interface{}{
			app,
		},
	})
	if err != nil {
		println("Error:", err.Error())
	}
}
