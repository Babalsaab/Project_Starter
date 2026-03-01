@echo off
REM =============================================================================
REM CTO Codebase Evaluation Suite - Windows Batch Launcher
REM =============================================================================
REM Usage: evaluate.bat [path\to\codebase] [options]
REM =============================================================================

setlocal EnableDelayedExpansion

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: PowerShell is required but not found.
    echo Please install PowerShell or use Git Bash directly.
    exit /b 1
)

REM Forward all arguments to the PowerShell script
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%evaluate.ps1" %*
