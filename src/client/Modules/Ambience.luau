-- Sonido ambiente de los mapas realistas (atributo Ambience de workspace.Map, lo pone cada mapa):
--   "War"  (Encrucijada): explosiones y ráfagas lejanas, como una guerra en otros barrios, y algo de viento
--   "Base" (Base Militar): disparos sueltos de la galería de tiro a lo lejos y brisa
--   "Wind" (Cumbre): viento fuerte de montaña
--   y en los demás mapas: "Breeze" (brisa), "Snow" (viento helado), "Coast" (brisa y olas que rompen),
--   "Night" (viento suave de noche), "Jungle", "Factory" (nave: casi nada, eco de nave) y "Desert"
-- Y el tiempo (atributo Weather de workspace.Map): "Rain" = lluvia alrededor de la cámara, ruido de
-- lluvia y, de vez en cuando, un relámpago (destello) y el trueno un par de segundos después.
-- Todo con sonidos que vienen con Roblox, apagados (filtro de graves) para que suenen lejos. Solo
-- durante la partida y nunca en la pantalla de inicio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local ClientState = require(script.Parent.ClientState)

local Ambience = {}

local WIND_ID = "rbxasset://sounds/action_falling.mp3"
local BOOM_ID = "rbxasset://sounds/Rocket shot.wav"
local SHOT_ID = "rbxasset://sounds/paintball.wav"
local WAVE_ID = "rbxasset://sounds/impact_water.mp3"

local PRESETS = {
	War = { Wind = 0.12, WindSpeed = 0.55, Booms = { 9, 22 }, Bursts = { 4, 11 } },
	Base = { Wind = 0.07, WindSpeed = 0.5, Booms = nil, Bursts = { 6, 16 } },
	Wind = { Wind = 0.4, WindSpeed = 0.42, Booms = nil, Bursts = nil },
	Breeze = { Wind = 0.06, WindSpeed = 0.5 },
	Snow = { Wind = 0.22, WindSpeed = 0.45 },
	Coast = { Wind = 0.1, WindSpeed = 0.55, Waves = { 5, 10 } },
	Night = { Wind = 0.12, WindSpeed = 0.38 },
	Jungle = { Wind = 0.07, WindSpeed = 0.62 },
	Factory = { Wind = 0.03, WindSpeed = 0.3 },
	Desert = { Wind = 0.16, WindSpeed = 0.5 },
}

local group, wind
local nextBoom, nextBurst, nextWave = 0, 0, 0
local rainBox, rainSound, rainConnection
local nextThunder = 0

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

-- Lluvia: una caja invisible encima de la cámara que la sigue y suelta gotas rápidas y alargadas
local function startRain()
	if rainBox and rainBox.Parent then
		return
	end
	rainBox = Instance.new("Part")
	rainBox.Name = "RainBox"
	rainBox.Anchored = true
	rainBox.CanCollide = false
	rainBox.CanQuery = false
	rainBox.CanTouch = false
	rainBox.Transparency = 1
	rainBox.Size = Vector3.new(70, 1, 70)
	local drops = Instance.new("ParticleEmitter")
	drops.Name = "Drops"
	drops.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	drops.Color = ColorSequence.new(Color3.fromRGB(200, 210, 225))
	drops.LightInfluence = 1
	drops.Transparency = NumberSequence.new(0.45)
	drops.Size = NumberSequence.new(0.09)
	drops.Squash = NumberSequence.new(-2.5) -- (gotas alargadas en la dirección en la que caen)
	drops.Orientation = Enum.ParticleOrientation.VelocityParallel
	drops.Lifetime = NumberRange.new(0.55, 0.7)
	drops.Speed = NumberRange.new(85, 100)
	drops.SpreadAngle = Vector2.new(4, 4)
	drops.EmissionDirection = Enum.NormalId.Bottom
	drops.Rate = 650
	drops.Shape = Enum.ParticleEmitterShape.Box
	drops.Parent = rainBox
	rainBox.Parent = workspace.CurrentCamera or workspace
	rainSound = Instance.new("Sound")
	rainSound.Name = "AmbienceRain"
	rainSound.SoundId = WIND_ID
	rainSound.Looped = true
	rainSound.Volume = 0.22
	rainSound.PlaybackSpeed = 1.45 -- (el viento acelerado suena como lluvia)
	rainSound.SoundGroup = ensureGroup()
	rainSound.Parent = SoundService
	rainSound:Play()
	rainConnection = RunService.Heartbeat:Connect(function()
		local camera = workspace.CurrentCamera
		if camera and rainBox then
			local p = camera.CFrame.Position
			rainBox.CFrame = CFrame.new(p.X, p.Y + 40, p.Z)
		end
	end)
end

