#!/usr/bin/env bash
# Publica el archivo del juego en Roblox usando Open Cloud.
#
# Variables necesarias:
#   ROBLOX_API_KEY      clave de API (Creator Hub > Credenciales) con permiso "universe-places: write"
#   ROBLOX_UNIVERSE_ID  ID de la experiencia (Universe ID)
#   ROBLOX_PLACE_ID     ID del lugar (Place ID)
# Opcional:
#   ROBLOX_VERSION_TYPE "Saved" (por defecto: solo guarda una versión) o "Published" (la ven los jugadores)
#
# Uso: scripts/publish.sh [archivo.rbxlx]
set -euo pipefail

: "${ROBLOX_API_KEY:?Falta la variable ROBLOX_API_KEY}"
: "${ROBLOX_UNIVERSE_ID:?Falta la variable ROBLOX_UNIVERSE_ID}"
: "${ROBLOX_PLACE_ID:?Falta la variable ROBLOX_PLACE_ID}"

FILE="${1:-ShooterRob.rbxlx}"
VERSION_TYPE="${ROBLOX_VERSION_TYPE:-Saved}"

if [[ ! -f "$FILE" ]]; then
	echo "No existe $FILE. Genéralo con: rojo build -o $FILE" >&2
	exit 1
fi

case "$FILE" in
	*.rbxlx) CONTENT_TYPE="application/xml" ;;
	*) CONTENT_TYPE="application/octet-stream" ;;
esac

URL="https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=${VERSION_TYPE}"
echo "Publicando $FILE en el lugar $ROBLOX_PLACE_ID ($VERSION_TYPE)..."

RESPONSE=$(curl -sS -w '\n%{http_code}' -X POST "$URL" \
	-H "x-api-key: ${ROBLOX_API_KEY}" \
	-H "Content-Type: ${CONTENT_TYPE}" \
	--data-binary @"$FILE")
BODY=$(echo "$RESPONSE" | sed '$d')
STATUS=$(echo "$RESPONSE" | tail -n1)

if [[ "$STATUS" != "200" ]]; then
	echo "Error $STATUS al publicar: $BODY" >&2
	exit 1
fi
echo "¡Publicado! Respuesta: $BODY"
