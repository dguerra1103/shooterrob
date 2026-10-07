-- Consejos de contexto (Fase 6): solo para jugadores nuevos, cada uno una vez, con espacio entre
-- ellos, nunca con un menú o la pantalla de muerte encima, y sin tocar los datos
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local Hints = req(game.StarterPlayer.Client.Modules.Hints)
Hints.Init()

local data = { Level = 2, TutorialDone = true }
ClientState.Data = data
ClientState.InMainMenu = false
ClientState.Dead = false
local rifle = { Type = "Gun", Pellets = 1 }
ClientState.CurrentDef = rifle
ClientState.AimAlpha = 0
ClientState.LastHitTime = 0

local function hint()
	local gui = pg:FindFirstChild("Hints")
	return gui and gui:FindFirstChild("Hint")
end
local function visible()
	local h = hint()
	return h ~= nil and h.Visible == true
end
local function hipBurst(n)
	for _ = 1, n do
		ClientState.ShotFired:Fire()
	end
end

-- Apuntar: ráfaga a la cadera sin acertar
hipBurst(Hints.HipShots - 1)
check(not visible(), "pocos disparos a la cadera: sin consejo")
hipBurst(1)
check(visible() and string.find(hint().Text, "apuntar", 1, true) ~= nil, "muchos disparos a la cadera sin acertar: consejo de apuntar («" .. (hint() and hint().Text or "") .. "»)")

-- Espacio entre consejos: el siguiente no sale enseguida
ClientState.WeaponEvent:Fire("ReloadStart", "Rifle", { Empty = true, Duration = 2 })
check(not string.find(hint().Text, "recargar", 1, true), "otro consejo justo después: no sale (espacio entre consejos)")

-- Sin espera (prueba): sale el de recargar
Hints.Gap = 0
ClientState.WeaponEvent:Fire("ReloadStart", "Rifle", { Empty = false, Duration = 2 })
check(not string.find(hint().Text, "recargar", 1, true), "recargar con balas: sin consejo")
ClientState.WeaponEvent:Fire("ReloadStart", "Rifle", { Empty = true, Duration = 2 })
check(string.find(hint().Text, "recargar", 1, true) ~= nil, "recargar con el cargador vacío: consejo de recargar antes")

-- Cada consejo, una vez por sesión
hint().Text = ""
hipBurst(Hints.HipShots * 2)
check(hint().Text == "", "el consejo de apuntar no se repite")

-- Apuntando, con escopeta o acertando: nada
Hints.Reset()
ClientState.AimAlpha = 1
hipBurst(Hints.HipShots * 2)
check(not visible() or not string.find(hint().Text, "apuntar", 1, true), "apuntando: sin consejo de apuntar")
ClientState.AimAlpha = 0
hint().Visible = false
ClientState.CurrentDef = { Type = "Gun", Pellets = 8 }
hipBurst(Hints.HipShots * 2)
check(not visible(), "con escopeta: sin consejo de apuntar")
ClientState.CurrentDef = rifle
ClientState.LastHitTime = os.clock()
hipBurst(Hints.HipShots * 2)
check(not visible(), "si aciertas: sin consejo de apuntar")
ClientState.LastHitTime = 0

-- Poca vida: cubrirse
local humanoid = mock.new("Humanoid")
humanoid.MaxHealth = 100
humanoid.Health = 60
Hints.CheckHealth(humanoid)
check(not visible(), "vida a 60: sin consejo")
humanoid.Health = 20
Hints.CheckHealth(humanoid)
check(visible() and string.find(hint().Text, "cubierto", 1, true) ~= nil, "vida a 20: consejo de cubrirse")

-- Si mueres con un consejo en pantalla, se quita en el acto (no se queda encima de la muerte)
check(visible(), "(el consejo de cubrirse sigue en pantalla)")
ClientState.Dead = true
Hints.Tick()
check(not visible(), "al morir, el consejo en pantalla se quita")
ClientState.Dead = false

-- Nunca con la pantalla de muerte, un menú, la killcam o los resultados
for _, blocker in { "Dead", "MenuOpen", "KillcamActive", "ResultsActive", "InMainMenu" } do
	Hints.Reset()
	hint().Visible = false
	ClientState[blocker] = true
	hipBurst(Hints.HipShots)
	check(not visible(), "con " .. blocker .. ": sin consejos")
	ClientState[blocker] = false
end

-- Jugadores con experiencia: nada
Hints.Reset()
hint().Visible = false
data.Level = Hints.MaxLevel + 1
hipBurst(Hints.HipShots)
humanoid.Health = 10
Hints.CheckHealth(humanoid)
check(not visible(), "nivel " .. data.Level .. ": sin consejos")

-- No toca los datos
local keys = 0
for _ in data do keys += 1 end
check(keys == 2, "los datos del jugador no cambian")
print("CONSEJOS OK")
process.exit(0)
