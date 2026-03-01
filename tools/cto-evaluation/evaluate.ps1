# =============================================================================
# CTO Codebase Evaluation Suite - Windows PowerShell Launcher
# =============================================================================
# Usage:
#   .\evaluate.ps1                      # Interactive - opens folder picker
#   .\evaluate.ps1 C:\path\to\codebase  # Evaluate specific folder
#   .\evaluate.ps1 --help               # Show help
# =============================================================================

param(
    [Parameter(Position=0)]
    [string]$CodebasePath,
    
    [switch]$Quick,
    [switch]$SkipSecurity,
    [switch]$SkipPerformance,
    [switch]$Verbose,
    [switch]$Help
)

$ErrorActionPreference = "Continue"

# Colors
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Clear-Host
    Write-Color ""
    Write-Color "╔═══════════════════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║                                                                       ║" "Cyan"
    Write-Color "║     ██████╗████████╗ ██████╗     ███████╗██╗   ██╗ █████╗ ██╗         ║" "Cyan"
    Write-Color "║    ██╔════╝╚══██╔══╝██╔═══██╗    ██╔════╝██║   ██║██╔══██╗██║         ║" "Cyan"
    Write-Color "║    ██║        ██║   ██║   ██║    █████╗  ██║   ██║███████║██║         ║" "Cyan"
    Write-Color "║    ██║        ██║   ██║   ██║    ██╔══╝  ╚██╗ ██╔╝██╔══██║██║         ║" "Cyan"
    Write-Color "║    ╚██████╗   ██║   ╚██████╔╝    ███████╗ ╚████╔╝ ██║  ██║███████╗    ║" "Cyan"
    Write-Color "║     ╚═════╝   ╚═╝    ╚═════╝     ╚══════╝  ╚═══╝  ╚═╝  ╚═╝╚══════╝    ║" "Cyan"
    Write-Color "║                                                                       ║" "Cyan"
    Write-Color "║              CODEBASE EVALUATION FRAMEWORK v1.0                       ║" "Cyan"
    Write-Color "║                    495 Parameters | 21 Categories                     ║" "Cyan"
    Write-Color "║                                                                       ║" "Cyan"
    Write-Color "╚═══════════════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""
}

function Show-Help {
    Write-Banner
    Write-Color ""
    Write-Color "Usage:" "Green"
    Write-Color "  .\evaluate.ps1                        Interactive mode - opens folder picker" "White"
    Write-Color "  .\evaluate.ps1 C:\path\to\codebase    Evaluate the specified folder" "White"
    Write-Color "  .\evaluate.ps1 --help                 Show this help" "White"
    Write-Color ""
    Write-Color "Options:" "Green"
    Write-Color "  -Quick              Run quick evaluation (faster, fewer checks)" "White"
    Write-Color "  -SkipSecurity       Skip security scanning" "White"
    Write-Color "  -SkipPerformance    Skip performance testing" "White"
    Write-Color "  -Verbose            Show detailed output" "White"
    Write-Color ""
    Write-Color "Results:" "Green"
    Write-Color "  Results are saved in the target codebase folder as:" "White"
    Write-Color "    <codebase>\.cto-evaluation\evaluation_<timestamp>\" "White"
    Write-Color ""
    Write-Color "Examples:" "Green"
    Write-Color "  .\evaluate.ps1 C:\Projects\my-app" "White"
    Write-Color "  .\evaluate.ps1 C:\Projects\my-app -Quick" "White"
    Write-Color "  .\evaluate.ps1   # Opens folder picker" "White"
    Write-Color ""
}

function Select-FolderDialog {
    Add-Type -AssemblyName System.Windows.Forms
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the codebase folder to evaluate"
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $folderBrowser.ShowNewFolderButton = $false
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}

function Test-IsCodebase {
    param([string]$Path)
    
    # Check for common project files
    $projectFiles = @(
        "package.json",
        "requirements.txt",
        "pyproject.toml",
        "go.mod",
        "Cargo.toml",
        "pom.xml",
        "build.gradle",
        "Gemfile",
        "composer.json",
        "Makefile",
        ".git"
    )
    
    foreach ($file in $projectFiles) {
        if (Test-Path (Join-Path $Path $file)) {
            return $true
        }
    }
    
    # Check for source files
    $sourceExtensions = @("*.js", "*.ts", "*.py", "*.go", "*.java", "*.rs", "*.rb", "*.php", "*.cs", "*.cpp", "*.c")
    foreach ($ext in $sourceExtensions) {
        if (Get-ChildItem -Path $Path -Filter $ext -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 1) {
            return $true
        }
    }
    
    return $false
}

