# =============================================================================
# CTO Codebase Evaluation Suite - Installation Script (Windows PowerShell)
# =============================================================================
# Run as: powershell -ExecutionPolicy Bypass -File install.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Write-Color ""
    Write-Color "╔═══════════════════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║         CTO Codebase Evaluation Suite - Installer (Windows)          ║" "Cyan"
    Write-Color "╚═══════════════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-ChocolateyInstalled {
    Test-CommandExists "choco"
}

function Test-WingetInstalled {
    Test-CommandExists "winget"
}

function Install-WithChocolatey {
    param([string]$Package)
    Write-Color "Installing $Package with Chocolatey..." "Blue"
    choco install $Package -y
}

function Install-WithWinget {
    param([string]$Package, [string]$Id)
    Write-Color "Installing $Package with winget..." "Blue"
    winget install --id $Id --accept-package-agreements --accept-source-agreements
}

# =============================================================================
# Main Installation
# =============================================================================

Write-Banner

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Color "Detected: Windows PowerShell" "Blue"
Write-Color ""

# Check for package manager
$HasChocolatey = Test-ChocolateyInstalled
$HasWinget = Test-WingetInstalled

if (-not $HasChocolatey -and -not $HasWinget) {
    Write-Color "No package manager found (Chocolatey or winget)." "Yellow"
    Write-Color ""
    Write-Color "Please install one of the following:" "Yellow"
    Write-Color "  - Chocolatey: https://chocolatey.org/install" "White"
    Write-Color "  - winget: Included with Windows 11 / App Installer from Microsoft Store" "White"
    Write-Color ""
}

# =============================================================================
# Check Dependencies
# =============================================================================

Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Color "  Checking Dependencies" "Cyan"
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Color ""

$MissingRequired = @()
$MissingOptional = @()

# Node.js
if (Test-CommandExists "node") {
    $NodeVersion = node --version
    Write-Color "✓ Node.js $NodeVersion" "Green"
} else {
    Write-Color "✗ Node.js (required)" "Red"
    $MissingRequired += "nodejs"
}

# npm
if (Test-CommandExists "npm") {
    $NpmVersion = npm --version
    Write-Color "✓ npm $NpmVersion" "Green"
} else {
    Write-Color "✗ npm (required)" "Red"
    $MissingRequired += "npm"
}

# jq
if (Test-CommandExists "jq") {
    $JqVersion = jq --version
    Write-Color "✓ jq $JqVersion" "Green"
} else {
    Write-Color "✗ jq (required)" "Red"
    $MissingRequired += "jq"
}

# Git
if (Test-CommandExists "git") {
    $GitVersion = (git --version) -replace "git version ", ""
    Write-Color "✓ Git $GitVersion" "Green"
} else {
    Write-Color "✗ Git (required)" "Red"
    $MissingRequired += "git"
}

# Git Bash (for running bash scripts)
$GitBashPath = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $GitBashPath) {
    Write-Color "✓ Git Bash found" "Green"
} else {
    Write-Color "✗ Git Bash (required - install Git for Windows)" "Red"
    $MissingRequired += "git-bash"
}

# Docker (optional)
if (Test-CommandExists "docker") {
    $DockerVersion = (docker --version) -replace "Docker version ", "" -replace ",.*", ""
    Write-Color "✓ Docker $DockerVersion" "Green"
} else {
    Write-Color "○ Docker (optional)" "Yellow"
    $MissingOptional += "docker"
}

# Python (optional)
if (Test-CommandExists "python") {
    $PythonVersion = (python --version) -replace "Python ", ""
    Write-Color "✓ Python $PythonVersion" "Green"
} else {
    Write-Color "○ Python (optional)" "Yellow"
    $MissingOptional += "python"
}

Write-Color ""

# =============================================================================
# Install Missing Dependencies
# =============================================================================

if ($MissingRequired.Count -gt 0) {
    Write-Color "Missing required dependencies: $($MissingRequired -join ', ')" "Yellow"
    Write-Color ""
    
    $InstallDeps = Read-Host "Would you like to install them? (y/n)"
    
    if ($InstallDeps -eq "y" -or $InstallDeps -eq "Y") {
        foreach ($dep in $MissingRequired) {
            switch ($dep) {
                "nodejs" {
                    if ($HasWinget) {
                        Install-WithWinget "Node.js" "OpenJS.NodeJS.LTS"
                    } elseif ($HasChocolatey) {
                        Install-WithChocolatey "nodejs-lts"
                    } else {
                        Write-Color "Please install Node.js from: https://nodejs.org/" "Yellow"
                    }
                }
                "jq" {
                    if ($HasChocolatey) {
                        Install-WithChocolatey "jq"
                    } elseif ($HasWinget) {
                        Install-WithWinget "jq" "jqlang.jq"
                    } else {
                        Write-Color "Please install jq from: https://stedolan.github.io/jq/download/" "Yellow"
                    }
                }
                "git" {
                    if ($HasWinget) {
                        Install-WithWinget "Git" "Git.Git"
                    } elseif ($HasChocolatey) {
                        Install-WithChocolatey "git"
                    } else {
                        Write-Color "Please install Git from: https://git-scm.com/download/win" "Yellow"
                    }
                }
                "git-bash" {
                    Write-Color "Git Bash is included with Git for Windows" "Yellow"
                }
            }
        }
        
        Write-Color ""
        Write-Color "Please restart PowerShell after installation and run this script again." "Yellow"
        exit 0
    } else {
        Write-Color ""
        Write-Color "Please install dependencies manually:" "Yellow"
        Write-Color "  - Node.js: https://nodejs.org/" "White"
        Write-Color "  - Git (includes Git Bash): https://git-scm.com/download/win" "White"
        Write-Color "  - jq: choco install jq  OR  winget install jqlang.jq" "White"
        exit 1
    }
}

# =============================================================================
# Install Node.js Global Packages
# =============================================================================

Write-Color ""
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Color "  Installing Node.js Analysis Tools" "Cyan"
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Color ""

$NpmPackages = @("eslint", "jscpd", "madge", "typescript")

foreach ($pkg in $NpmPackages) {
    $installed = npm list -g $pkg 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Color "✓ $pkg already installed" "Green"
    } else {
        Write-Color "Installing $pkg..." "Blue"
        npm install -g $pkg
    }
}

# =============================================================================
# Create Windows Launcher
# =============================================================================

Write-Color ""
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Color "  Setting Up Windows Launcher" "Cyan"
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Color ""

Write-Color "✓ Windows launcher (evaluate.ps1) is ready" "Green"
Write-Color "✓ Batch file (evaluate.bat) is ready" "Green"

# =============================================================================
# Done
# =============================================================================

Write-Color ""
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
Write-Color "  Installation Complete!" "Green"
Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
Write-Color ""
Write-Color "  To evaluate a codebase:" "Blue"
Write-Color ""
Write-Color "    cd $ScriptDir" "White"
Write-Color "    .\evaluate.ps1 C:\path\to\your\codebase" "White"
Write-Color ""
Write-Color "  Or use the batch file:" "Blue"
Write-Color ""
Write-Color "    evaluate.bat C:\path\to\your\codebase" "White"
Write-Color ""
Write-Color "  Or use interactive mode (opens folder picker):" "Blue"
Write-Color ""
Write-Color "    .\evaluate.ps1" "White"
Write-Color ""
Write-Color "  For help:" "Blue"
Write-Color ""
Write-Color "    .\evaluate.ps1 --help" "White"
Write-Color ""
