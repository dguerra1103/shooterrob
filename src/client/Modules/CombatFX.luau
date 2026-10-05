-- Sensaciones de combate (realismo), solo en este cliente:
--   Concussion: una explosión cerca te aturde: destello blanco, desenfoque, pitido en los oídos y todo
--               lo demás suena apagado unos segundos (más cuanto más cerca)
--   Suppress:   balas que pasan rozando: un instante de desenfoque y la imagen se oscurece (supresión)
--   Latido:     con poca vida, un latido grave que se acelera cuanto menos vida queda
-- En calidad Baja, sin desenfoques (cuestan en móviles modestos); el sonido sí.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage.Shared.Sounds)
local ClientState = require(script.Parent.ClientState)

local CombatFX = {}

local player = Players.LocalPlayer
local blur, flash, ring
local muffles = {}
local muffleUntil, muffleStrength = 0, 0
local blurTarget = 0
local nextBeat = 0

local function lowQuality()
	return ClientState.EffectiveQuality == "Baja"
end

local function ensureEffects()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if not blur or blur.Parent ~= camera then
		blur = Instance.new("BlurEffect")
		blur.Name = "CombatBlur"
		blur.Size = 0
		blur.Parent = camera
	end
	if not flash or flash.Parent ~= camera then
		flash = Instance.new("ColorCorrectionEffect")
		flash.Name = "CombatFlash"
		flash.Parent = camera
	end
end

-- Filtro que apaga los agudos de todo lo que suena (el oído "taponado" tras una explosión): uno en
-- cada grupo de sonido (armas, ambiente y el resto, ver Sounds), que es donde Roblox aplica los efectos
local function ensureMuffles()
	Sounds.GetWorldGroup()
	Sounds.GetGunGroup()
	muffles = {}
	for _, group in SoundService:GetChildren() do
		if group:IsA("SoundGroup") then
			local eq = group:FindFirstChild("ConcussionMuffle")
			if not eq then
				eq = Instance.new("EqualizerSoundEffect")
				eq.Name = "ConcussionMuffle"
				eq.HighGain = 0
				eq.MidGain = 0
				eq.LowGain = 0
				eq.Priority = 10
				eq.Parent = group
			end
			table.insert(muffles, eq)
		end
	end
end

local function setMuffle(high, mid)
	for _, eq in muffles do
		if eq.Parent then
			eq.HighGain = high
			eq.MidGain = mid
			eq.Enabled = high < -0.5
		end
	end
end

-- strength: 0..1 (1 = la explosión casi encima)
function CombatFX.Concussion(strength)
	strength = math.clamp(strength or 0, 0, 1)
	-- (muerto: la cámara es la de la killcam o la de observar, no tus oídos)
	if strength < 0.2 or ClientState.InMainMenu or ClientState.Dead then
		return
	end
	ensureEffects()
	if not lowQuality() and blur and flash then
		blur.Size = 18 * strength
		blurTarget = 0
		flash.Brightness = 0.45 * strength
		flash.Contrast = -0.2 * strength
		flash.Saturation = -0.5 * strength
		TweenService:Create(flash, TweenInfo.new(1.6 * strength + 0.4), { Brightness = 0, Contrast = 0, Saturation = 0 }):Play()
	end
	-- Oído taponado: los agudos y medios bajan de golpe y vuelven poco a poco
	muffleStrength = strength
	muffleUntil = os.clock() + 1.2 + 2.3 * strength
	ensureMuffles()
	setMuffle(-30 * strength, -14 * strength)
	-- Pitido en los oídos (fuera de los grupos: no se apaga con el filtro)
	if ring then
		ring:Destroy()
	end
	-- (un único pitido agudo que se apaga solo: en bucle sonaría a pitidos seguidos)
	ring = Sounds.Play("Tinnitus", nil, 1, 0.4 + 0.6 * strength)
	if ring then
		ring.Name = "Tinnitus"
		ring.SoundGroup = nil
	end
	ClientState.ConcussedUntil = muffleUntil
end

-- Bala que pasa rozando: un instante de desenfoque y la imagen se oscurece un poco (te "encoges")
function CombatFX.Suppress(amount)
	amount = math.clamp(amount or 0.5, 0, 1)
	if ClientState.Dead or ClientState.InMainMenu then
		return
	end
	ensureEffects()
	if not lowQuality() and blur and flash then
		blur.Size = math.max(blur.Size, 5 * amount)
		blurTarget = 0
		-- (sin pisar el destello de una explosión que aún se está yendo)
		if os.clock() >= muffleUntil then
			flash.Brightness = -0.06 * amount
			flash.Contrast = 0.1 * amount
			flash.Saturation = -0.2 * amount
			TweenService:Create(flash, TweenInfo.new(0.5), { Brightness = 0, Contrast = 0, Saturation = 0 }):Play()
		end
	end
	ClientState.SuppressedAt = os.clock()
end

function CombatFX.Update(dt)
	dt = dt or 1 / 60
	-- El desenfoque se va solo (y al morir o en el menú, al momento: que se vea bien la killcam)
	if blur and blur.Size > blurTarget then
		if ClientState.Dead or ClientState.InMainMenu then
			blur.Size = blurTarget
		else
			blur.Size = math.max(blurTarget, blur.Size - dt * 9)
		end
	end
	-- El oído se destapona poco a poco
	if #muffles > 0 then
		local left = muffleUntil - os.clock()
		if left <= 0 then
			setMuffle(0, 0)
			muffles = {}
		else
			local k = math.clamp(left / (1.2 + 2.3 * math.max(muffleStrength, 0.01)), 0, 1)
			setMuffle(-30 * muffleStrength * k, -14 * muffleStrength * k)
		end
	end
	-- Latido con poca vida
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and humanoid.MaxHealth > 0 and not ClientState.InMainMenu then
		local ratio = humanoid.Health / humanoid.MaxHealth
		if ratio < 0.35 then
			local now = os.clock()
			if now >= nextBeat then
				local danger = 1 - ratio / 0.35
				-- (dos golpes, "pum-pum", cada vez más seguidos)
				Sounds.Play("Boom", nil, 0.55, 0.35 + 0.35 * danger)
				task.delay(0.16, function()
					Sounds.Play("Boom", nil, 0.5, 0.25 + 0.25 * danger)
				end)
				nextBeat = now + (1.1 - 0.5 * danger)
			end
		end
	end
end

function CombatFX.Init()
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(CombatFX.Update, dt)
		if not ok then
			warn("[CombatFX]", err)
		end
	end)
end

return CombatFX
