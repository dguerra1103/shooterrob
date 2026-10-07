-- Pantalla de arranque: fases con progreso real, consejos, lobby oculto detrás y salida en cuanto todo está
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local mock = require("./mock")
mock.taskImpl = task
local src = process.args[1]
local game, req = mock.buildGame(src)
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId = "Yo", "Yo", 1
me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
local ps = mock.new("PlayerScripts"); ps.Name = "PlayerScripts"; ps.Parent = me
game.StarterPlayer.Client.Parent = ps
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
game:GetService("ContentProvider").RequestQueueSize = 0
game:GetService("LocalizationService").RobloxLocaleId = "es-es"
local rf = game:GetService("ReplicatedFirst")
for _, name in { "BootTips", "Loading" } do
	local ms = mock.new("ModuleScript"); ms.Name = name
	ms.Source = fs.readFile(src .. "/first/" .. name .. (name == "Loading" and ".client.luau" or ".luau"))
	ms.Parent = rf
end
RS:SetAttribute("State", "Intermission")
RS:SetAttribute("LoadingMap", "Metro Yard")
local errored
task.spawn(function()
	local rs = game:GetService("RunService")
	while true do
		pcall(function() rs.RenderStepped:Fire(0.05) end)
		task.wait(0.05)
	end
end)
task.spawn(function()
	local ok, err = pcall(req, rf.Loading)
	if not ok then errored = tostring(err) end
end)
task.wait(0.3)
local function texts()
	local t = {}
	for _, d in pg:GetDescendants() do
		if d.__className == "TextLabel" and type(d.Text) == "string" then t[d.Text] = d end
	end
	return t
end
local gui = pg:FindFirstChild("Loading")
check(gui ~= nil and errored == nil, "pantalla de arranque visible " .. tostring(errored))
local t = texts()
local tip
for text in t do if string.find(text, "CONSEJO", 1, true) then tip = text end end
check(tip ~= nil, "consejo: " .. tostring(tip))
-- Sin datos aún: se queda en ARMAS
check(t["CARGANDO ARMAS"] ~= nil, "fase CARGANDO ARMAS (esperando tus datos)")
check(#mock.preloaded > 3, "precarga real de los sonidos de la interfaz (" .. #mock.preloaded .. ")")
if process.args[2] then
	require("./guidump")(pg, process.args[2] .. "/boot_1280x720.json")
end
local ClientState = req(ps.Client.Modules.ClientState)
ClientState.Data = { Level = 1 }
task.wait(0.4)
t = texts()
check(t["CONSTRUYENDO METRO YARD"] ~= nil, "dice qué mapa se está construyendo")
local percent
for text in t do if string.match(text, "^%d+%%$") then percent = tonumber(string.match(text, "^(%d+)")) end end
check(percent and percent >= 55 and percent < 100, "barra a medias mientras falta el mapa (" .. tostring(percent) .. "%)")
local map = mock.new("Model"); map.Name = "Map"; map.Parent = game.Workspace
RS:SetAttribute("LoadingMap", nil)
task.wait(0.4)
check(texts()["PREPARANDO PARTIDA"] ~= nil, "fase PREPARANDO PARTIDA (esperando el lobby)")
check(game.Lighting:FindFirstChild("FlowBlur") ~= nil, "el mapa se ve detrás, desenfocado")
-- El lobby aparece: se oculta hasta que se vaya la pantalla de arranque
local lobby = mock.new("ScreenGui"); lobby.Name = "MainMenu"; lobby.Enabled = true; lobby.Parent = pg
task.wait(0.2)
check(lobby.Enabled == false, "el lobby no se ve por detrás mientras tanto")
local t0 = os.clock()
lobby:SetAttribute("Ready", true)
while pg:FindFirstChild("Loading") and os.clock() - t0 < 3 do task.wait(0.05) end
local took = os.clock() - t0
check(pg:FindFirstChild("Loading") == nil, string.format("se va en cuanto el lobby está listo (%.2f s)", took))
check(took < 1, "sin esperas inventadas")
check(lobby.Enabled == true, "el lobby vuelve a verse")
check(errored == nil, "sin errores " .. tostring(errored))
print("ARRANQUE OK")
process.exit(0)
