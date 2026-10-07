-- Sonido ambiente de los mapas realistas
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local RS = game.ReplicatedStorage
local SS = game:GetService("SoundService")
local map = mock.new("Folder"); map.Name = "Map"; map:SetAttribute("Ambience", "War"); map.Parent = game.Workspace
RS:SetAttribute("State", "Playing")
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
local Ambience = req(game.StarterPlayer.Client.Modules.Ambience)
Ambience.Update()
local wind = SS:FindFirstChild("AmbienceWind")
check(wind ~= nil and wind.Looped and wind.Volume > 0, "viento en bucle durante la partida")
check(SS:FindFirstChild("Ambiente") ~= nil and wind.SoundGroup == SS:FindFirstChild("Ambiente"), "va por el grupo con filtro (suena lejos)")
for _ = 1, 3 do Ambience.Update() end
ClientState.InMainMenu = true
Ambience.Update()
check(wind.Volume == 0, "en la pantalla de inicio no suena")
ClientState.InMainMenu = false
map:SetAttribute("Ambience", nil)
Ambience.Update()
check(wind.Volume == 0, "en los mapas sin ambiente no suena")
map:SetAttribute("Ambience", "Wind")
Ambience.Update()
check(wind.Volume > 0.15, "en Cumbre el viento es fuerte (" .. wind.Volume .. ", con ráfagas: entre 0.2 y 0.44)")
-- Tormenta: lluvia que sigue a la cámara y se quita al acabar
map:SetAttribute("Ambience", "Base")
map:SetAttribute("Weather", "Rain")
Ambience.Update()
local cam = game.Workspace.CurrentCamera
local box = cam:FindFirstChild("RainBox")
check(box ~= nil and box:FindFirstChild("Drops") ~= nil, "con tormenta llueve alrededor de la cámara")
check(SS:FindFirstChild("AmbienceRain") ~= nil, "y suena la lluvia")
map:SetAttribute("Weather", nil)
Ambience.Update()
check(cam:FindFirstChild("RainBox") == nil and SS:FindFirstChild("AmbienceRain") == nil, "sin tormenta, nada de lluvia")
-- Eco: dentro de un edificio (techo y paredes) suena a habitación; fuera, según el mapa
local Ambience2 = req(game.StarterPlayer.Client.Modules.Ambience)
local SS = game:GetService("SoundService")
local savedRay = mock.raycastImpl
mock.raycastImpl = function(origin, direction)
	return { Instance = game.Workspace:FindFirstChild("Map") or game.Workspace, Position = roblox.Vector3.new(0, 8, 0), Normal = roblox.Vector3.new(0, -1, 0), Distance = 8, Material = roblox.Enum.Material.Concrete }
end
pcall(Ambience2.Update)
local indoor = SS.AmbientReverb
mock.raycastImpl = function() return nil end
pcall(Ambience2.Update)
local outdoor = SS.AmbientReverb
mock.raycastImpl = savedRay
check(indoor ~= outdoor, "dentro y fuera suenan distinto (" .. tostring(indoor) .. " / " .. tostring(outdoor) .. ")")
-- Los demás mapas también tienen ambiente (viento helado, nave industrial...)
mock.raycastImpl = function() return nil end
map:SetAttribute("Ambience", "Snow")
pcall(Ambience2.Update)
local snowWind = SS:FindFirstChild("AmbienceWind")
check(snowWind ~= nil and snowWind.Volume > 0.1, "en la nieve, viento helado")
check(SS.AmbientReverb == roblox.Enum.ReverbType.Mountains, "con eco de montaña")
map:SetAttribute("Ambience", "Factory")
pcall(Ambience2.Update)
check(SS.AmbientReverb == roblox.Enum.ReverbType.Hangar, "en la fundición, eco de nave")
map:SetAttribute("Ambience", "Coast")
-- Suelo mojado: el suelo al aire libre se oscurece y brilla; bajo techo, no
local floor = mock.new("Part"); floor.Name = "Suelo"; floor.Material = roblox.Enum.Material.Concrete
floor.Size = roblox.Vector3.new(40, 1, 40); floor.CFrame = roblox.CFrame.new(0, 0, 0); floor.Color = roblox.Color3.fromRGB(150, 150, 150); floor.Reflectance = 0; floor.Parent = map
local inside = mock.new("Part"); inside.Name = "SueloDentro"; inside.Material = roblox.Enum.Material.Concrete
inside.Size = roblox.Vector3.new(10, 1, 10); inside.CFrame = roblox.CFrame.new(100, 0, 0); inside.Color = roblox.Color3.fromRGB(150, 150, 150); inside.Reflectance = 0; inside.Parent = map
local roofPart = mock.new("Part"); roofPart.Name = "Tejado"; roofPart.Parent = map
mock.raycastImpl = function(origin)
	if origin.X > 50 then
		return { Instance = roofPart, Position = origin + roblox.Vector3.new(0, 10, 0), Normal = roblox.Vector3.new(0, -1, 0), Distance = 10, Material = roblox.Enum.Material.Concrete }
	end
	return nil
end
map:SetAttribute("Weather", "Rain")
pcall(Ambience2.Update)
check(cam:FindFirstChild("RainBox") ~= nil, "y la lluvia funciona en cualquier mapa con ambiente")
task.wait(0.1)
check(floor.Reflectance >= 0.07 and floor.Color.R < 0.55, "con lluvia, el suelo al aire libre está mojado (oscuro y con brillo)")
check(inside.Reflectance == 0 and math.abs(inside.Color.R - 150 / 255) < 1e-3, "bajo techo, seco")
map:SetAttribute("Weather", nil)
pcall(Ambience2.Update)
check(floor.Reflectance == 0 and math.abs(floor.Color.R - 150 / 255) < 1e-3, "al parar de llover, se seca")
mock.raycastImpl = function() return nil end
mock.raycastImpl = savedRay
print("AMBIENTE OK")
process.exit(0)
