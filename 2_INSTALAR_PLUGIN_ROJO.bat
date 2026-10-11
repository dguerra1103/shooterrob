@echo off
chcp 65001 >nul
rem Instala (o actualiza) el plugin de Rojo en Roblox Studio. Despues, cierra y abre Studio.
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
"%ROJO%" plugin install
echo.
echo Plugin instalado. Cierra Roblox Studio y vuelve a abrirlo.
pause
