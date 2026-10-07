-- Comprueba que los puntos FFASpawn (y SpawnLocations) no quedan dentro de piezas sólidas
local process = require("@lune/process")
local mock = require("./mock")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local game, req = mock.buildGame(process.args[1])
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local MapBuilder = req(game.ServerScriptService.Server.Modules.MapBuilder)
local function inside(part, point)
	local lp = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2
	if part.Shape and tostring(part.Shape):find("Ball") then
		return lp.Magnitude < h.X
	end
	return math.abs(lp.X) < h.X and math.abs(lp.Y) < h.Y and math.abs(lp.Z) < h.Z
end
local total = 0
for _, id in MapBuilder.Order do
	MapBuilder.Build(id)
	local map = game.Workspace.Map
	local solids, points = {}, {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "FFASpawn" or d.__className == "SpawnLocation" then
				table.insert(points, d)
			elseif d.CanCollide ~= false and d.Transparency < 1 then
				table.insert(solids, d)
			end
		end
	end
	local bad = 0
	for _, p in points do
		-- cuerpo del personaje: de 1 a 5 studs sobre el punto
		for _, dy in { 1.5, 3, 4.5 } do
			local probe = p.Position + Vector3.new(0, dy, 0)
			for _, s in solids do
				if inside(s, probe) then
					bad += 1
					print(string.format("  %s: %s en (%.1f, %.1f, %.1f) choca con %s", id, p.Name, p.Position.X, p.Position.Y, p.Position.Z, s.Name))
					break
				end
			end
		end
	end
	total += bad
	print(id, #points, "puntos,", bad, "choques")
end
print(total == 0 and "TODO OK" or "HAY CHOQUES")
