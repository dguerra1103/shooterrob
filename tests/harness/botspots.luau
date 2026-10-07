-- Los puestos de vigilancia de los mapas 5 contra 5 están sobre suelo firme (no en el aire ni dentro
-- de una pared) y el tirador va a uno de su mitad
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
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local function inside(part, point, pad)
	local lp = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2 + Vector3.new(pad, pad, pad)
	return math.abs(lp.X) < h.X and math.abs(lp.Y) < h.Y and math.abs(lp.Z) < h.Z
end
for _, id in MapBuilder.Order do
	MapBuilder.Build(id)
	local map = game.Workspace.Map
	local spots, solids = {}, {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "BotSpot" then
				table.insert(spots, d)
			elseif d.CanCollide ~= false and (d.Transparency or 0) < 1 then
				table.insert(solids, d)
			end
		end
	end
	check(#spots >= 4, id .. ": puestos de vigilancia (" .. #spots .. ")")
	for _, spot in spots do
		local p = spot.Position
		local floor, blocked = false, nil
		for _, part in solids do
			if inside(part, p - Vector3.new(0, 1.2, 0), 0) then floor = true end
			if inside(part, p + Vector3.new(0, 2, 0), -0.05) then blocked = part.Name end
		end
		check(floor and not blocked, string.format("%s: puesto en (%.0f, %.0f, %.0f) con suelo y sin pared%s", id, p.X, p.Y, p.Z, blocked and (" (choca con " .. blocked .. ")") or ""))
		local look = spot:GetAttribute("Look")
		check(typeof(look) == "Vector3", "  con hacia dónde mirar")
		-- A la altura de los ojos, la vista sale libre (por la ventana o por encima del parapeto)
		local eye = p + Vector3.new(0, 4, 0)
		local flat = Vector3.new(look.X - p.X, 0, look.Z - p.Z).Unit
		local wall
		for d = 0.5, 5, 0.25 do
			for _, part in solids do
				if part.Name ~= "Lintel" and part.Name ~= "Sill" and inside(part, eye + flat * d, -0.02) then wall = part.Name .. " " .. tostring(part.Position) .. " " .. tostring(part.Size) .. " d=" .. d end
			end
		end
		check(wall == nil, "  la vista sale libre" .. (wall and (" (choca con " .. wall .. ")") or ""))
	end
end
print("PUESTOS OK")
