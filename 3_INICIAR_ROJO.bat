@echo off
chcp 65001 >nul
rem Conecta el codigo (carpeta src) con Roblox Studio. Deja esta ventana abierta mientras trabajas.
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
"%ROJO%" --version
echo.
echo  Deja esta ventana ABIERTA.
echo  En Roblox Studio: pestana Plugins, boton Rojo, Connect.
echo  Para parar: cierra esta ventana o pulsa Ctrl+C.
echo.
"%ROJO%" serve default.project.json
pause
