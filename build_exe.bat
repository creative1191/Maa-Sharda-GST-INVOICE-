@echo off
title GST Invoice Generator - EXE Builder
cd /d "%~dp0"

echo ============================================
echo   GST Invoice Generator - EXE Builder
echo ============================================
echo.

where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python nahi mila. https://www.python.org/downloads/ se install karo
    echo         ^(install karte waqt "Add Python to PATH" tick karna zaroori hai^)
    pause
    exit /b 1
)

echo [1/2] Dependencies install ho rahi hain... ^(first time ~2 min^)
python -m pip install --upgrade pip >nul
python -m pip install -r requirements.txt pyinstaller
if errorlevel 1 (
    echo [ERROR] Dependencies install nahi hui. Internet check karo.
    pause
    exit /b 1
)

echo.
echo [2/2] EXE ban rahi hai... ^(~2-3 min^)
python -m PyInstaller --onefile --windowed --collect-all customtkinter --name GST_Invoice_Generator --noconfirm src\gst_desktop.py
if errorlevel 1 (
    echo [ERROR] Build fail hui. Upar ka error padho.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   HO GAYA! ^| EXE yahan hai:
echo   dist\GST_Invoice_Generator.exe
echo ============================================
echo   Tip: exe ko Desktop par copy kar lo.
echo   Data ^(clients/invoices^) exe ke folder me bante hain.
echo.
pause
