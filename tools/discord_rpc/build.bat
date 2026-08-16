@echo off
REM Build the Discord Rich Presence companion for Betacraft (Windows only).
REM Produces mods\CORE\mcl_discord_rpc\bin\discord_rpc.exe where the
REM mcl_discord_rpc mod picks it up. Requires Go 1.21+.
cd /d "%~dp0"

if not exist ..\..\mods\CORE\mcl_discord_rpc\bin mkdir ..\..\mods\CORE\mcl_discord_rpc\bin

echo Building for windows (amd64)...
set GOOS=windows
set GOARCH=amd64
set CGO_ENABLED=0
go build -trimpath -ldflags="-s -w" -o ..\..\mods\CORE\mcl_discord_rpc\bin\discord_rpc.exe .
if errorlevel 1 exit /b 1

echo Done. Binary in ..\..\mods\CORE\mcl_discord_rpc\bin\discord_rpc.exe