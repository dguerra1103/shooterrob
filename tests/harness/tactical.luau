-- Estilo Táctico: en todos los mapas (y sus variantes de luz) se cumplen los límites de legibilidad:
-- nada muy oscuro, niebla contenida, brillo moderado y algo de color
local process = require("@lune/process")
local task = require("@lune/task")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Modules = game.ServerScriptService.Server.Modules
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
check(GameConfig.VisualStyle == "Tactico", "el estilo del juego es Táctico")
local Kit = req(Modules.MapKit)
local function top(c) return math.max(c.R, c.G, c.B) * 255 end
local count, problems = 0, {}
for _, module in Modules.MapDefs:GetChildren() do
	local ok, map = pcall(req, module)
	if ok and type(map) == "table" and map.Lighting then
		local presets = { { "base", map.Lighting } }
		for _, v in map.LightingVariants or {} do
			local p = table.clone(map.Lighting)
			for k, val in v do if k ~= "Name" and k ~= "Chance" and k ~= "Weather" then p[k] = val end end
			table.insert(presets, { v.Name or "?", p })
		end
		for _, entry in presets do
			local designed = map.Realistic == true
			local p = Kit.tacticalize(entry[2], designed)
			count += 1
			local clock = p.ClockTime or 14
			local night = clock < 6.2 or clock > 17.8
			local name = (map.Id or module.Name) .. "/" .. entry[1]
			local function bad(why) table.insert(problems, name .. ": " .. why) end
			if top(p.Ambient) < (night and 54 or 65) then bad("ambiente oscuro " .. top(p.Ambient)) end
			if top(p.OutdoorAmbient) < (night and 84 or 110) then bad("exterior oscuro " .. top(p.OutdoorAmbient)) end
			if p.Bloom.Intensity > 0.76 then bad("brillo " .. p.Bloom.Intensity) end
			if (p.Atmosphere.Density or 0) > 0.381 then bad("niebla " .. p.Atmosphere.Density) end
			if (p.Atmosphere.Haze or 0) > 1.41 then bad("bruma " .. p.Atmosphere.Haze) end
			if (p.Color.Saturation or 0) < 0.079 then bad("sin color " .. p.Color.Saturation) end
		end
	end
end
for _, line in problems do print("  " .. line) end
check(count >= 20, "revisados " .. count .. " ajustes de luz")
check(#problems == 0, "todos legibles")
print("ESTILO TACTICO OK")
process.exit(0)
