-- Consejos de contexto para jugadores nuevos (Fase 6): una línea discreta en partida cuando hacen algo
-- que un consejo arregla. Solo hasta el nivel Hints.MaxLevel, cada consejo como mucho una vez por
-- sesión y con Hints.Gap segundos entre uno y otro. No guarda nada (sin cambios en los datos) y no
-- bloquea: no quita el ratón ni para el juego.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Hints = {}

Hints.MaxLevel = 5 -- a partir de aquí ya no salen
Hints.Gap = 60 -- segundos mínimos entre dos consejos
Hints.Duration = 5 -- segundos en pantalla
Hints.HipShots = 8 -- disparos a la cadera seguidos sin acertar que sacan el consejo de apuntar
Hints.HipWindow = 4 -- (en estos segundos)
Hints.LowHealth = 0.35 -- fracción de vida que saca el consejo de cubrirse

-- Textos: { PC, táctil }
Hints.Text = {
	Aim = { "Mantén el clic derecho para apuntar: de lejos aciertas mucho más", "Toca 🎯 para apuntar: de lejos aciertas mucho más" },
	Reload = { "Pulsa R para recargar antes de vaciar el cargador", "Toca 🔄 para recargar antes de vaciar el cargador" },
	Cover = { "Ponte a cubierto: si no te dan, la vida se recupera sola", "Ponte a cubierto: si no te dan, la vida se recupera sola" },
}

local seen = {}
local lastAt = -math.huge
local label = nil
local hipShots = {}

local function touchOnly()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ¿Se puede enseñar un consejo ahora? (jugador nuevo, en partida, vivo y sin nada encima)
function Hints.Eligible()
	local data = ClientState.Data
	if not data or (tonumber(data.Level) or 1) > Hints.MaxLevel then
		return false
	end
	if ClientState.IsBlocked() or ClientState.ResultsActive or ClientState.KillcamActive then
		return false
	end
	return true
end

local function ensureLabel()
	if label and label.Parent then
		return label
	end
	local gui = UI.new("ScreenGui", {
		Name = "Hints",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local phone = touchOnly()
	-- (escritorio: encima del aviso corto del HUD; teléfono: centrado, por debajo de la mira)
	label = UI.label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = phone and UDim2.new(0.5, 0, 0.5, 64) or UDim2.new(0.5, 0, 1, -162),
		Size = phone and UDim2.fromOffset(320, 24) or UDim2.fromOffset(560, 30),
		BackgroundColor3 = Color3.fromRGB(14, 15, 18),
		BackgroundTransparency = 0.35,
		Text = "",
		TextSize = phone and 14 or 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextWrapped = true,
		Visible = false,
		Parent = gui,
	}, { UI.corner(6) })
	return label
end

-- Enseña el consejo `id` si toca (devuelve true si salió)
function Hints.Show(id)
	local texts = Hints.Text[id]
	if not texts or seen[id] or not Hints.Eligible() then
		return false
	end
	local now = os.clock()
	if now - lastAt < Hints.Gap then
		return false
	end
	seen[id] = true
	lastAt = now
	local hint = ensureLabel()
	hint.Text = "💡 " .. (touchOnly() and texts[2] or texts[1])
	hint.Visible = true
	local token = {}
	hint:SetAttribute("Token", tostring(token))
	task.delay(Hints.Duration, function()
		if hint:GetAttribute("Token") == tostring(token) then
			hint.Visible = false
		end
	end)
	return true
end

-- Disparo propio: muchos a la cadera seguidos sin acertar → apuntar
function Hints.OnShot()
	local def = ClientState.CurrentDef
	if not def or def.Type ~= "Gun" or def.Scope or (def.Pellets or 1) > 1 or (ClientState.AimAlpha or 0) > 0.3 then
		hipShots = {}
		return
	end
	local now = os.clock()
	table.insert(hipShots, now)
	while hipShots[1] and now - hipShots[1] > Hints.HipWindow do
		table.remove(hipShots, 1)
	end
	if #hipShots >= Hints.HipShots and now - (ClientState.LastHitTime or 0) > Hints.HipWindow then
		hipShots = {}
		Hints.Show("Aim")
	end
end

-- Recarga con el cargador vacío → recargar antes
function Hints.OnWeaponEvent(name, _weapon, info)
	if name == "ReloadStart" and type(info) == "table" and info.Empty then
		Hints.Show("Reload")
	end
end

-- Poca vida → cubrirse (solo si la vida se recupera de verdad)
function Hints.CheckHealth(humanoid)
	if not humanoid or humanoid.Health <= 0 or humanoid.MaxHealth <= 0 then
		return
	end
	local regen = GameConfig.HealthRegen
	if regen and regen.Enabled and humanoid.Health / humanoid.MaxHealth < Hints.LowHealth then
		Hints.Show("Cover")
	end
end

-- (pruebas: empezar de cero)
function Hints.Reset()
	seen = {}
	lastAt = -math.huge
	hipShots = {}
end

function Hints.Init()
	ClientState.ShotFired.Event:Connect(Hints.OnShot)
	ClientState.WeaponEvent.Event:Connect(Hints.OnWeaponEvent)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		-- (cuando ya no puede salir ninguno, no mira nada)
		if seen.Cover then
			return
		end
		local character = player.Character
		Hints.CheckHealth(character and character:FindFirstChildOfClass("Humanoid"))
	end)
end

return Hints
