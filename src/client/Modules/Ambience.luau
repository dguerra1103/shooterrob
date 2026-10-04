-- Sonido ambiente de los mapas realistas (atributo Ambience de workspace.Map, lo pone cada mapa):
--   "War"  (Encrucijada): explosiones y ráfagas lejanas, como una guerra en otros barrios, y algo de viento
--   "Base" (Base Militar): disparos sueltos de la galería de tiro a lo lejos y brisa
--   "Wind" (Cumbre): viento fuerte de montaña
-- Todo con sonidos que vienen con Roblox, apagados (filtro de graves) para que suenen lejos. Solo
-- durante la partida y nunca en la pantalla de inicio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local ClientState = require(script.Parent.ClientState)

local Ambience = {}

local WIND_ID = "rbxasset://sounds/action_falling.mp3"
local BOOM_ID = "rbxasset://sounds/Rocket shot.wav"
local SHOT_ID = "rbxasset://sounds/paintball.wav"

local PRESETS = {
	War = { Wind = 0.12, WindSpeed = 0.55, Booms = { 9, 22 }, Bursts = { 4, 11 } },
	Base = { Wind = 0.07, WindSpeed = 0.5, Booms = nil, Bursts = { 6, 16 } },
	Wind = { Wind = 0.4, WindSpeed = 0.42, Booms = nil, Bursts = nil },
}

local group, wind
local nextBoom, nextBurst = 0, 0

-- Grupo con filtro de graves y un poco de eco: todo suena lejano
local function ensureGroup()
	if group and group.Parent then
		return group
	end
	group = Instance.new("SoundGroup")
	group.Name = "Ambiente"
	group.Volume = 1
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain = -28
	eq.MidGain = -8
	eq.LowGain = 3
	eq.Parent = group
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 2.2
	reverb.WetLevel = -6
	reverb.Parent = group
	group.Parent = SoundService
	return group
end

local function oneShot(id, volume, speed)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.PlaybackSpeed = speed
	sound.SoundGroup = ensureGroup()
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(6, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Ráfaga lejana: 3 a 7 disparos seguidos con la cadencia de un fusil
local function burst()
	local shots = math.random(3, 7)
	local speed = 0.55 + math.random() * 0.25
	local volume = 0.05 + math.random() * 0.06
	task.spawn(function()
		for _ = 1, shots do
			oneShot(SHOT_ID, volume, speed * (0.95 + math.random() * 0.1))
			task.wait(0.08 + math.random() * 0.05)
		end
	end)
end

local function current()
	if ClientState.InMainMenu or ReplicatedStorage:GetAttribute("State") == "Intermission" then
		return nil
	end
	local map = workspace:FindFirstChild("Map")
	local kind = map and map:GetAttribute("Ambience")
	return kind and PRESETS[kind] or nil
end

function Ambience.Update()
	local preset = current()
	if not preset then
		if wind then
			wind.Volume = 0
		end
		return
	end
	if not wind or not wind.Parent then
		wind = Instance.new("Sound")
		wind.Name = "AmbienceWind"
		wind.SoundId = WIND_ID
		wind.Looped = true
		wind.SoundGroup = ensureGroup()
		wind.Parent = SoundService
		wind:Play()
	end
	-- (el viento sube y baja poco a poco, como ráfagas)
	local gust = 0.8 + 0.2 * math.sin(os.clock() * 0.35) + 0.1 * math.sin(os.clock() * 1.3)
	wind.Volume = preset.Wind * gust
	wind.PlaybackSpeed = preset.WindSpeed
	if not wind.IsPlaying then
		wind:Play()
	end
	local now = os.clock()
	if preset.Booms and now >= nextBoom then
		if nextBoom > 0 then
			oneShot(BOOM_ID, 0.18 + math.random() * 0.15, 0.3 + math.random() * 0.12)
		end
		nextBoom = now + preset.Booms[1] + math.random() * (preset.Booms[2] - preset.Booms[1])
	end
	if preset.Bursts and now >= nextBurst then
		if nextBurst > 0 then
			burst()
		end
		nextBurst = now + preset.Bursts[1] + math.random() * (preset.Bursts[2] - preset.Bursts[1])
	end
end

function Ambience.Init()
	task.spawn(function()
		while true do
			local ok, err = pcall(Ambience.Update)
			if not ok then
				warn("[Ambiente]", err)
				task.wait(5)
			end
			task.wait(0.25)
		end
	end)
end

return Ambience
