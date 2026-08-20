package main

import (
	"archive/zip"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	updateRepo       = "z3nnix/bcgame"
	latestReleaseURL = "https://api.github.com/repos/" + updateRepo + "/releases/latest"
)

// UpdateInfo describes the newest release on GitHub compared to the installed
// copy. Current is empty when the launcher does not know what is installed.
type UpdateInfo struct {
	Available bool
	Current   string
	Latest    string
	Size      int64
	URL       string
	SHA256    string
}

// UpdateState is the progress snapshot the frontend polls while an update runs.
type UpdateState struct {
	Running  bool
	Phase    string
	Done     int64
	Total    int64
	Finished bool
	Err      string
}

var (
	updateMu    sync.Mutex
	updateState UpdateState
)

type ghRelease struct {
	TagName string `json:"tag_name"`
	Assets  []struct {
		Name               string `json:"name"`
		Size               int64  `json:"size"`
		BrowserDownloadURL string `json:"browser_download_url"`
		Digest             string `json:"digest"`
	} `json:"assets"`
}

// compareTags compares release tags such as "v2026.08.19" or "v0.1.0".
// The CI tags use the zero-padded %Y.%m.%d format, so plain lexicographic
// comparison of the part after "v" is correct for them.
func compareTags(a, b string) int {
	return strings.Compare(strings.TrimPrefix(a, "v"), strings.TrimPrefix(b, "v"))
}

func platformAssetName() string {
	if runtime.GOOS == "windows" {
		return "betacraft-windows-x86_64.zip"
	}
	return "betacraft-linux-x86_64.zip"
}

func fetchLatestRelease() (ghRelease, error) {
	req, err := http.NewRequest(http.MethodGet, latestReleaseURL, nil)
	if err != nil {
		return ghRelease{}, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("User-Agent", "betacraft-launcher")
	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return ghRelease{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return ghRelease{}, fmt.Errorf("GitHub API returned %s", resp.Status)
	}
	var rel ghRelease
	if err := json.NewDecoder(resp.Body).Decode(&rel); err != nil {
		return ghRelease{}, err
	}
	if rel.TagName == "" {
		return ghRelease{}, errors.New("release has no tag")
	}
	return rel, nil
}

// checkForUpdate queries GitHub and reports whether current is older than the
// latest release. An empty current means "unknown" and never counts as stale.
func checkForUpdate(current string) (UpdateInfo, error) {
	rel, err := fetchLatestRelease()
	if err != nil {
		return UpdateInfo{}, err
	}
	name := platformAssetName()
	info := UpdateInfo{Current: current, Latest: rel.TagName}
	for _, a := range rel.Assets {
		if a.Name != name {
			continue
		}
		info.Size = a.Size
		info.URL = a.BrowserDownloadURL
		info.SHA256 = strings.TrimPrefix(a.Digest, "sha256:")
		break
	}
	if info.URL == "" {
		return info, fmt.Errorf("no %s asset in release %s", name, rel.TagName)
	}
	if current != "" && compareTags(current, rel.TagName) < 0 {
		info.Available = true
	}
	return info, nil
}

// managedPaths are the game-content paths owned by a release archive. Everything
// else in the game root (worlds/, config.toml, mod_data/, cache/, debug.txt) is
// left untouched by updates.
var managedPaths = []string{
	"mods", "textures", "menu", "bin", "builtin", "fonts", "client",
	"game.conf", "settingtypes.txt", "LICENSE", "CREDITS.md", "LEGAL.md",
}

// runUpdate downloads and installs the latest release, updating updateState.
func runUpdate() error {
	info, err := checkForUpdate("")
	if err != nil {
		return err
	}
	setPhase("Downloading", 0, info.Size)
	return downloadAndInstall(info)
}

func downloadAndInstall(info UpdateInfo) (err error) {
	tmpZip, err := downloadToTemp(info)
	if err != nil {
		return err
	}
	defer os.Remove(tmpZip)

	if info.SHA256 != "" {
		sum, err := sha256File(tmpZip)
		if err != nil {
			return err
		}
		if !strings.EqualFold(sum, info.SHA256) {
			return fmt.Errorf("checksum mismatch (got %s)", sum)
		}
	}

	root := gameRoot()
	ts := time.Now().UnixNano()
	staging := filepath.Join(root, fmt.Sprintf(".update-staging-%d", ts))
	backup := filepath.Join(root, fmt.Sprintf(".update-backup-%d", ts))
	defer func() {
		os.RemoveAll(staging)
		if err != nil {
			restoreBackup(root, backup)
		} else {
			os.RemoveAll(backup)
		}
	}()

	setPhase("Extracting", 0, 0)
	if err = extractArchive(tmpZip, staging); err != nil {
		return err
	}
	if err = validateStaging(staging); err != nil {
		return err
	}

	setPhase("Installing", 0, 0)
	return installStaged(root, staging, backup)
}

func downloadToTemp(info UpdateInfo) (tmpPath string, err error) {
	tmp, err := os.CreateTemp("", "betacraft-update-*.zip")
	if err != nil {
		return "", err
	}
	defer func() {
		if err != nil {
			tmp.Close()
			os.Remove(tmp.Name())
		}
	}()

	req, err := http.NewRequest(http.MethodGet, info.URL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "betacraft-launcher")
	client := &http.Client{Timeout: 10 * time.Minute}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("download failed: %s", resp.Status)
	}

	pr := &progressReader{r: resp.Body}
	if _, err := io.Copy(tmp, pr); err != nil {
		return "", err
	}
	if err := tmp.Close(); err != nil {
		return "", err
	}
	return tmp.Name(), nil
}

