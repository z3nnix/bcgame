<#
.SYNOPSIS
Builds the Luanti engine for Windows x64 using MSVC and vcpkg.

.DESCRIPTION
Configures and builds the vendored Luanti engine with -DRUN_IN_PLACE=1 and
installs it into a staging directory ready for packaging:

  <StageDir>/bin/luanti.exe      - engine executable
  <StageDir>/bin/*.dll           - runtime DLLs
  <StageDir>/share/luanti/...    - engine data (builtin, fonts, textures, client)

Requirements: Visual Studio (MSVC), CMake, and a vcpkg checkout.

.PARAMETER VcpkgDir
Path to the vcpkg checkout (must contain scripts/buildsystems/vcpkg.cmake).

.PARAMETER SourceDir
Luanti source directory (default: engine/luanti, which also holds the
vcpkg.json dependency manifest used by the vcpkg toolchain).

.PARAMETER BuildDir
CMake build directory (default: engine/build-windows).

.PARAMETER StageDir
Install staging directory (default: engine/stage-windows).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VcpkgDir,
    [string]$SourceDir = (Join-Path $PSScriptRoot 'luanti'),
    [string]$BuildDir = (Join-Path $PSScriptRoot 'build-windows'),
    [string]$StageDir = (Join-Path $PSScriptRoot 'stage-windows')
)

$ErrorActionPreference = 'Stop'
$env:VCPKG_DEFAULT_TRIPLET = 'x64-windows'

$toolchain = Join-Path $VcpkgDir 'scripts\buildsystems\vcpkg.cmake'
if (-not (Test-Path $toolchain)) {
    throw "vcpkg toolchain not found: $toolchain"
}

if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# The vcpkg toolchain installs the dependencies declared in
# $SourceDir/vcpkg.json during configure.
cmake -S $SourceDir -B $BuildDir `
    -A x64 `
    -DCMAKE_TOOLCHAIN_FILE="$toolchain" `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 `
    -DRUN_IN_PLACE=1 `
    -DENABLE_GETTEXT=FALSE `
    -DENABLE_POSTGRESQL=OFF `
    -DENABLE_LUAJIT=TRUE `
    -DREQUIRE_LUAJIT=TRUE
if ($LASTEXITCODE -ne 0) {
    throw 'cmake configure failed'
}

cmake --build $BuildDir --config Release -j
if ($LASTEXITCODE -ne 0) {
    throw 'cmake build failed'
}

if (Test-Path $StageDir) {
    Remove-Item -Recurse -Force $StageDir
}
cmake --install $BuildDir --config Release --prefix $StageDir
if ($LASTEXITCODE -ne 0) {
    throw 'cmake install failed'
}

# Bring runtime DLLs next to the executable for a portable package.
# The MSVC runtime is installed by cmake --install; the vcpkg dependency
# DLLs end up next to the built executable (VCPKG_APPLOCAL_DEPS) or in the
# vcpkg install root. Try all the usual locations.
$dllDst = Join-Path $StageDir 'bin'
$dllCandidates = @(
    (Join-Path $BuildDir 'bin\Release'),
    (Join-Path $BuildDir 'bin'),
    (Join-Path $BuildDir 'vcpkg_installed\x64-windows\bin'),
    (Join-Path $SourceDir 'vcpkg_installed\x64-windows\bin'),
    (Join-Path $VcpkgDir 'installed\x64-windows\bin')
)
$copied = $false
foreach ($candidate in $dllCandidates) {
    if (Test-Path $candidate) {
        $dlls = Get-ChildItem -Path $candidate -Filter '*.dll' -File
        if ($dlls) {
            Copy-Item $dlls.FullName $dllDst -Force
            Write-Host "Copied $($dlls.Count) runtime DLL(s) from $candidate"
            $copied = $true
        }
    }
}
if (-not $copied) {
    Write-Warning 'No vcpkg runtime DLLs found to copy; the package may not run standalone.'
}

Write-Host "Done. Binary: $(Join-Path $StageDir 'bin\luanti.exe')"