-- Sensaciones de combate: aturdimiento por explosión cercana, supresión por balas que rozan, latido
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
local camera = game.Workspace.CurrentCamera
camera.CFrame = CFrame.new(0, 5, 0)
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char
char.Parent = game.Workspace
me.Character = char
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
ClientState.EffectiveQuality = "Alta"
local Sounds = req(game.ReplicatedStorage.Shared.Sounds)
local Effects = req(game.StarterPlayer.Client.Modules.Effects)
local CombatFX = req(game.StarterPlayer.Client.Modules.CombatFX)
CombatFX.Init()
Effects.OnConcussion = CombatFX.Concussion

local function muffles()
	local list = {}
	for _, g in SoundService:GetChildren() do
		if g:IsA("SoundGroup") then
			local eq = g:FindFirstChild("ConcussionMuffle")
			check(eq ~= nil, "filtro en el grupo " .. g.Name)
			table.insert(list, eq)
		end
	end
	return list
end

-- Explosión lejos: nada
Effects.Explosion(Vector3.new(0, 5, 200), 14)
local blur = camera:FindFirstChild("CombatBlur")
check(blur == nil or blur.Size == 0, "explosión lejana: sin aturdimiento")

-- Explosión a 6 studs: aturde
Effects.Explosion(Vector3.new(0, 5, 6), 14)
blur = camera:FindFirstChild("CombatBlur")
check(blur ~= nil and blur.Size > 10, "explosión cercana: desenfoque fuerte (" .. tostring(blur and blur.Size) .. ")")
check(camera:FindFirstChild("CombatFlash") ~= nil, "y destello blanco")
local list = muffles()
check(#list >= 2, "filtro en todos los grupos de sonido (" .. #list .. ")")
for _, eq in list do
	check(eq.HighGain < -20 and eq.Enabled ~= false, "agudos apagados (" .. eq.HighGain .. ")")
end
local ring = camera:FindFirstChild("Tinnitus")
check(ring ~= nil and ring.SoundGroup ~= Sounds.GetWorldGroup(), "pitido en los oídos (fuera del filtro)")
check((ClientState.ConcussedUntil or 0) > os.clock(), "estado de aturdido")
-- Los sonidos normales van al grupo Mundo (para que el filtro los apague)
local click = Sounds.Play("Click")
check(click.SoundGroup ~= nil and click.SoundGroup.Name == "Mundo", "los sonidos van al grupo Mundo")
local shot = Sounds.PlayGun("Shot")
check(shot.SoundGroup ~= nil and shot.SoundGroup.Name == "Armas", "los disparos, al grupo Armas")

-- Se va poco a poco
local before = list[1].HighGain
task.wait(0.5)
CombatFX.Update(0.5)
check(list[1].HighGain > before + 1, "el oído se destapona poco a poco (" .. before .. " → " .. list[1].HighGain .. ")")
check(blur.Size < 16, "el desenfoque baja")
for _ = 1, 10 do CombatFX.Update(0.3) end
check(blur.Size == 0, "y se va del todo")
task.wait(3.2)
CombatFX.Update(1 / 60)
check(list[1].HighGain == 0 and list[1].Enabled == false, "al rato, el sonido vuelve a la normalidad")

-- Supresión
CombatFX.Suppress(0.8)
check(blur.Size >= 3.9, "bala rozando: un instante de desenfoque")
check(ClientState.SuppressedAt ~= nil, "estado de suprimido")

-- Calidad Baja: sin desenfoque, pero el sonido sí
for _ = 1, 10 do CombatFX.Update(0.3) end
ClientState.EffectiveQuality = "Baja"
CombatFX.Concussion(1)
check(blur.Size == 0, "en calidad Baja no hay desenfoque")
check(list[1].HighGain < -20, "pero el oído sí se tapona")

-- Ajustes → efectos de pantalla reducidos: sin desenfoque ni destello (el oído sí)
for _ = 1, 10 do CombatFX.Update(0.3) end
ClientState.EffectiveQuality = "Alta"
ClientState.Settings = { ScreenFX = 0 }
CombatFX.Concussion(1)
check(blur.Size == 0, "con efectos reducidos, sin desenfoque (accesibilidad)")
check(list[1].HighGain < -20, "pero el oído sí se tapona")
ClientState.Settings = nil
-- Muerto o en el menú: el desenfoque se quita al momento
ClientState.EffectiveQuality = "Alta"
CombatFX.Concussion(1)
check(blur.Size > 10, "otra explosión")
ClientState.Dead = true
CombatFX.Update(1 / 60)
check(blur.Size == 0, "al morir, sin desenfoque (se ve bien la killcam)")
CombatFX.Concussion(1)
CombatFX.Suppress(1)
check(blur.Size == 0, "muerto, ni aturdimiento ni supresión (la cámara es la de la killcam)")
ClientState.Dead = false

-- Latido con poca vida
local function beats()
	local n = 0
	for _, child in camera:GetChildren() do
		if child:IsA("Sound") and child.SoundId == Sounds.Boom.Id then n += 1 end
	end
	return n
end
local base = beats()
CombatFX.Update(1 / 60)
check(beats() == base, "con la vida llena, sin latido")
hum.Health = 20
CombatFX.Update(1 / 60)
check(beats() == base + 1, "con poca vida: latido")
CombatFX.Update(1 / 60)
check(beats() == base + 1, "sin repetirse en cada fotograma")
task.wait(0.25)
check(beats() >= base + 2, "doble golpe (pum-pum)")
ClientState.InMainMenu = true
hum.Health = 10
task.wait(1.2)
local n = beats()
CombatFX.Update(1 / 60)
check(beats() == n, "en el menú, sin latido")
CombatFX.Concussion(1)
check(blur.Size == 0, "en el menú no aturde")
print("COMBATE OK")
process.exit(0)
