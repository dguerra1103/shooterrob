@echo off
chcp 65001 >nul
rem Genera ShooterRob.rbxlx con todo el codigo actual y lo abre en Roblox Studio (sin Rojo conectado).
cd /d "%~dp0"
set "ROJO="
if exist "%~dp0rojo.exe" set "ROJO=%~dp0rojo.exe"
if not defined ROJO for /r "%USERPROFILE%\.aftman\tool-storage\rojo-rbx\rojo" %%f in (rojo.exe) do if exist "%%f" set "ROJO=%%f"
if not defined ROJO (
  echo.
  echo No encuentro rojo.exe.
  echo Abre PowerShell en esta carpeta y ejecuta:  aftman install
  echo O descarga rojo-7.4.4-windows-x86_64.zip de github.com/rojo-rbx/rojo/releases
  echo y pon rojo.exe dentro de esta carpeta.
  echo.
  pause
  exit /b 1
)
"%ROJO%" build default.project.json -o ShooterRob.rbxlx
if errorlevel 1 (
  echo No se pudo construir. Manda captura de esta ventana.
  pause
  exit /b 1
)
echo Construido. Abriendo en Roblox Studio...
start "" "%~dp0ShooterRob.rbxlx"
