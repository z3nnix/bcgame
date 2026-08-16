package main

import (
	"encoding/binary"
	"encoding/json"
	"io"
	"net"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// readRawFrame reads a raw frame from the server side.
func readRawFrame(t *testing.T, conn net.Conn) (uint32, []byte) {
	t.Helper()
	var header [8]byte
	if _, err := io.ReadFull(conn, header[:]); err != nil {
		t.Fatalf("read frame header: %v", err)
	}
	op := binary.LittleEndian.Uint32(header[0:4])
	length := binary.LittleEndian.Uint32(header[4:8])
	payload := make([]byte, length)
	if _, err := io.ReadFull(conn, payload); err != nil {
		t.Fatalf("read frame payload: %v", err)
	}
	return op, payload
}

func writeRawTestFrame(t *testing.T, conn net.Conn, op uint32, payload []byte) {
	t.Helper()
	var header [8]byte
	binary.LittleEndian.PutUint32(header[0:4], op)
	binary.LittleEndian.PutUint32(header[4:8], uint32(len(payload)))
	if _, err := conn.Write(header[:]); err != nil {
		t.Fatalf("write header: %v", err)
	}
	if _, err := conn.Write(payload); err != nil {
		t.Fatalf("write payload: %v", err)
	}
}

// startMockDiscord listens on $XDG_RUNTIME_DIR/discord-ipc-0 and plays the
// role of the Discord client for exactly one session.
func startMockDiscord(t *testing.T, tDir string) {
	t.Helper()
	sockPath := filepath.Join(tDir, "discord-ipc-0")
	ln, err := net.Listen("unix", sockPath)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	t.Cleanup(func() { ln.Close() })

	go func() {
		conn, err := ln.Accept()
		if err != nil {
			return
		}
		defer conn.Close()

		// 1. Expect handshake (op=0) with correct client id.
		op, payload := readRawFrame(t, conn)
		if err != nil {
			return
		}
		if op != opHandshake {
			t.Errorf("expected handshake, got op %d", op)
		}
		var hs struct {
			V        int    `json:"v"`
			ClientID string `json:"client_id"`
		}
		if err := json.Unmarshal(payload, &hs); err != nil {
			t.Errorf("handshake payload: %v", err)
			return
		}
		if hs.V != 1 || hs.ClientID != "1538625871005491342" {
			t.Errorf("unexpected handshake: %+v", hs)
		}

		// 2. Send READY.
		ready := []byte(`{"cmd":"DISPATCH","evt":"READY","data":{"user":{"id":"1","username":"test"}}}`)
		writeRawTestFrame(t, conn, opFrame, ready)

		// 3. Expect SET_ACTIVITY.
		op, payload = readRawFrame(t, conn)
		if op != opFrame {
			t.Errorf("expected frame op, got %d", op)
		}
		var act struct {
			Cmd  string `json:"cmd"`
			Args struct {
				Activity map[string]interface{} `json:"activity"`
			} `json:"args"`
		}
		if err := json.Unmarshal(payload, &act); err != nil {
			t.Errorf("activity payload: %v", err)
			return
		}
		if act.Cmd != "SET_ACTIVITY" {
			t.Errorf("expected SET_ACTIVITY, got %q", act.Cmd)
		}
		details, _ := act.Args.Activity["details"].(string)
		if details != "Playing Betacraft" {
			t.Errorf("unexpected details %q", details)
		}
		assets, ok := act.Args.Activity["assets"].(map[string]interface{})
		if !ok {
			t.Errorf("missing assets")
			return
		}
		if assets["large_image"] != "betacraft-logo" {
			t.Errorf("unexpected large_image %v", assets["large_image"])
		}

		// 4. Send a PING, expect a PONG with the same payload.
		writeRawTestFrame(t, conn, opPing, []byte(`"ping-payload"`))
		op, payload = readRawFrame(t, conn)
		if op != opPong || string(payload) != `"ping-payload"` {
			t.Errorf("expected pong, got op=%d payload=%s", op, payload)
		}
	}()
}

func TestDiscordSession(t *testing.T) {
	tDir := t.TempDir()
	t.Setenv("XDG_RUNTIME_DIR", tDir)
	startMockDiscord(t, tDir)

	cfg := config{
		clientID:   "1538625871005491342",
		details:    "Playing Betacraft",
		largeImage: "betacraft-logo",
		largeText:  "Betacraft",
	}

	done := make(chan error, 1)
	go func() { done <- run(cfg) }()

	select {
	case err := <-done:
		if err == nil {
			t.Fatal("expected run() to return an error after the mock session ended")
		}
	case <-time.After(15 * time.Second):
		t.Fatal("run() did not finish within 15s")
	}
}

func TestIPCPathsLinux(t *testing.T) {
	if os.Getenv("GOOS") == "windows" {
		t.Skip("unix-specific")
	}
	tDir := t.TempDir()
	t.Setenv("XDG_RUNTIME_DIR", tDir)
	paths := ipcPaths()
	if len(paths) != 10 {
		t.Fatalf("expected 10 candidate paths, got %d", len(paths))
	}
	if paths[0] != filepath.Join(tDir, "discord-ipc-0") {
		t.Errorf("unexpected first path %q", paths[0])
	}
}