@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  UPX-Tools Build Script  v1.5.0
REM  Usage: Double-click or run from project root
REM ============================================================

title UPX-Tools Build

set "PROJECT_DIR=%~dp0"
set "SRC_TAURI=%PROJECT_DIR%src-tauri"
set "VERSION=1.5.0"
set "PROXY=http://127.0.0.1:7890"

cd /d "%PROJECT_DIR%"

echo.
echo ========================================================
echo     UPX-Tools Build Script  v%VERSION%
echo ========================================================
echo.

REM ============================================================
REM Phase 1 - Environment Check
REM ============================================================
echo [1/5] Checking environment...

where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js not found. Install Node.js 16+ first.
    pause
    exit /b 1
)

where npm >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] npm not found
    pause
    exit /b 1
)

where cargo >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Cargo not found. Install Rust first.
    pause
    exit /b 1
)

echo     Current Rust toolchain:
rustup show active-toolchain 2>nul
echo.
echo     [OK] Environment check passed
echo.

REM ============================================================
REM Phase 2 - Frontend Build (Tailwind CSS)
REM ============================================================
echo [2/5] Building frontend (Tailwind CSS)...

cd /d "%PROJECT_DIR%"

if not exist "node_modules\" (
    echo     Installing npm dependencies...
    call npm install --prefer-offline
    if !ERRORLEVEL! NEQ 0 (
        echo     [WARN] Retrying npm install...
        call npm install
        if !ERRORLEVEL! NEQ 0 (
            echo [ERROR] npm install failed
            pause
            exit /b 1
        )
    )
)

echo     Compiling Tailwind CSS...
call npm run build:css
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Tailwind CSS build failed
    pause
    exit /b 1
)
echo     [OK] Frontend built
echo.

REM ============================================================
REM Phase 3 - Rust Backend Build (Release)
REM ============================================================
echo [3/5] Building Rust backend (Release + LTO)...

set HTTP_PROXY=%PROXY%
set HTTPS_PROXY=%PROXY%

cd /d "%SRC_TAURI%"

rustup show active-toolchain | findstr "msvc" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo     Switching to MSVC toolchain...
    rustup default stable-x86_64-pc-windows-msvc
)

echo     Compiling (first run ~3-5 min)...
cargo build --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Rust build failed
    pause
    exit /b 1
)
echo     [OK] Rust build complete
echo.

REM ============================================================
REM Phase 4 - Package Distribution
REM ============================================================
echo [4/5] Packaging...

cd /d "%SRC_TAURI%"

set "RELEASE_DIR=%SRC_TAURI%\target\release"
set "BUNDLE_DIR=%RELEASE_DIR%\bundle\Portable"

if not exist "%RELEASE_DIR%\UPX-Tools.exe" (
    echo [ERROR] UPX-Tools.exe not found
    pause
    exit /b 1
)

if not exist "%BUNDLE_DIR%" mkdir "%BUNDLE_DIR%"

copy /Y "%RELEASE_DIR%\UPX-Tools.exe" "%BUNDLE_DIR%\UPX-Tools.exe" >nul
copy /Y "%RELEASE_DIR%\UPX-Tools.exe" "%RELEASE_DIR%\UPX-Tools-%VERSION%-x64-portable.exe" >nul
copy /Y "%RELEASE_DIR%\UPX-Tools.exe" "%PROJECT_DIR%UPX-Tools.exe" >nul

echo     [OK] Packaging complete
echo.

REM ============================================================
REM Phase 5 - Summary
REM ============================================================
echo [5/5] Build output
echo --------------------------------------------------------

call :show "%RELEASE_DIR%\UPX-Tools.exe"           "Release build"
call :show "%BUNDLE_DIR%\UPX-Tools.exe"            "Portable bundle"
call :show "%PROJECT_DIR%UPX-Tools.exe"            "Project root"
call :show "%RELEASE_DIR%\UPX-Tools-%VERSION%-x64-portable.exe" "Versioned portable"

echo --------------------------------------------------------
echo.
echo Build complete!
echo Estimated: first run ~5min, incremental ~2min
echo.
echo Portable version includes embedded UPX engine.
echo Double-click UPX-Tools.exe to run.
echo.
pause
exit /b 0

REM ============================================================
REM Helper - Show file info
REM ============================================================
:show
if exist "%~1" (
    echo   %~2:  %~nx1  [%~z1 bytes]
) else (
    echo   %~2:  [MISSING]
)
exit /b 0