function Invoke-Evaluation {
    param(
        [string]$Path,
        [string[]]$ExtraArgs
    )
    
    # Get absolute path
    $Path = (Resolve-Path $Path).Path
    
    # Create results directory in the codebase folder
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $ResultsDir = Join-Path $Path ".cto-evaluation\evaluation_$Timestamp"
    
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
    
    Write-Color ""
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
    Write-Color "  EVALUATION CONFIGURATION" "Green"
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
    Write-Color ""
    Write-Color "  Codebase:     $Path" "White"
    Write-Color "  Results Dir:  $ResultsDir" "White"
    Write-Color "  Options:      $($ExtraArgs -join ' ')" "White"
    Write-Color ""
    
    $Confirm = Read-Host "Start evaluation? (Y/n)"
    if ($Confirm -eq "n" -or $Confirm -eq "N") {
        Write-Color "Evaluation cancelled." "Yellow"
        exit 0
    }
    
    Write-Color ""
    Write-Color "Starting evaluation..." "Cyan"
    Write-Color ""
    
    # Find Git Bash
    $GitBashPaths = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    
    $GitBash = $null
    foreach ($bashPath in $GitBashPaths) {
        if (Test-Path $bashPath) {
            $GitBash = $bashPath
            break
        }
    }
    
    if (-not $GitBash) {
        Write-Color "Error: Git Bash not found. Please install Git for Windows." "Red"
        Write-Color "Download from: https://git-scm.com/download/win" "Yellow"
        exit 1
    }
    
    # Convert Windows path to Unix path for bash
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $UnixScriptDir = $ScriptDir -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
    $UnixCodebasePath = $Path -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
    $UnixOutputDir = (Join-Path $Path ".cto-evaluation") -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
    
    # Build arguments
    $BashArgs = @(
        "$UnixScriptDir/scripts/run-full-evaluation.sh",
        $UnixCodebasePath,
        "--output-dir",
        $UnixOutputDir
    )
    $BashArgs += $ExtraArgs
    
    # Run evaluation using Git Bash
    & $GitBash -c "$($BashArgs -join ' ')"
    
    # Show results
    Write-Color ""
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
    Write-Color "  EVALUATION COMPLETE" "Green"
    Write-Color "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
    Write-Color ""
    Write-Color "  Results saved to:" "Blue"
    Write-Color "    $Path\.cto-evaluation\" "White"
    Write-Color ""
    
    # Find latest evaluation
    $LatestEval = Get-ChildItem -Path (Join-Path $Path ".cto-evaluation") -Directory | 
                  Where-Object { $_.Name -like "evaluation_*" } | 
                  Sort-Object Name -Descending | 
                  Select-Object -First 1
    
    if ($LatestEval) {
        $ReportMd = Join-Path $LatestEval.FullName "report.md"
        $ReportHtml = Join-Path $LatestEval.FullName "report.html"
        
        Write-Color "  View the report:" "Blue"
        Write-Color "    Get-Content $ReportMd" "White"
        Write-Color ""
        
        $OpenReport = Read-Host "Open report now? (y/N)"
        if ($OpenReport -eq "y" -or $OpenReport -eq "Y") {
            if (Test-Path $ReportHtml) {
                Start-Process $ReportHtml
            } elseif (Test-Path $ReportMd) {
                Get-Content $ReportMd
            }
        }
    }
}

# =============================================================================
# Main
# =============================================================================

if ($Help) {
    Show-Help
    exit 0
}

Write-Banner

# Build extra arguments
$ExtraArgs = @()
if ($Quick) { $ExtraArgs += "--quick" }
if ($SkipSecurity) { $ExtraArgs += "--skip-security" }
if ($SkipPerformance) { $ExtraArgs += "--skip-performance" }
if ($Verbose) { $ExtraArgs += "--verbose" }

# If no path provided, open folder picker
if (-not $CodebasePath) {
    Write-Color "No codebase path provided. Opening folder picker..." "Yellow"
    Write-Color ""
    
    $CodebasePath = Select-FolderDialog
    
    if (-not $CodebasePath) {
        Write-Color "No folder selected. Exiting." "Red"
        exit 1
    }
}

# Validate path exists
if (-not (Test-Path $CodebasePath)) {
    Write-Color "Error: Folder does not exist: $CodebasePath" "Red"
    exit 1
}

# Validate it looks like a codebase
if (-not (Test-IsCodebase $CodebasePath)) {
    Write-Color "Warning: This folder doesn't appear to be a codebase." "Yellow"
    $Continue = Read-Host "Continue anyway? (y/n)"
    if ($Continue -ne "y" -and $Continue -ne "Y") {
        exit 1
    }
}

# Run evaluation
Invoke-Evaluation -Path $CodebasePath -ExtraArgs $ExtraArgs
