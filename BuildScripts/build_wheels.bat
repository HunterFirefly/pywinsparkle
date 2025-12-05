@echo off
REM Build script for pywinsparkle Windows wheels
REM 
REM Prerequisites:
REM 1. Python 3.x installed and in PATH
REM 2. 'wheel' and 'setuptools' packages: pip install wheel setuptools
REM 3. PowerShell available for downloading files
REM
REM Run this script from the BuildScripts directory

setlocal enabledelayedexpansion

echo ========================================
echo Building PyWinSparkle Windows Wheels
echo ========================================
echo.

REM Set WinSparkle version
set WINSPARKLE_VERSION=0.9.2

REM Create working directory
echo Creating working directory...
if not exist WORK mkdir WORK
cd WORK

REM Download WinSparkle
echo.
echo Downloading WinSparkle v%WINSPARKLE_VERSION%...
set DOWNLOAD_URL=https://github.com/vslavik/winsparkle/releases/download/v%WINSPARKLE_VERSION%/WinSparkle-%WINSPARKLE_VERSION%.zip
set ZIP_FILE=WinSparkle-%WINSPARKLE_VERSION%.zip

powershell -Command "& {Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'}"
if errorlevel 1 (
    echo ERROR: Failed to download WinSparkle
    exit /b 1
)

REM Extract the zip file
echo.
echo Extracting WinSparkle...
powershell -Command "& {Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '.' -Force}"
if errorlevel 1 (
    echo ERROR: Failed to extract WinSparkle
    exit /b 1
)

cd WinSparkle-%WINSPARKLE_VERSION%

REM Copy DLL files to libs folders
echo.
echo Copying DLL files to pywinsparkle libs folders...
echo Checking directory structure...
dir /b

REM Calculate correct path: we're in <project>\WORK\WinSparkle-X.X.X
REM Need to go to <project>\pywinsparkle\libs
REM Path: ..\.. goes up to project root, then into pywinsparkle\libs
set LIBS_FOLDER=..\..\pywinsparkle\libs
echo Target libs folder: %LIBS_FOLDER%
echo Current directory: %CD%
echo.

REM Check if target directory exists
if not exist %LIBS_FOLDER%\x86 (
    echo ERROR: Target directory does not exist: %LIBS_FOLDER%\x86
    echo Creating directory...
    mkdir %LIBS_FOLDER%\x86
)
if not exist %LIBS_FOLDER%\x64 (
    echo Creating directory...
    mkdir %LIBS_FOLDER%\x64
)

REM Check if DLL files exist and copy them
REM WinSparkle 0.8.0+ maintains Release/x64 structure
if exist Release\WinSparkle.dll (
    echo Found standard Release directory structure
    REM Copy x86 version (32-bit)
    echo Copying x86 DLL from Release\...
    echo Source: %CD%\Release\WinSparkle.dll
    echo Target: %LIBS_FOLDER%\x86\WinSparkle.dll
    copy /Y Release\WinSparkle.dll %LIBS_FOLDER%\x86\WinSparkle.dll
    if errorlevel 1 (
        echo ERROR: Failed to copy x86 DLL
        exit /b 1
    )
    echo x86 DLL copied successfully
    
    REM Copy x64 version (64-bit)
    echo Copying x64 DLL from x64\Release\...
    copy /Y x64\Release\WinSparkle.dll %LIBS_FOLDER%\x64\WinSparkle.dll
    if errorlevel 1 (
        echo ERROR: Failed to copy x64 DLL
        exit /b 1
    )
    echo x64 DLL copied successfully
    
    REM Skip to cleanup - we're done
    goto :copy_complete
)

REM Alternative: check for flat structure (if Release\ doesn't exist)
if exist WinSparkle.dll (
    echo Found DLLs in root directory (flat structure)
    REM Copy x86 version
    echo Copying x86 DLL...
    copy /Y WinSparkle.dll %LIBS_FOLDER%\x86\WinSparkle.dll
    if errorlevel 1 (
        echo ERROR: Failed to copy x86 DLL
        exit /b 1
    )
    REM Copy x64 version - check for both possible names
    if exist WinSparkle64.dll (
        echo Copying x64 DLL (WinSparkle64.dll)...
        copy /Y WinSparkle64.dll %LIBS_FOLDER%\x64\WinSparkle.dll
        if errorlevel 1 (
            echo ERROR: Failed to copy x64 DLL
            exit /b 1
        )
    ) else if exist WinSparkle-x64.dll (
        echo Copying x64 DLL (WinSparkle-x64.dll)...
        copy /Y WinSparkle-x64.dll %LIBS_FOLDER%\x64\WinSparkle.dll
        if errorlevel 1 (
            echo ERROR: Failed to copy x64 DLL
            exit /b 1
        )
    ) else (
        echo ERROR: Cannot find x64 DLL file
        echo Listing all DLL files:
        dir /s /b *.dll
        exit /b 1
    )
    
    REM Skip to cleanup - we're done
    goto :copy_complete
)

REM If we get here, no DLLs were found
echo ERROR: Cannot find WinSparkle DLL files in expected locations
echo.
echo Directory contents:
dir
echo.
echo Searching for all DLL files:
dir /s /b *.dll
exit /b 1

:copy_complete
echo.
echo DLL files copied successfully!

REM Go back to project root from WinSparkle-X.X.X
REM Current: <project>\WORK\WinSparkle-X.X.X
REM Target: <project> (where setup.py is)
REM Path: ..\.. means up 2 levels: WinSparkle-X.X.X -> WORK -> project root
cd ..\..

REM Verify we're in project root
echo Current directory for build: %CD%
if not exist setup.py (
    echo ERROR: setup.py not found in current directory
    echo Current directory: %CD%
    dir
    exit /b 1
)

REM Clean up WORK directory (now we can access it from project root)
echo.
echo Cleaning up temporary files...
rmdir /S /Q WORK
if errorlevel 1 (
    echo Warning: Failed to remove WORK directory
)

echo.
echo ========================================
echo Building Python Wheels
echo ========================================
echo.

REM Clean up old build artifacts
echo Cleaning up old build artifacts...
if exist build rmdir /S /Q build
if exist dist rmdir /S /Q dist
if exist pywinsparkle.egg-info rmdir /S /Q pywinsparkle.egg-info

REM Build wheels
echo.
echo Building 64-bit wheel (win_amd64)...
python setup.py bdist_wheel --plat-name=win_amd64
if errorlevel 1 (
    echo ERROR: Failed to build win_amd64 wheel
    exit /b 1
)

echo.
echo Building 32-bit wheel (win32)...
python setup.py bdist_wheel --plat-name=win32
if errorlevel 1 (
    echo ERROR: Failed to build win32 wheel
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Generated wheels are in the 'dist' directory:
dir dist\*.whl

echo.
echo Done.

cd BuildScripts
endlocal
