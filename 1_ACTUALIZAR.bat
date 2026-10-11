@echo off
chcp 65001 >nul
rem Baja lo ultimo de GitHub (rama del proyecto). Si guardaste ShooterRob.rbxlx desde Studio,
rem antes se copia a ShooterRob_tuyo.rbxlx para no perder nada.
cd /d "%~dp0"
git diff --quiet -- ShooterRob.rbxlx
if errorlevel 1 (
  echo Tu ShooterRob.rbxlx tenia cambios: se guarda una copia en ShooterRob_tuyo.rbxlx
  copy /Y ShooterRob.rbxlx ShooterRob_tuyo.rbxlx >nul
  git checkout -- ShooterRob.rbxlx
)
git fetch origin claude/intelligent-fermi-cz7und
git checkout claude/intelligent-fermi-cz7und
git pull origin claude/intelligent-fermi-cz7und
echo.
git log --oneline -1
echo.
echo Listo: tienes la ultima version.
pause
