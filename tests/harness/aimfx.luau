-- Apuntar: bordes oscuros al apuntar. Desenfoque (DOF): por defecto nunca en partida (Fase 3); con
-- GameConfig.AimDepthOfField = true, el de antes (enfocado a lo que se mira)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.CFrame = roblox.CFrame.new(0, 5, 0)
local wall = mock.new("Part"); wall.Transparency = 0; wall.Parent = game.Workspace
local glass = mock.new("Part"); glass.Transparency = 0.6; glass.Parent = game.Workspace
local glassAt = nil -- (a qué distancia hay un cristal delante, si lo hay)
mock.raycastImpl = function(origin, direction, params)
	local ignored = false
	for _, item in (params and params.FilterDescendantsInstances or {}) do
		if item == glass then ignored = true end
	end
	if glassAt and not ignored then
		return { Instance = glass, Position = origin + direction.Unit * glassAt, Normal = roblox.Vector3.new(0, 0, 1), Distance = glassAt, Material = roblox.Enum.Material.Glass }
	end
	return { Instance = wall, Position = origin + direction.Unit * 40, Normal = roblox.Vector3.new(0, 0, 1), Distance = 40, Material = roblox.Enum.Material.Concrete }
end
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
ClientState.EffectiveQuality = "Alta"
local AimFX = req(game.StarterPlayer.Client.Modules.AimFX)
AimFX.Init()
local gui = pg:FindFirstChild("AimVignette")
check(gui ~= nil, "viñeta creada")
ClientState.AimAlpha = 0
AimFX.Update(1 / 60)
local dof = game.Workspace.CurrentCamera:FindFirstChild("AimDepthOfField")
check(dof ~= nil and dof.Enabled == false, "sin apuntar, sin desenfoque")
-- Por defecto (Fase 3): apuntando tampoco hay desenfoque; los bordes sí se oscurecen
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
check(GameConfig.AimDepthOfField == false, "desenfoque al apuntar apagado por defecto")
ClientState.AimAlpha = 1
for _ = 1, 30 do AimFX.Update(1 / 30) end
check(dof.Enabled == false, "apuntando en partida: nada borroso")
check(gui:FindFirstChild("Edge1").BackgroundTransparency < 0.8, "apuntando: bordes oscuros (sin desenfoque)")
-- Con la opción encendida, el comportamiento de antes
GameConfig.AimDepthOfField = true
ClientState.AimAlpha = 1
for _ = 1, 60 do AimFX.Update(1 / 30) end
check(dof.Enabled and dof.FarIntensity > 0.1 and math.abs(dof.FocusDistance - 40) < 3, "apuntando: fondo desenfocado y enfocado a lo que miras (" .. dof.FocusDistance .. ")")
check(dof.FarIntensity <= 0.2 + 1e-6, "desenfoque por debajo del salto brusco de Roblox (0,22)")
check(dof.InFocusRadius <= 50 and dof.FocusDistance <= 200, "valores dentro de lo que admite Roblox")
-- Un cristal delante (ventana): se enfoca a lo de detrás
glassAt = 8
for _ = 1, 60 do AimFX.Update(1 / 30) end
check(math.abs(dof.FocusDistance - 40) < 3, "a través de un cristal, enfoca lo de detrás (" .. dof.FocusDistance .. ")")
glassAt = nil
-- El desenfoque lejano de calidad Ultra: en partida nunca (ni apuntando ni sin apuntar); en los menús sí
local Lighting = game:GetService("Lighting")
local quality = mock.new("DepthOfFieldEffect"); quality.Name = "QualityDOF"; quality.Enabled = true; quality.Parent = Lighting
ClientState.EffectiveQuality = "Ultra"
AimFX.Update(1 / 30)
check(quality.Enabled == false, "en partida, apuntando: el desenfoque de Ultra apagado")
ClientState.AimAlpha = 0
AimFX.Update(1 / 30)
check(quality.Enabled == false, "en partida, sin apuntar: también apagado")
ClientState.InMainMenu = true
AimFX.Update(1 / 30)
check(quality.Enabled == true, "en los menús, con Ultra: encendido")
ClientState.EffectiveQuality = "Alta"
AimFX.Update(1 / 30)
check(quality.Enabled == false, "en los menús sin Ultra: apagado")
ClientState.InMainMenu = false
ClientState.AimAlpha = 1
ClientState.EffectiveQuality = "Alta"
AimFX.Update(1 / 30)
local edge = gui:FindFirstChild("Edge1")
check(edge.BackgroundTransparency < 0.8, "y los bordes se oscurecen")
ClientState.CurrentDef = { Scope = true }
AimFX.Update(1 / 30)
check(dof.Enabled == false, "con visor de francotirador, nada (lo tapa el visor)")
ClientState.CurrentDef = nil
ClientState.Settings = { ScreenFX = 0 }
AimFX.Update(1 / 30)
check(dof.Enabled == false, "con efectos de pantalla reducidos, sin desenfoque")
ClientState.Settings = nil
ClientState.EffectiveQuality = "Baja"
AimFX.Update(1 / 30)
check(dof.Enabled == false, "en calidad Baja, sin desenfoque")
print("APUNTADO OK")
process.exit(0)
