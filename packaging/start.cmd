@echo off
REM Betacraft launcher (Windows)
REM Runs the bundled Luanti engine with the starter world.
REM The game folder must stay a direct child of its parent directory so that
REM LUANTI_GAME_PATH (the parent) can find this game.
cd /d "%~dp0"

REM Keep world.mt's gameid in sync with the folder name, so renaming the
REM folder does not break game discovery.
for %%I in ("%CD%") do set "GAMEID=%%~nxI"
powershell -NoProfile -Command "$p='worlds\default\world.mt'; (Get-Content $p) -replace '^gameid = .*','gameid = %GAMEID%' | Set-Content $p"

set "LUANTI_GAME_PATH=%CD%\.."
start "" "bin\luanti.exe" --go --world "%CD%\worlds\default"