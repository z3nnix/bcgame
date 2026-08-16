// Betacraft Discord Rich Presence companion.
//
// Connects to the locally running Discord client over its IPC interface and
// keeps a static Rich Presence activity ("Playing Betacraft") alive while the
// game is running. It is started and stopped by the mcl_discord_rpc mod.
//
// Discord IPC is a JSON protocol on top of a local socket:
//   - Linux: unix socket $XDG_RUNTIME_DIR/discord-ipc-N
//   - Linux (flatpak clients like Vesktop): unix socket
//     $XDG_RUNTIME_DIR/.flatpak/<app-id>/xdg-run/discord-ipc-N
//   - macOS: unix socket $HOME/Library/Application Support/discord/pipe-N
//   - Windows: named pipe \\.\pipe\discord-ipc-N
//
// Each frame is: 4-byte little-endian opcode, 4-byte little-endian payload
// length, then the JSON payload.
package main

import (
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"
)

const (
	opHandshake = 0 // Send a handshake request
	opFrame     = 1 // Any non-handshake frame
	opClose     = 2 // Close the connection
	opPing      = 3 // Ping (must be answered with opPong and the same payload)
	opPong      = 4 // Response to a ping
)

type config struct {
	clientID   string
	details    string
	state      string
	largeImage string
	largeText  string
	smallImage string
	smallText  string
	pidfile    string
	logFile    string
	verbose    bool
	parentPID  int
}

func parseConfig() config {
	var cfg config
	flag.StringVar(&cfg.clientID, "client-id", "1538625871005491342",
		"Discord application client ID")
	flag.StringVar(&cfg.details, "details", "Playing Betacraft",
		"First line of the presence")
	flag.StringVar(&cfg.state, "state", "",
		"Second line of the presence")
	flag.StringVar(&cfg.largeImage, "large-image", "betacraft-logo",
		"Large asset key as configured on the Discord application")
	flag.StringVar(&cfg.largeText, "large-text", "Betacraft",
		"Tooltip of the large asset")
	flag.StringVar(&cfg.smallImage, "small-image", "",
		"Small asset key as configured on the Discord application")
	flag.StringVar(&cfg.smallText, "small-text", "",
		"Tooltip of the small asset")
	flag.StringVar(&cfg.pidfile, "pidfile", "",
		"Write the process PID to this file (used to stop the companion)")
	flag.StringVar(&cfg.logFile, "log", "",
		"Append diagnostic output to this file")
	flag.BoolVar(&cfg.verbose, "verbose", false,
		"Print diagnostic output to stdout too")
	flag.IntVar(&cfg.parentPID, "parent-pid", 0,
		"Exit when this process is no longer running (the game's PID)")
	flag.Parse()
	return cfg
}

var logMu sync.Mutex

// logf writes a diagnostic line to the configured log file and, when verbose
// is enabled, to stdout as well.
func logf(cfg config, format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	ts := time.Now().Format("2006-01-02 15:04:05")
	line := ts + " " + msg + "\n"
	if cfg.logFile != "" {
		logMu.Lock()
		f, err := os.OpenFile(cfg.logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
		if err == nil {
			_, _ = f.WriteString(line)
			_ = f.Close()
		}
		logMu.Unlock()
	}
	if cfg.verbose || cfg.logFile == "" {
		fmt.Print(line)
	}
}

func writeFrame(conn net.Conn, op uint32, payload interface{}) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	return writeRawFrame(conn, op, data)
}

// writeRawFrame writes a frame with an already-encoded JSON payload.
func writeRawFrame(conn net.Conn, op uint32, data []byte) error {
	var header [8]byte
	binary.LittleEndian.PutUint32(header[0:4], op)
	binary.LittleEndian.PutUint32(header[4:8], uint32(len(data)))
	if _, err := conn.Write(header[:]); err != nil {
		return err
	}
	if _, err := conn.Write(data); err != nil {
		return err
	}
	return nil
}

func readFrame(conn net.Conn) (uint32, []byte, error) {
	var header [8]byte
	if _, err := io.ReadFull(conn, header[:]); err != nil {
		return 0, nil, err
	}
	op := binary.LittleEndian.Uint32(header[0:4])
	length := binary.LittleEndian.Uint32(header[4:8])
	if length > 1<<20 {
		return 0, nil, fmt.Errorf("frame too large: %d bytes", length)
	}
	payload := make([]byte, length)
	if _, err := io.ReadFull(conn, payload); err != nil {
		return 0, nil, err
	}
	return op, payload, nil
}

