# Build script for pywinsparkle Windows wheels (PowerShell)
#
# Prerequisites:
# 1. Python 3.x installed and in PATH
# 2. 'wheel' and 'setuptools' packages: pip install wheel setuptools
#
# Run this script from the BuildScripts directory:
#   .\build_wheels.ps1

# Stop on errors
$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "Building PyWinSparkle Windows Wheels"
Write-Host "========================================"
Write-Host ""

# Set WinSparkle version
$WINSPARKLE_VERSION = "0.9.2"

# Create working directory
Write-Host "Creating working directory..."
New-Item -ItemType Directory -Force -Path "WORK" | Out-Null
Set-Location "WORK"

# Download WinSparkle
Write-Host ""
Write-Host "Downloading WinSparkle v$WINSPARKLE_VERSION..."
$DOWNLOAD_URL = "https://github.com/vslavik/winsparkle/releases/download/v$WINSPARKLE_VERSION/WinSparkle-$WINSPARKLE_VERSION.zip"
$ZIP_FILE = "WinSparkle-$WINSPARKLE_VERSION.zip"

try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ZIP_FILE
    Write-Host "Download completed successfully."
} catch {
    Write-Host "ERROR: Failed to download WinSparkle"
    Write-Host $_.Exception.Message
    exit 1
}

# Extract the zip file
Write-Host ""
Write-Host "Extracting WinSparkle..."
try {
    Expand-Archive -Path $ZIP_FILE -DestinationPath "." -Force
    Write-Host "Extraction completed successfully."
} catch {
    Write-Host "ERROR: Failed to extract WinSparkle"
    Write-Host $_.Exception.Message
    exit 1
}

Set-Location "WinSparkle-$WINSPARKLE_VERSION"

# Copy DLL files to libs folders
Write-Host ""
Write-Host "Copying DLL files to pywinsparkle libs folders..."
Write-Host "Checking directory structure..."
Get-ChildItem -Name

# Calculate correct path: we're in BuildScripts\WORK\WinSparkle-X.X.X
# Need to go to project_root\pywinsparkle\libs
$LIBS_FOLDER = "..\..\..\pywinsparkle\libs"
Write-Host "Target libs folder: $LIBS_FOLDER"

# Check if DLL files exist and copy them
# WinSparkle maintains Release/x64 structure
if (Test-Path "Release\WinSparkle.dll") {
    Write-Host "Found standard Release directory structure"
    # Copy x86 version (32-bit)
    Write-Host "Copying x86 DLL from Release\..."
    try {
        Copy-Item -Path "Release\WinSparkle.dll" -Destination "$LIBS_FOLDER\x86\WinSparkle.dll" -Force
        Write-Host "x86 DLL copied successfully."
    } catch {
        Write-Host "ERROR: Failed to copy x86 DLL"
        Write-Host $_.Exception.Message
        exit 1
    }
    
    # Copy x64 version (64-bit)
    Write-Host "Copying x64 DLL from x64\Release\..."
    try {
        Copy-Item -Path "x64\Release\WinSparkle.dll" -Destination "$LIBS_FOLDER\x64\WinSparkle.dll" -Force
        Write-Host "x64 DLL copied successfully."
    } catch {
        Write-Host "ERROR: Failed to copy x64 DLL"
        Write-Host $_.Exception.Message
        exit 1
    }
} elseif (Test-Path "WinSparkle.dll") {
    Write-Host "Found DLLs in root directory (flat structure)"
    # Copy x86 version
    Write-Host "Copying x86 DLL..."
    try {
        Copy-Item -Path "WinSparkle.dll" -Destination "$LIBS_FOLDER\x86\WinSparkle.dll" -Force
        Write-Host "x86 DLL copied successfully."
    } catch {
        Write-Host "ERROR: Failed to copy x86 DLL"
        Write-Host $_.Exception.Message
        exit 1
    }
    # Copy x64 version
    if (Test-Path "WinSparkle64.dll") {
        Write-Host "Copying x64 DLL (WinSparkle64.dll)..."
        Copy-Item -Path "WinSparkle64.dll" -Destination "$LIBS_FOLDER\x64\WinSparkle.dll" -Force
    } elseif (Test-Path "WinSparkle-x64.dll") {
        Write-Host "Copying x64 DLL (WinSparkle-x64.dll)..."
        Copy-Item -Path "WinSparkle-x64.dll" -Destination "$LIBS_FOLDER\x64\WinSparkle.dll" -Force
    } else {
        Write-Host "ERROR: Cannot find x64 DLL file"
        Get-ChildItem -Recurse -Filter *.dll | Select-Object FullName
        exit 1
    }
} else {
    Write-Host "ERROR: Cannot find WinSparkle DLL files in expected locations"
    Write-Host ""
    Write-Host "Directory contents:"
    Get-ChildItem
    Write-Host ""
    Write-Host "Searching for all DLL files:"
    Get-ChildItem -Recurse -Filter *.dll | Select-Object FullName
    exit 1
}

# Go back to BuildScripts directory
Set-Location "..\..\"

# Clean up WORK directory
Write-Host ""
Write-Host "Cleaning up temporary files..."
Remove-Item -Path "WORK" -Recurse -Force

# Navigate to project root
Set-Location ".."

Write-Host ""
Write-Host "========================================"
Write-Host "Building Python Wheels"
Write-Host "========================================"
Write-Host ""

# Clean up old build artifacts
Write-Host "Cleaning up old build artifacts..."
if (Test-Path "build") { Remove-Item -Path "build" -Recurse -Force }
if (Test-Path "dist") { Remove-Item -Path "dist" -Recurse -Force }
if (Test-Path "pywinsparkle.egg-info") { Remove-Item -Path "pywinsparkle.egg-info" -Recurse -Force }

# Build wheels
Write-Host ""
Write-Host "Building 64-bit wheel (win_amd64)..."
try {
    & python setup.py bdist_wheel --plat-name=win_amd64
    if ($LASTEXITCODE -ne 0) {
        throw "Python build command failed"
    }
    Write-Host "win_amd64 wheel built successfully."
} catch {
    Write-Host "ERROR: Failed to build win_amd64 wheel"
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host ""
Write-Host "Building 32-bit wheel (win32)..."
try {
    & python setup.py bdist_wheel --plat-name=win32
    if ($LASTEXITCODE -ne 0) {
        throw "Python build command failed"
    }
    Write-Host "win32 wheel built successfully."
} catch {
    Write-Host "ERROR: Failed to build win32 wheel"
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host ""
Write-Host "========================================"
Write-Host "Build Complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "Generated wheels are in the 'dist' directory:"
Get-ChildItem -Path "dist\*.whl" | Format-Table Name, Length, LastWriteTime

Write-Host ""
Write-Host "Done."

Set-Location "BuildScripts"
