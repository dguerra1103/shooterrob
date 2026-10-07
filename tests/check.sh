#!/usr/bin/env bash
# Comprobaciones estáticas: construir con Rojo y analizar todo el código con luau-lsp.
#   tests/check.sh
# Variables: ROJO (por defecto "rojo"), LUAU_LSP (por defecto "luau-lsp").
# La primera vez descarga las definiciones de tipos de Roblox (globalTypes.d.luau) a tests/.cache.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROJO="${ROJO:-rojo}"
LUAU_LSP="${LUAU_LSP:-luau-lsp}"
CACHE="$ROOT/tests/.cache"
TYPES="$CACHE/globalTypes.d.luau"
cd "$ROOT"

mkdir -p "$CACHE"
echo "== rojo build"
"$ROJO" build default.project.json -o "$CACHE/ShooterRob.check.rbxlx"

if [ ! -s "$TYPES" ]; then
	echo "== descargando globalTypes.d.luau"
	curl -sSL -o "$TYPES" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi

echo "== luau-lsp analyze"
"$ROJO" sourcemap default.project.json -o sourcemap.json >/dev/null
# (los avisos de estilo y los del PlayerModule de Roblox no cuentan como errores)
OUT=$("$LUAU_LSP" analyze --definitions="$TYPES" --sourcemap=sourcemap.json src 2>&1 | grep -v -e INFO -e WARN -e PlayerModule -e LocalShadow || true)
if [ -n "$OUT" ]; then
	echo "$OUT"
	echo "luau-lsp: hay errores"
	exit 1
fi
echo "luau-lsp: sin errores"
