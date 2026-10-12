@echo off
chcp 65001 >nul
rem Crea en Roblox los productos de pago de la tienda (con su icono) y apunta sus ids en el juego.
rem Pide el id del universo y la clave de Open Cloud por teclado: la clave no se guarda en ningun sitio.
rem Primero ensena la lista y pregunta; no crea nada hasta que escribes SI.
rem Guia completa: MONETIZACION.md
cd /d "%~dp0"
set "PY=python"
where python >nul 2>nul || set "PY=py -3"
%PY% -X utf8 scripts\monetizacion\crear_productos.py --preguntar --iconos %*
echo.
if errorlevel 1 (
  echo Algo ha fallado. Manda captura de esta ventana ^(la clave no aparece en ella^).
) else (
  echo Terminado. Si se han creado, ejecuta ahora 4_CONSTRUIR_Y_ABRIR_PLACE.bat y prueba la tienda.
)
pause
