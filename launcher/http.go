package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"reflect"
	"runtime"
	"strconv"
	"strings"
)

// Web-mode address. The launcher is both the server and the "browser"
// opener: it binds here and opens the URL in the default browser. If the
// port is already taken (previous instance), it just opens the browser.
const (
	defaultAddr = "127.0.0.1"
	defaultPort = 39841
)

// runWebServer serves the frontend plus an /api/* bridge that calls the same
// App methods as the Wails bindings. Used by --web / BETACRAFT_WEB=1.
func runWebServer() {
	app := NewApp()

	mux := http.NewServeMux()
	mux.Handle("/frontend/", http.FileServer(http.FS(assets)))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			http.Redirect(w, r, "/frontend/", http.StatusFound)
			return
		}
		http.NotFound(w, r)
	})
	mux.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "POST only", http.StatusMethodNotAllowed)
			return
		}
		method := strings.TrimPrefix(r.URL.Path, "/api/")
		if method == "" {
			http.Error(w, "no method", http.StatusBadRequest)
			return
		}
		body, _ := io.ReadAll(r.Body)
		result, err := app.invoke(method, body)
		if err != nil {
			writeJSON(w, map[string]interface{}{"error": err.Error()})
			return
		}
		writeJSON(w, map[string]interface{}{"result": result})
	})

	addr := net.JoinHostPort(defaultAddr, strconv.Itoa(port()))
	url := fmt.Sprintf("http://%s/frontend/", addr)

	ln, err := net.Listen("tcp", addr)
	if err != nil {
		log.Printf("%s already in use, opening browser instead", addr)
		if err := openURL(url); err != nil {
			log.Printf("open browser: %v", err)
		}
		select {}
	}

	go func() { log.Fatal(http.Serve(ln, mux)) }()

	log.Printf("Betacraft launcher (web mode) at %s — Ctrl+C to quit", url)
	if err := openURL(url); err != nil {
		log.Printf("open browser: %v", err)
	}
	select {}
}

// port returns the listening port: BETACRAFT_PORT env override or the default.
func port() int {
	if v := os.Getenv("BETACRAFT_PORT"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 && n < 65536 {
			return n
		}
	}
	return defaultPort
}

// webMode reports whether to run in browser fallback mode instead of the
// native Wails window.
func webMode() bool {
	for _, a := range os.Args[1:] {
		if a == "--web" {
			return true
		}
	}
	return os.Getenv("BETACRAFT_WEB") == "1"
}

// invoke calls an App method by name with JSON-encoded arguments.
func (a *App) invoke(method string, rawArgs []byte) (interface{}, error) {
	m := reflect.ValueOf(a).MethodByName(method)
	if !m.IsValid() {
		return nil, fmt.Errorf("unknown method %q", method)
	}
	mt := m.Type()

	var args []interface{}
	if len(rawArgs) > 0 {
		if err := json.Unmarshal(rawArgs, &args); err != nil {
			return nil, fmt.Errorf("bad arguments: %w", err)
		}
	}
	if len(args) != mt.NumIn() {
		return nil, fmt.Errorf("method %q expects %d args, got %d", method, mt.NumIn(), len(args))
	}

	in := make([]reflect.Value, mt.NumIn())
	for i, arg := range args {
		data, err := json.Marshal(arg)
		if err != nil {
			return nil, err
		}
		pv := reflect.New(mt.In(i))
		if err := json.Unmarshal(data, pv.Interface()); err != nil {
			return nil, fmt.Errorf("argument %d: %w", i, err)
		}
		in[i] = pv.Elem()
	}

	out := m.Call(in)
	if len(out) == 0 {
		return nil, nil
	}
	if err, ok := out[len(out)-1].Interface().(error); ok && err != nil {
		return nil, err
	}
	return out[0].Interface(), nil
}

func writeJSON(w http.ResponseWriter, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

// openURL opens a URL in the default browser.
func openURL(url string) error {
	if runtime.GOOS == "windows" {
		return exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
	}
	return exec.Command("xdg-open", url).Start()
}
