#!/bin/bash
#
# This script builds the 32-bit and 64-bit Windows wheels for pywinsparkle.
#
# Prerequisites:
# 1. Python 3.x
# 2. 'wheel' and 'setuptools' packages: pip install wheel setuptools
# 3. An environment that can run bash scripts (like Git Bash on Windows).
#
# Run this script from the project root or from within the BuildScripts directory.
#

# Exit immediately if a command exits with a non-zero status.
set -e
set -x

# Pull the version of winsparkle from github specified in the variable. Then
# unzip it and place it in a location that setup.py is expecting it to be.
function download_latest_winsparkle()
{
    winsparkle_version="0.9.2"

    mkdir -p ./WORK
    cd WORK 

    wget https://github.com/vslavik/winsparkle/releases/download/v$winsparkle_version/WinSparkle-$winsparkle_version.zip
    unzip WinSparkle-$winsparkle_version.zip
    cd WinSparkle-$winsparkle_version

    # Calculate correct path: we're in BuildScripts/WORK/WinSparkle-X.X.X
    # Need to go to project_root/pywinsparkle/libs
    libs_folder="../../../pywinsparkle/libs"
	
    echo "Checking directory structure..."
    ls -la
    echo "Target libs folder: $libs_folder"
    
    # Check if DLL files exist and copy them
    # WinSparkle maintains Release/x64 structure
    if [ -f "Release/WinSparkle.dll" ]; then
        echo "Found standard Release directory structure"
        # copy the x86 version (32-bit)
        echo "Copying x86 DLL from Release/..."
        cp Release/WinSparkle.dll $libs_folder/x86/
        diff Release/WinSparkle.dll $libs_folder/x86/WinSparkle.dll
        echo "x86 DLL copied successfully"
        
        # copy the x64 version (64-bit)
        echo "Copying x64 DLL from x64/Release/..."
        cp x64/Release/WinSparkle.dll $libs_folder/x64/
        diff x64/Release/WinSparkle.dll $libs_folder/x64/WinSparkle.dll
        echo "x64 DLL copied successfully"
    elif [ -f "WinSparkle.dll" ]; then
        echo "Found DLLs in root directory (flat structure)"
        # copy the x86 version
        cp WinSparkle.dll $libs_folder/x86/
        diff WinSparkle.dll $libs_folder/x86/WinSparkle.dll
        
        # copy the x64 version
        if [ -f "WinSparkle64.dll" ]; then
            echo "Copying x64 DLL (WinSparkle64.dll)..."
            cp WinSparkle64.dll $libs_folder/x64/WinSparkle.dll
            diff WinSparkle64.dll $libs_folder/x64/WinSparkle.dll
        elif [ -f "WinSparkle-x64.dll" ]; then
            echo "Copying x64 DLL (WinSparkle-x64.dll)..."
            cp WinSparkle-x64.dll $libs_folder/x64/WinSparkle.dll
            diff WinSparkle-x64.dll $libs_folder/x64/WinSparkle.dll
        else
            echo "ERROR: Cannot find x64 DLL file"
            find . -name "*.dll"
            exit 1
        fi
    else
        echo "ERROR: Cannot find WinSparkle DLL files in expected locations"
        echo "Directory contents:"
        ls -la
        echo "Searching for all DLL files:"
        find . -name "*.dll"
        exit 1
    fi

    cd ../../
    rm -r WORK
}

download_latest_winsparkle

# Navigate to the project root (one level up from this script's directory)
cd "$(dirname "$0")/.."

echo "Navigated to project root: $(pwd)"

echo "Cleaning up old build artifacts..."
rm -rf build dist pywinsparkle.egg-info

echo ""
echo "Building 64-bit wheel (win_amd64)..."
python setup.py bdist_wheel --plat-name=win_amd64

echo ""
echo "Building 32-bit wheel (win32)..."
python setup.py bdist_wheel --plat-name=win32

echo ""
echo "Build complete. Generated wheels are in the 'dist' directory:"
ls -l dist/

echo "Done."