type progressReader struct {
	r io.Reader
	n int64
}

func (p *progressReader) Read(b []byte) (int, error) {
	n, err := p.r.Read(b)
	p.n += int64(n)
	setProgress(p.n)
	return n, err
}

func extractArchive(zipPath, dest string) error {
	zr, err := zip.OpenReader(zipPath)
	if err != nil {
		return err
	}
	defer zr.Close()

	for _, f := range zr.File {
		rel, ok := archiveRelPath(f.Name)
		if !ok {
			continue
		}
		target := filepath.Join(dest, filepath.FromSlash(rel))
		mode := f.Mode().Perm()
		if mode == 0 {
			mode = 0o644
		}
		if f.FileInfo().IsDir() {
			if err := os.MkdirAll(target, 0o755); err != nil {
				return err
			}
			continue
		}
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return err
		}
		rc, err := f.Open()
		if err != nil {
			return err
		}
		out, err := os.OpenFile(target, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, mode)
		if err != nil {
			rc.Close()
			return err
		}
		if _, err := io.Copy(out, rc); err != nil {
			out.Close()
			rc.Close()
			return err
		}
		out.Close()
		rc.Close()
	}
	return nil
}

// archiveRelPath maps an archive entry to a path relative to the game root. It
// strips the leading "betacraft/" folder, rejects traversal, and skips anything
// that must never be overwritten (worlds/, config.toml). ok=false means skip.
func archiveRelPath(name string) (string, bool) {
	name = strings.TrimPrefix(name, "./")
	parts := strings.Split(filepath.ToSlash(name), "/")
	if len(parts) > 0 && parts[0] == "betacraft" {
		parts = parts[1:]
	}
	if len(parts) == 0 {
		return "", false
	}
	for _, p := range parts {
		if p == "" || p == ".." {
			return "", false
		}
	}
	if parts[0] == "worlds" {
		return "", false
	}
	if len(parts) == 1 && parts[0] == "config.toml" {
		return "", false
	}
	return strings.Join(parts, "/"), true
}

func validateStaging(staging string) error {
	engine := "luanti"
	if runtime.GOOS == "windows" {
		engine = "luanti.exe"
	}
	for _, p := range []string{filepath.Join("bin", engine), "mods", "game.conf"} {
		if _, err := os.Stat(filepath.Join(staging, p)); err != nil {
			return fmt.Errorf("archive is missing %s", p)
		}
	}
	return nil
}

// installStaged swaps the release content into root: existing managed paths are
// moved to backup first (so a failure can be rolled back), the staged content
// is copied in, and then the launcher binary itself is replaced.
func installStaged(root, staging, backup string) error {
	if _, err := os.Lstat(filepath.Join(staging, "minetest.conf")); err == nil {
		if err := mergeMinetestConf(filepath.Join(staging, "minetest.conf"),
			filepath.Join(root, "minetest.conf")); err != nil {
			return err
		}
	}

	for _, p := range managedPaths {
		src := filepath.Join(root, p)
		if _, err := os.Lstat(src); os.IsNotExist(err) {
			continue
		}
		dst := filepath.Join(backup, p)
		if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
			return err
		}
		if err := os.Rename(src, dst); err != nil {
			return err
		}
	}

	for _, p := range managedPaths {
		src := filepath.Join(staging, p)
		if _, err := os.Lstat(src); os.IsNotExist(err) {
			continue
		}
		if err := copyTree(src, filepath.Join(root, p)); err != nil {
			return err
		}
	}

	stagedLauncher := filepath.Join(staging, launcherBinary())
	if _, err := os.Lstat(stagedLauncher); err == nil {
		return replaceLauncher(root, stagedLauncher)
	}
	return nil
}

// restoreBackup puts the pre-update content back, discarding any partially
// applied staged files.
func restoreBackup(root, backup string) {
	for _, p := range managedPaths {
		src := filepath.Join(backup, p)
		if _, err := os.Lstat(src); os.IsNotExist(err) {
			continue
		}
		_ = os.RemoveAll(filepath.Join(root, p))
		_ = os.Rename(src, filepath.Join(root, p))
	}
	_ = os.RemoveAll(backup)
}

