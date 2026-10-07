-- Los sitios de la bomba están despejados (nada sólido en el centro ni alrededor a la altura del cuerpo)
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
local function inside(part, point)
	local lp = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2
	return math.abs(lp.X) < h.X and math.abs(lp.Y) < h.Y and math.abs(lp.Z) < h.Z
end
local total = 0
for _, id in MapBuilder.Order do
	MapBuilder.Build(id)
	local map = game.Workspace.Map
	local sites, solids = {}, {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "BombSite" then
				table.insert(sites, d)
			elseif d.CanCollide ~= false and (d.Transparency or 0) < 1 then
				table.insert(solids, d)
			end
		end
	end
	if #sites > 0 then
		local byTeam = { 0, 0 }
		for _, site in sites do
			local d = site:GetAttribute("Defender")
			byTeam[d] = (byTeam[d] or 0) + 1
		end
		check(byTeam[1] >= 1 and byTeam[2] >= 1 and #sites <= 4, id .. ": sitios para los dos equipos (" .. #sites .. ")")
		for _, site in sites do
			local blocked
			for _, offset in { Vector3.new(0, 2, 0), Vector3.new(3, 2, 0), Vector3.new(-3, 2, 0), Vector3.new(0, 2, 3), Vector3.new(0, 2, -3) } do
				for _, part in solids do
					if inside(part, site.Position + offset) then blocked = part.Name end
				end
			end
			check(not blocked, string.format("%s: sitio %s del equipo %d despejado%s", id, site:GetAttribute("Letter"), site:GetAttribute("Defender"), blocked and (" (choca con " .. blocked .. ")") or ""))
			total += 1
		end
	end
end
check(total >= 2 * #MapBuilder.Order, "sitios en todos los mapas (" .. total .. ")")
print("SITIOS OK")
