local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local M = game.ServerScriptService.Server.Modules
-- Teams
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
req(game.ReplicatedStorage.Shared.Remotes)
local MapBuilder = req(M.MapBuilder)
local Flags = req(M.Flags)
local Hardpoint = req(M.Hardpoint)
local Round = req(M.Round)
local PlayerData = req(M.PlayerData)
local Loadout = req(M.Loadout)
local Combat = req(M.Combat)
for _, id in MapBuilder.Order do
	mock.terrainFills = {}
	MapBuilder.Build(id)
	local map = game.Workspace.Map
	local counts = { FFASpawn = 0, HardpointZone = 0, FlagBase = 0, SpawnLocation = 0, Parts = 0 }
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then counts.Parts += 1 end
		if counts[d.Name] then counts[d.Name] += 1 end
		if d.__className == "SpawnLocation" then counts.SpawnLocation += 1 end
	end
	print(id, "partes", counts.Parts, "spawns", counts.SpawnLocation, "ffa", counts.FFASpawn, "zonas", counts.HardpointZone, "banderas", counts.FlagBase, "flags ok", Flags.IsAvailable(), "zona ok", Hardpoint.IsAvailable())
	Flags.Start(); Flags.Stop()
	Hardpoint.Start(); Hardpoint.Stop()
end
print("Round/PlayerData/Loadout/Combat cargados", Round ~= nil, PlayerData ~= nil, Loadout ~= nil, Combat ~= nil)
