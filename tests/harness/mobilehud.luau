-- shared/MobileHUD (Fase 12), lógica pura: tipos de pantalla, controles sin duplicar, valores por
-- defecto válidos, validación de lo guardado (rangos, basura, parejas X/Y) y disposición dentro de
-- la pantalla y fuera del centro en las resoluciones de la matriz (FASE_12_MOVIL.md).
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Vector2 = roblox.Vector2
local MobileHUD = req(game.ReplicatedStorage.Shared.MobileHUD)
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
local TouchIcons = req(game.StarterPlayer.Client.Modules.TouchIcons)

-- Tipos de pantalla (pocos)
check(MobileHUD.Breakpoint(Vector2.new(1920, 1080), false) == "DESKTOP", "sin pantalla táctil: DESKTOP")
check(MobileHUD.Breakpoint(Vector2.new(568, 320), true) == "PHONE_SMALL", "568x320: PHONE_SMALL")
check(MobileHUD.Breakpoint(Vector2.new(844, 390), true) == "PHONE", "844x390: PHONE")
check(MobileHUD.Breakpoint(Vector2.new(932, 430), true) == "PHONE", "932x430: PHONE")
check(MobileHUD.Breakpoint(Vector2.new(1024, 768), true) == "TABLET", "1024x768: TABLET")
check(MobileHUD.Breakpoint(Vector2.new(390, 844), true) == "PHONE", "en vertical, el mismo tipo")

-- Controles: ids únicos, papeles y tamaños coherentes
local seen = {}
for _, c in MobileHUD.Controls do
	check(not seen[c.Id], c.Id .. " no está repetido")
	seen[c.Id] = true
	check(MobileHUD.RoleOpacity[c.Role] ~= nil, c.Id .. " tiene un papel conocido")
	check(c.Anchor == "Jump" or c.Anchor == "BottomLeft" or c.Anchor == "TopRight", c.Id .. " con ancla conocida")
	check(c.Icon == "Card" or TouchIcons.Kinds[c.Icon] ~= nil, c.Id .. " con icono dibujado (" .. c.Icon .. ")")
end
local fire = MobileHUD.ById.Fire
for _, c in MobileHUD.Controls do
	if c.Id ~= "Fire" and type(c.Size) == "number" then
		check(c.Size < fire.Size, c.Id .. " más pequeño que disparar")
		check(c.Size * MobileHUD.Unit("PHONE_SMALL") >= 30, c.Id .. " se puede tocar con el dedo hasta en PHONE_SMALL")
	end
end

-- Ajustes por defecto y límites
check(type(GameConfig.DefaultSettings.HudLayout) == "table" and next(GameConfig.DefaultSettings.HudLayout) == nil, "disposición por defecto vacía (la de fábrica)")
check(GameConfig.DefaultSettings.AutoSprint == 1 and GameConfig.DefaultSettings.LeftFire == 0 and GameConfig.DefaultSettings.FireDrag == 1, "correr solo, sin disparo izquierdo y disparar arrastrando por defecto")
check(GameConfig.MobileHUDDebug == false, "depuración del HUD apagada por defecto")

-- Validación de lo guardado
local clean = MobileHUD.Validate({
	Fire = { X = 0.5, Y = 0.5, S = 3, O = -1 },
	Aim = { X = 0.2 },
	Melee = { S = 0 / 0 },
	Reload = { S = math.huge },
	Unknown = { X = 0.1, Y = 0.1 },
	[1] = { X = 1 },
	Grenade = "x",
})
check(clean.Fire.S == MobileHUD.Limits.S[2] and clean.Fire.O == MobileHUD.Limits.O[1], "tamaño y opacidad recortados")
check(clean.Aim == nil, "posición a medias descartada")
check(clean.Melee == nil and clean.Reload == nil, "NaN e infinito descartados")
check(clean.Unknown == nil and clean[1] == nil and clean.Grenade == nil, "controles desconocidos y basura fuera")
check(next(MobileHUD.Validate(nil)) == nil and next(MobileHUD.Validate("hola")) == nil, "sin tabla: vacía")
local again = MobileHUD.Validate(clean)
check(again.Fire.S == clean.Fire.S and again.Fire.X == clean.Fire.X, "validar dos veces da lo mismo")

-- Disposición por defecto en la matriz de resoluciones
for _, dims in { { 568, 320 }, { 667, 375 }, { 844, 390 }, { 932, 430 }, { 1080, 480 }, { 1024, 768 }, { 1180, 820 } } do
	local size = Vector2.new(dims[1], dims[2])
	local layout = MobileHUD.Resolve(size, {})
	local count = 0
	for id, info in layout do
		count += 1
		check(info.Opacity > 0 and info.Opacity <= 1, dims[1] .. "x" .. dims[2] .. " " .. id .. " opacidad válida")
	end
	check(count == #MobileHUD.Controls, dims[1] .. "x" .. dims[2] .. ": todos los controles colocados")
	check(layout.Fire.Center.X > size.X / 2 and layout.AbilityDash.Center.X < size.X / 2, dims[1] .. "x" .. dims[2] .. ": combate a la derecha, habilidades a la izquierda (joystick)")
end
-- Disposición propia: fracciones de la pantalla (vale al girar o cambiar de móvil)
local a = MobileHUD.Resolve(Vector2.new(844, 390), { Custom = { Fire = { X = 0.25, Y = 0.5 } } })
local b = MobileHUD.Resolve(Vector2.new(1024, 768), { Custom = { Fire = { X = 0.25, Y = 0.5 } } })
check(math.abs(a.Fire.Center.X - 211) < 1 and math.abs(b.Fire.Center.X - 256) < 1, "la posición propia es relativa a la pantalla")
print("MOBILEHUD OK")
process.exit(0)