func sendActivity(conn net.Conn, cfg config, startTime int64) error {
	activity := map[string]interface{}{
		"details": cfg.details,
	}
	if cfg.state != "" {
		activity["state"] = cfg.state
	}
	activity["timestamps"] = map[string]interface{}{"start": startTime}
	assets := map[string]interface{}{}
	if cfg.largeImage != "" {
		assets["large_image"] = cfg.largeImage
	}
	if cfg.largeText != "" {
		assets["large_text"] = cfg.largeText
	}
	if cfg.smallImage != "" {
		assets["small_image"] = cfg.smallImage
	}
	if cfg.smallText != "" {
		assets["small_text"] = cfg.smallText
	}
	if len(assets) > 0 {
		activity["assets"] = assets
	}

	payload := map[string]interface{}{
		"cmd": "SET_ACTIVITY",
		"args": map[string]interface{}{
			"pid":      os.Getpid(),
			"activity": activity,
		},
		"nonce": fmt.Sprintf("activity-%d-%d", os.Getpid(), time.Now().UnixNano()),
	}
	return writeFrame(conn, opFrame, payload)
}

// run performs a single Discord IPC session. It returns an error when the
// session ends, so the caller can retry.
func run(cfg config) error {
	conn, path, err := dial()
	if err != nil {
		return err
	}
	defer conn.Close()
	logf(cfg, "connected to %s", path)

	startTime := time.Now().Unix()

	// Handshake
	if err := writeFrame(conn, opHandshake, map[string]interface{}{
		"v":         1,
		"client_id": cfg.clientID,
	}); err != nil {
		return err
	}
	logf(cfg, "sent handshake (client_id=%s, v=1)", cfg.clientID)

	ready := make(chan struct{}, 1)
	readErr := make(chan error, 1)
	go func() {
		for {
			op, payload, err := readFrame(conn)
			if err != nil {
				readErr <- err
				return
			}
			switch op {
			case opPing:
				// Discord expects the same raw payload back with opPong
				_ = writeRawFrame(conn, opPong, payload)
			case opFrame:
				var msg struct {
					Cmd string `json:"cmd"`
					Evt string `json:"evt"`
				}
				if err := json.Unmarshal(payload, &msg); err != nil {
					continue
				}
				if msg.Cmd == "DISPATCH" && msg.Evt == "READY" {
					select {
					case ready <- struct{}{}:
					default:
					}
				}
			}
		}
	}()

	select {
	case err := <-readErr:
		return err
	case <-ready:
		logf(cfg, "received READY")
	case <-time.After(10 * time.Second):
		return fmt.Errorf("timeout waiting for Discord READY")
	}

	if err := sendActivity(conn, cfg, startTime); err != nil {
		return err
	}
	logf(cfg, "sent SET_ACTIVITY")

	// Re-send periodically so Discord keeps showing the activity.
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case err := <-readErr:
			return err
		case <-ticker.C:
			if err := sendActivity(conn, cfg, startTime); err != nil {
				return err
			}
		}
	}
}

func main() {
	cfg := parseConfig()

	if cfg.pidfile != "" {
		if err := os.WriteFile(cfg.pidfile, []byte(strconv.Itoa(os.Getpid())), 0o644); err != nil {
			logf(cfg, "warning: could not write pidfile %s: %v", cfg.pidfile, err)
		}
		defer os.Remove(cfg.pidfile)
	}

	// Watch the game process: if it dies (crash, quit, kill), this companion
	// should stop too instead of lingering in the background.
	if cfg.parentPID > 0 {
		go watchParent(cfg)
		logf(cfg, "watching parent pid %d", cfg.parentPID)
	}

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

	for {
		if err := run(cfg); err != nil {
			logf(cfg, "session ended: %v", err)
		}
		select {
		case <-sig:
			logf(cfg, "shutting down")
			return
		case <-time.After(5 * time.Second):
			// Discord not running yet or connection dropped; retry.
		}
	}
}