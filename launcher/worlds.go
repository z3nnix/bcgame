package main

import (
	"crypto/rand"
	"embed"
	"fmt"
	"io/fs"
	"math/big"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

//go:embed template/*
var templateFS embed.FS

const templateDir = "template/New World"

// World is a single save game inside the game's worlds/ folder.
type World struct {
	Name       string
	Path       string
	LastPlayed int64
}

var (
	reKeyValue = regexp.MustCompile(`(?m)^(\w+)\s*=\s*.*$`)
	reBadName  = regexp.MustCompile(`[/\\:*?"<>|#=\r\n\t]`)
	reSeed     = regexp.MustCompile(`^-?\d+$`)
)

// scanWorlds lists every subdirectory of worlds/ that contains a world.mt.
func scanWorlds() []World {
	root := filepath.Join(gameRoot(), "worlds")
	entries, err := os.ReadDir(root)
	if err != nil {
		return nil
	}
	var worlds []World
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		dir := filepath.Join(root, e.Name())
		if _, err := os.Stat(filepath.Join(dir, "world.mt")); err == nil {
			worlds = append(worlds, World{Name: e.Name(), Path: dir, LastPlayed: lastPlayed(dir)})
		}
	}
	// Most recently played first; stable alphabetical order as a tie-break.
	sort.Slice(worlds, func(i, j int) bool {
		if worlds[i].LastPlayed != worlds[j].LastPlayed {
			return worlds[i].LastPlayed > worlds[j].LastPlayed
		}
		return strings.ToLower(worlds[i].Name) < strings.ToLower(worlds[j].Name)
	})
	return worlds
}

// lastPlayed returns the most recent modification time (unix seconds) of the
// files the engine writes while playing, so recently played worlds sort to
// the top of the list.
func lastPlayed(dir string) int64 {
	var latest int64
	for _, f := range []string{"world.mt", "map_meta.txt", "env_meta.txt", "map.sqlite"} {
		if fi, err := os.Stat(filepath.Join(dir, f)); err == nil {
			if t := fi.ModTime().Unix(); t > latest {
				latest = t
			}
		}
	}
	if latest == 0 {
		if fi, err := os.Stat(dir); err == nil {
			latest = fi.ModTime().Unix()
		}
	}
	return latest
}

// uniqueWorldName returns name, or "name (N)" if name is already taken.
func uniqueWorldName(name string) string {
	if _, err := os.Stat(worldDir(name)); os.IsNotExist(err) {
		return name
	}
	for n := 1; ; n++ {
		candidate := fmt.Sprintf("%s (%d)", name, n)
		if _, err := os.Stat(worldDir(candidate)); os.IsNotExist(err) {
			return candidate
		}
	}
}

func worldDir(name string) string {
	return filepath.Join(gameRoot(), "worlds", name)
}

// sanitizeName cleans a world name for use as a folder and as a world.mt value.
func sanitizeName(name string) string {
	name = strings.TrimSpace(name)
	name = reBadName.ReplaceAllString(name, "")
	name = strings.TrimSpace(name)
	name = strings.Trim(name, ".")
	if name == "" {
		name = "New World"
	}
	return name
}

// createWorld makes a new world from the embedded template and returns its
// final (deduplicated) name. An empty seed produces a random one.
func createWorld(name, seed string) (string, error) {
	name = sanitizeName(name)
	name = uniqueWorldName(name)
	dir := worldDir(name)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}

	// Copy template files into the new world.
	err := fs.WalkDir(templateFS, templateDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}
		rel, err := filepath.Rel(templateDir, path)
		if err != nil {
			return err
		}
		data, err := fs.ReadFile(templateFS, path)
		if err != nil {
			return err
		}
		return os.WriteFile(filepath.Join(dir, rel), data, 0o644)
	})
	if err != nil {
		os.RemoveAll(dir)
		return "", err
	}

	// world.mt: keep gameid and world_name in sync.
	worldMt := filepath.Join(dir, "world.mt")
	if err := setKey(worldMt, "gameid", gameID()); err != nil {
		os.RemoveAll(dir)
		return "", err
	}
	if err := setKey(worldMt, "world_name", name); err != nil {
		os.RemoveAll(dir)
		return "", err
	}

	// map_meta.txt: set the seed (random by default).
	seedValue, err := seedString(seed)
	if err != nil {
		os.RemoveAll(dir)
		return "", err
	}
	if err := setKey(filepath.Join(dir, "map_meta.txt"), "seed", seedValue); err != nil {
		os.RemoveAll(dir)
		return "", err
	}
	return name, nil
}

// seedString validates the user seed, or produces a random one.
func seedString(seed string) (string, error) {
	seed = strings.TrimSpace(seed)
	if seed == "" {
		// Similar magnitude to the template seed (a big unsigned decimal).
		max := new(big.Int).Lsh(big.NewInt(1), 64)
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", err
		}
		return n.String(), nil
	}
	if !reSeed.MatchString(seed) {
		return "", fmt.Errorf("bad seed %q", seed)
	}
	return seed, nil
}

// setKey replaces "key = <value>" lines in an engine settings file.
func setKey(path, key, value string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	out := reKeyValue.ReplaceAllStringFunc(string(data), func(line string) string {
		if strings.HasPrefix(line, key+"=") || strings.HasPrefix(line, key+" =") {
			return key + " = " + value
		}
		return line
	})
	return os.WriteFile(path, []byte(out), 0o644)
}

// deleteWorld removes a world directory entirely.
func deleteWorld(name string) error {
	return os.RemoveAll(worldDir(name))
}
