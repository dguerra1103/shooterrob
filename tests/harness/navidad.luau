-- Eventos por fecha: Halloween en octubre, Navidad en diciembre (regalos, muñecos de nieve, traje y skin)
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
game.JobId = "A"
local roblox = require("@lune/roblox")
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
local Skins = req(Shared.Skins)
local Outfits = req(Shared.Outfits)
local OCT, NOV, DEC, JAN = 1791590400, 1794700800, 1796860800, 1799625600 -- 10 oct, 15 nov, 10 dic 2026, 11 ene 2027
check(GameConfig.PickEvent(OCT).Name == "Halloween" and GameConfig.EventActive(GameConfig.PickEvent(OCT), OCT), "en octubre: Halloween")
local nov = GameConfig.PickEvent(NOV)
check(nov.Name == "Navidad" and not GameConfig.EventActive(nov, NOV), "en noviembre: sin evento (el siguiente es Navidad)")
check(GameConfig.PickEvent(DEC).Name == "Navidad" and GameConfig.EventActive(GameConfig.PickEvent(DEC), DEC), "en diciembre: Navidad")
check(not GameConfig.EventActive(GameConfig.PickEvent(JAN), JAN), "en enero ya no hay evento")
for _, event in GameConfig.Events do
	check(Skins.List[event.RewardSkin] and Skins.List[event.RewardSkin].Event, "skin del evento " .. event.Name)
	for _, m in event.Milestones do
		check(not m.Outfit or (Outfits.List[m.Outfit] and Outfits.List[m.Outfit].Event), "traje del evento " .. tostring(m.Outfit))
	end
	check(event.Icon and event.Item and event.Items and event.ItemIcon and event.ItemColors and event.Decoration, "textos y aspecto de " .. event.Name)
end
-- Navidad en marcha (se fuerza el evento y que esté dentro de fechas)
local navidad = GameConfig.Events[2]
GameConfig.Events[1].EndsAt = os.time() - 60 -- (Halloween ya acabó)
navidad.StartsAt = os.time() + 3600 -- (aún no ha empezado: se encenderá con el servidor en marcha)
navidad.EndsAt = os.time() + 3600
navidad.SpawnEvery = 0.2
navidad.Goal = 3
navidad.Milestones = { { Count = 2, Outfit = "PapaNoel", Compensate = 400 } }
GameConfig.Event = navidad
local M = game.ServerScriptService.Server.Modules
local PlayerData = req(M.PlayerData)
PlayerData.Init()
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local MapBuilder = req(M.MapBuilder)
local Event = req(M.Event)
local ground = mock.new("Part"); ground.CanCollide = true
mock.raycastImpl = function(origin, direction)
	local target = origin + direction
	if origin.Y >= 0 and target.Y <= 0 then
		return { Position = roblox.Vector3.new(origin.X, 0, origin.Z), Instance = ground, Normal = roblox.Vector3.new(0, 1, 0) }
	end
	return nil
end
MapBuilder.Build("Construction")
local snowmen, pumpkins = 0, 0
for _, d in game.Workspace.Map:GetDescendants() do
	if d.Name == "SnowmanHead" then snowmen += 1 end
	if d.Name == "Pumpkin" then pumpkins += 1 end
end
check(pumpkins == 0, "sin calabazas")
Event.Init()
local RS = game.ReplicatedStorage
check(RS:GetAttribute("EventId") == nil, "antes de su fecha no hay evento")
check(GameConfig.ActiveNews() == GameConfig.News, "fuera de Navidad, las novedades de siempre")
navidad.StartsAt = os.time() - 10
task.wait(0.5)
check(RS:GetAttribute("EventName") == "Navidad" and RS:GetAttribute("EventId") == "Navidad2026", "llega la fecha con el servidor en marcha: empieza la Navidad")
check(GameConfig.CurrentEvent() == navidad, "el cliente sigue al servidor (EventId)")
check(string.find(GameConfig.ActiveNews().Title, "NAVIDAD") ~= nil and GameConfig.ActiveNews().Version > GameConfig.News.Version, "en Navidad salen sus novedades (versión nueva)")
MapBuilder.Build("Construction")
for _, d in game.Workspace.Map:GetDescendants() do
	if d.Name == "SnowmanHead" then snowmen += 1 end
end
check(snowmen >= 3, "muñecos de nieve en el mapa (" .. snowmen .. ")")
RS:SetAttribute("State", "Playing")
task.wait(1.2)
local folder = game.Workspace.EventCandies
local first = folder:GetChildren()[1]
check(first ~= nil and first.Shape == roblox.Enum.PartType.Block, "aparecen regalos (cajas)")
local p = mock.new("Player"); p.Name = "P"; p.UserId = 19; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
local data = PlayerData.WaitFor(p, 3)
local char = mock.new("Model"); char.Name = "P"
local root = mock.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
char.Parent = game.Workspace
p.Character = char
for _ = 1, 3 do
	local gift = folder:GetChildren()[1]
	root.Position = gift.Position
	Event.Collect(p, gift)
	task.wait(0.3)
end
check(data.EventProgress.Id == "Navidad2026" and data.EventProgress.Count == 3, "3 regalos contados en el evento de Navidad")
check(data.Outfits.PapaNoel == true, "a los 2: traje de Papá Noel")
check(data.Skins.Navidena == true, "a los 3: skin Navideña")
local notes = {}
for _, m in mock.sent do
	if m.Remote == "Notify" then table.insert(notes, tostring(m.Args[2])) end
end
local text = table.concat(notes, " | ")
check(string.find(text, "🎁") and string.find(text, "🎄") and not string.find(text, "caramelo"), "avisos con regalos y 🎄 (" .. string.sub(text, 1, 120) .. ")")
print("NAVIDAD OK")
process.exit(0)