local function stopRain()
	if rainConnection then
		rainConnection:Disconnect()
		rainConnection = nil
	end
	if rainBox then
		rainBox:Destroy()
		rainBox = nil
	end
	if rainSound then
		rainSound:Destroy()
		rainSound = nil
	end
end

-- Relámpago: la escena se ilumina de golpe un instante y el trueno llega después
local function lightning()
	local before = Lighting.ExposureCompensation
	Lighting.ExposureCompensation = before + 1.6
	task.delay(0.08, function()
		Lighting.ExposureCompensation = before + 0.4
		task.wait(0.06)
		Lighting.ExposureCompensation = before + 1.1
		task.wait(0.1)
		Lighting.ExposureCompensation = before
	end)
	task.delay(1 + math.random() * 2, function()
		oneShot(BOOM_ID, 0.45, 0.22 + math.random() * 0.06)
	end)
end

-- Eco del sitio (SoundService.AmbientReverb, afecta a todos los sonidos): dentro de un edificio los
-- disparos retumban como en una habitación; fuera, según el mapa (ciudad, montaña, campo abierto)
local OUTDOOR_REVERB = {
	War = Enum.ReverbType.City,
	Base = Enum.ReverbType.Plain,
	Wind = Enum.ReverbType.Mountains,
	Snow = Enum.ReverbType.Mountains,
	Jungle = Enum.ReverbType.Forest,
	Factory = Enum.ReverbType.Hangar,
}
local reverbParams = RaycastParams.new()
reverbParams.FilterType = Enum.RaycastFilterType.Include
local function updateReverb(map, preset)
	local reverb = Enum.ReverbType.NoReverb
	local camera = workspace.CurrentCamera
	if map and camera and not ClientState.InMainMenu then
		reverb = (preset and OUTDOOR_REVERB[map:GetAttribute("Ambience")]) or Enum.ReverbType.Plain
		-- ¿Bajo techo? (y no es el techo invisible del límite del mapa)
		reverbParams.FilterDescendantsInstances = { map }
		local roof = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, 30, 0), reverbParams)
		local boundary = map:FindFirstChild("Boundary")
		if roof and not (boundary and roof.Instance:IsDescendantOf(boundary)) and roof.Instance.Name ~= "Boundary" then
			-- (y con paredes alrededor: bajo un árbol o un toldo sigue siendo la calle)
			local walls = 0
			local origin = camera.CFrame.Position
			for _, direction in { Vector3.new(24, 0, 0), Vector3.new(-24, 0, 0), Vector3.new(0, 0, 24), Vector3.new(0, 0, -24) } do
				local hit = workspace:Raycast(origin, direction, reverbParams)
				if hit and not (boundary and hit.Instance:IsDescendantOf(boundary)) then
					walls += 1
				end
			end
			if walls >= 2 then
				reverb = roof.Distance < 14 and Enum.ReverbType.Room or Enum.ReverbType.Hallway
			end
		end
	end
	if SoundService.AmbientReverb ~= reverb then
		SoundService.AmbientReverb = reverb
	end
	Ambience.Reverb = reverb
end

function Ambience.Update()
	local preset = current()
	local map = workspace:FindFirstChild("Map")
	pcall(updateReverb, map, preset)
	local raining = preset ~= nil and map ~= nil and map:GetAttribute("Weather") == "Rain"
	if raining then
		startRain()
		-- Bajo techo no caen gotas (seguirían atravesando el tejado); en calidad Baja, menos gotas
		local drops = rainBox and rainBox:FindFirstChild("Drops")
		local camera = workspace.CurrentCamera
		if drops and drops:IsA("ParticleEmitter") and camera then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { map }
			local roof = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, 60, 0), params)
			-- (el techo invisible del límite del mapa no cuenta como tejado)
			local boundary = map:FindFirstChild("Boundary")
			if roof and boundary and roof.Instance:IsDescendantOf(boundary) then
				roof = nil
			end
			drops.Enabled = roof == nil
			local quality = ClientState.EffectiveQuality
			drops.Rate = (quality == "Baja" and 250) or (quality == "Media" and 420) or 650
		end
		if os.clock() >= nextThunder then
			if nextThunder > 0 then
				lightning()
			end
			nextThunder = os.clock() + 14 + math.random() * 18
		end
	else
		stopRain()
	end
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
	-- (con ventisca, el viento sopla mucho más fuerte)
	local storm = map ~= nil and map:GetAttribute("Weather") == "Snowstorm"
	wind.Volume = preset.Wind * gust * (storm and 1.7 or 1)
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
	-- Olas que rompen a lo lejos (puertos y playas)
	if preset.Waves and now >= nextWave then
		if nextWave > 0 then
			oneShot(WAVE_ID, 0.08 + math.random() * 0.06, 0.45 + math.random() * 0.15)
		end
		nextWave = now + preset.Waves[1] + math.random() * (preset.Waves[2] - preset.Waves[1])
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