// replaceLauncher swaps in the new launcher binary. On Linux the running
// process keeps its old inode, so the file can be replaced in place. On
// Windows a running executable cannot be overwritten, so the new one is staged
// and a detached helper swaps it in after this process exits.
func replaceLauncher(root, staged string) error {
	dest := filepath.Join(root, launcherBinary())
	if runtime.GOOS == "windows" {
		newPath := filepath.Join(root, "launcher.exe.new")
		if err := copyFile(staged, newPath, 0o755); err != nil {
			return err
		}
		script := "@echo off\r\n:wait\r\ntasklist /fi \"imagename eq launcher.exe\" | find \"launcher.exe\" >nul\r\nif %errorlevel%==0 (\r\n  timeout /t 2 /nobreak >nul\r\n  goto wait\r\n)\r\nmove /y \"%CD%\\launcher.exe.new\" \"%CD%\\launcher.exe\"\r\ndel \"%~f0\"\r\n"
		cmd := filepath.Join(root, "update.cmd")
		if err := os.WriteFile(cmd, []byte(script), 0o644); err != nil {
			return err
		}
		c := exec.Command("cmd", "/c", "start", "", "/b", filepath.Base(cmd))
		c.Dir = root
		return c.Start()
	}

	backup := dest + ".old"
	_ = os.Remove(backup)
	if _, err := os.Lstat(dest); err == nil {
		if err := os.Rename(dest, backup); err != nil {
			return err
		}
	}
	if err := os.Rename(staged, dest); err != nil {
		_ = os.Rename(backup, dest)
		return err
	}
	_ = os.Remove(backup)
	return nil
}

// mergeMinetestConf adds keys present in the release config but missing in the
// local config. In run-in-place builds minetest.conf also stores the player's
// settings, so it must never be blindly overwritten.
func mergeMinetestConf(archivePath, localPath string) error {
	arch, err := os.ReadFile(archivePath)
	if err != nil {
		return err
	}
	re := regexp.MustCompile(`(?m)^\s*([\w.]+)\s*=\s*(.*?)\s*$`)
	archKeys := map[string]string{}
	for _, m := range re.FindAllStringSubmatch(string(arch), -1) {
		archKeys[m[1]] = m[2]
	}
	if len(archKeys) == 0 {
		return nil
	}

	local, err := os.ReadFile(localPath)
	if err != nil && !os.IsNotExist(err) {
		return err
	}
	localKeys := map[string]bool{}
	if len(local) > 0 {
		for _, m := range re.FindAllStringSubmatch(string(local), -1) {
			localKeys[m[1]] = true
		}
	}

	var missing []string
	for k := range archKeys {
		if !localKeys[k] {
			missing = append(missing, k)
		}
	}
	sort.Strings(missing)
	if len(missing) == 0 {
		return nil
	}

	var b strings.Builder
	b.Write(local)
	if len(local) > 0 && local[len(local)-1] != '\n' {
		b.WriteByte('\n')
	}
	for _, k := range missing {
		fmt.Fprintf(&b, "%s = %s\n", k, archKeys[k])
	}
	return os.WriteFile(localPath, []byte(b.String()), 0o644)
}

func sha256File(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func copyTree(src, dst string) error {
	return filepath.Walk(src, func(path string, fi os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		target := filepath.Join(dst, rel)
		if fi.IsDir() {
			return os.MkdirAll(target, fi.Mode().Perm())
		}
		return copyFile(path, target, fi.Mode().Perm())
	})
}

func copyFile(src, dst string, perm os.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dst, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, perm)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		return err
	}
	return out.Close()
}

func launcherBinary() string {
	if runtime.GOOS == "windows" {
		return "launcher.exe"
	}
	return "launcher"
}

func setProgress(done int64) {
	updateMu.Lock()
	updateState.Running = true
	updateState.Done = done
	updateMu.Unlock()
}

func setPhase(phase string, done, total int64) {
	updateMu.Lock()
	updateState.Phase = phase
	updateState.Done = done
	updateState.Total = total
	updateState.Running = true
	updateMu.Unlock()
}

func updateSnapshot() UpdateState {
	updateMu.Lock()
	defer updateMu.Unlock()
	return updateState
}

// startUpdate kicks off the download/install in the background and returns
// immediately; progress can be read via updateSnapshot.
func startUpdate() error {
	updateMu.Lock()
	if updateState.Running {
		updateMu.Unlock()
		return errors.New("an update is already running")
	}
	updateState = UpdateState{Running: true}
	updateMu.Unlock()

	go func() {
		err := runUpdate()
		updateMu.Lock()
		updateState.Running = false
		updateState.Finished = true
		updateState.Phase = "Done"
		if err != nil {
			updateState.Err = err.Error()
		}
		updateMu.Unlock()
	}()
	return nil
}
