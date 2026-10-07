-- Versiones de luz de los mapas realistas
local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local MapBuilder = req(game.ServerScriptService.Server.Modules.MapBuilder)
local L = game:GetService("Lighting")
for _, spec in { { "Construction", "Mediodía", 13.2 }, { "Construction", "Noche", 21.2 } } do
	local seen, base = {}, nil
	for _ = 1, 30 do
		MapBuilder.Build(spec[1])
		local v = game.Workspace:FindFirstChild("Map"):GetAttribute("Variant")
		seen[v or "base"] = L.ClockTime
	end
	check(seen[spec[2]] == spec[3], spec[1] .. ": a veces sale " .. spec[2] .. " (hora " .. tostring(seen[spec[2]]) .. ")")
	check(seen.base ~= nil and seen.base ~= spec[3], spec[1] .. ": y casi siempre la luz normal")
end
print("VARIANTES OK")
process.exit(0)
