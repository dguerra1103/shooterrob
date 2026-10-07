#!/usr/bin/env bash
# Ejecuta las pruebas automáticas del simulador (Lune + mock de Roblox). Ver tests/README.md.
#
#   tests/run_all.sh                 todas (pruebas, navegación de los 9 mapas y arranque de los 10 modos)
#   tests/run_all.sh flow econ_server   solo esas
#
# Variables: LUNE (por defecto "lune" del PATH), TEST_TIMEOUT (segundos por prueba, 300).
# Importante: ejecútalas de una en una (sin otras pruebas a la vez): algunas esperan tiempo real y con
# la máquina cargada pueden pasarse del límite.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src"
LUNE="${LUNE:-lune}"
TIMEOUT="${TEST_TIMEOUT:-300}"
cd "$ROOT/tests/harness"

if ! command -v "$LUNE" >/dev/null 2>&1; then
	echo "No se encuentra Lune ('$LUNE'). Instálalo con: aftman install (ver tests/README.md)" >&2
	exit 2
fi

TESTS=(
	smoke
	spawncheck
	rounds
	elim
	bots
	progress
	datastore
	gifts
	melee
	scoreboard
	respawn
	sightcheck
	combos
	grenade
	killstreak
	camo
	rainbow
	abilities
	friends
	event
	ranks
	infection
	infection_bots
	flagbots
	gunbots
	wheel
	news
	menu
	hudclient
	clientboot
	killfx
	charms
	bounty
	group
	sprays
	weekly
	damageind
	titles
	assists
	calabazas
	navidad
	outfitswap
	orbit
	referral
	seasons
	comeback
	firstwin
	boosters
	friendteams
	friendround
	postpass
	bundleout
	leaderboard
	featured
	movement
	shooting
	weaponsounds
	weaponanims
	botbrain
	minimap
	spawnpick
	domination
	votecheck
	botspots
	bomb
	sndround
	bombsites
	dogtags
	perks
	medals
	botsteps
	glint
	grenwarn
	podium
	ambience
	variants
	ragdoll
	bombbeep
	flow
	boot
	results
	resultsserver
	enemyname
	rewardfx
	hudreward
	loot
	questtick
	upper
	daily
	phonefx
	touchbtns
	aimfx
	realhits
	aimassist
	killcam
	uniform
	combatfx
	realshots
	scopesway
	riflepose
	bodyview
	grenadecook
	finalkillcam
	finalkillcam_server
	aimpitch_server
	enemysounds
	flashlights
	callouts
	enemyoutline
	tactical
	ace
	zonename
	soundpool
	sndround_mall
	econ_catalog
	econ_server
	econ_client
	fase1
	weaponfeel
	gunfeel
	hittelemetry
	mapvisual
	rendimiento
	hints
	qa
)
MAPS=("Construction" "Coastal" "Terminal" "MallRush 0,12,24" "RooftopDistrict 0,4,6,8,14" "MetroYard -3,0,10" "DesertBase 0,6,9,12" "Dockyard 0,4,9" "IndustrialYard 0,8")
MODES=(TDM DOM SND FFA CTF KOTH GUN ELIM INF CAL)

ok=0
failed=()
run() { # nombre, argumentos de lune...
	local name="$1"
	shift
	local out code
	out=$(timeout "$TIMEOUT" "$LUNE" run "$@" 2>&1)
	code=$?
	local last
	last=$(echo "$out" | tail -1)
	if [ $code -eq 124 ]; then
		echo "XX $name: TIEMPO AGOTADO (${TIMEOUT}s)"
		failed+=("$name")
	elif echo "$out" | grep -q "FALLO\|Stack Begin" || [ $code -ne 0 ]; then
		echo "XX $name ($code): $(echo "$out" | grep -m1 'FALLO\|error' || echo "$last")"
		failed+=("$name")
	else
		echo "ok $name: $last"
		ok=$((ok + 1))
	fi
}

if [ $# -gt 0 ]; then
	for t in "$@"; do
		run "$t" "$t.luau" "$SRC"
	done
else
	for t in "${TESTS[@]}"; do
		run "$t" "$t.luau" "$SRC"
	done
	run "econ_client (móvil)" econ_client.luau "$SRC" phone
	for spec in "${MAPS[@]}"; do
		# shellcheck disable=SC2086
		run "navcheck $spec" navcheck.luau -- "$SRC" $spec
	done
	for m in "${MODES[@]}"; do
		run "serverboot $m" serverboot.luau "$SRC" "$m"
	done
	# Ciclo de estabilidad: 10 partidas seguidas con los 10 modos
	run "ciclo 10 partidas" ciclo.luau "$SRC" 10
fi

echo "----"
echo "OK: $ok   FALLOS: ${#failed[@]}"
for f in "${failed[@]}"; do
	echo "  - $f"
done
[ ${#failed[@]} -eq 0 ]
