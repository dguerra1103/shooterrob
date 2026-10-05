-- Sonidos del juego. Los "rbxasset://" vienen incluidos con Roblox y funcionan sin subir nada.
-- Para mejores sonidos busca en el Creator Store (Toolbox > Audio) y pega aquí "rbxassetid://<id>".
local Sounds = {
	Shot = { Id = "rbxasset://sounds/paintball.wav", Volume = 0.7, Pitch = 1.3 },
	ShotHeavy = { Id = "rbxasset://sounds/Rocket shot.wav", Volume = 0.6, Pitch = 1.6 },
	Empty = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.6, Pitch = 1 },
	Reload = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.8, Pitch = 0.7 },
	Swing = { Id = "rbxasset://sounds/swordslash.wav", Volume = 0.6, Pitch = 1.2 },
	Hit = { Id = "rbxasset://sounds/snap.wav", Volume = 0.9, Pitch = 1.4 },
	Headshot = { Id = "rbxasset://sounds/snap.wav", Volume = 1, Pitch = 2 },
	Kill = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.8, Pitch = 1 },
	Click = { Id = "rbxasset://sounds/button.wav", Volume = 0.5, Pitch = 1 },
	Flag = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 1, Pitch = 0.7 },
	Slide = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.4, Pitch = 0.6 },
	Land = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.7, Pitch = 0.9 },
	Infected = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 1, Pitch = 0.4 }, -- golpe grave: ¡zombis!
	-- Capas de las armas (sonidos oficiales de Roblox: funcionan en cualquier juego)
	Boom = { Id = "rbxassetid://3149249837", Volume = 0.5, Pitch = 1 }, -- estampido grave (cañón) para dar cuerpo
	Mech = { Id = "rbxassetid://16480551554", Volume = 0.5, Pitch = 1 }, -- clic metálico del mecanismo
	MagOut = { Id = "rbxassetid://16480567946", Volume = 0.6, Pitch = 1 }, -- sacar el cargador
	MagIn = { Id = "rbxassetid://16480567638", Volume = 0.75, Pitch = 0.9 }, -- meter el cargador
	Bolt = { Id = "rbxassetid://16480567747", Volume = 0.7, Pitch = 0.8 }, -- cerrojo / corredera
	Equip = { Id = "rbxassetid://16480568148", Volume = 0.45, Pitch = 0.9 }, -- sacar el arma
	Unsheath = { Id = "rbxassetid://12222225", Volume = 0.4, Pitch = 1.3 }, -- sacar el arma cuerpo a cuerpo
	Whiz = { Id = "rbxassetid://12222095", Volume = 0.45, Pitch = 2.6 }, -- bala que pasa rozando
	LowAmmo = { Id = "rbxassetid://15675032796", Volume = 0.35, Pitch = 1.4 }, -- quedan pocas balas
	-- Pitido en los oídos tras una explosión cercana (un "ping" muy agudo que se apaga solo)
	Tinnitus = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Pitch = 2.4 },
}

-- Mezcla de las armas: grupo con compresor (más pegada), graves realzados y una cola de eco
-- corta (suena a sitio abierto en vez de a sonido "seco"). Se crea la primera vez que hace falta.
local gunGroup
local function getGunGroup()
	if gunGroup and gunGroup.Parent then
		return gunGroup
	end
	local ok = pcall(function()
		local SoundService = game:GetService("SoundService")
		local group = Instance.new("SoundGroup")
		group.Name = "Armas"
		group.Volume = 1
		local compressor = Instance.new("CompressorSoundEffect")
		compressor.Threshold = -18
		compressor.Ratio = 3
		compressor.Attack = 0.003
		compressor.Release = 0.12
		compressor.GainMakeup = 3
		compressor.Priority = 1
		compressor.Parent = group
		local eq = Instance.new("EqualizerSoundEffect")
		eq.LowGain = 5
		eq.MidGain = 0
		eq.HighGain = -2
		eq.Priority = 2
		eq.Parent = group
		local reverb = Instance.new("ReverbSoundEffect")
		reverb.DecayTime = 0.9
		reverb.Density = 0.8
		reverb.Diffusion = 0.9
		reverb.DryLevel = 0
		reverb.WetLevel = -13
		reverb.Priority = 3
		reverb.Parent = group
		group.Parent = SoundService
		gunGroup = group
	end)
	return ok and gunGroup or nil
end
Sounds.GetGunGroup = getGunGroup

-- Grupo de todos los demás sonidos (sin efectos): así se pueden filtrar todos a la vez, p. ej. el
-- oído "taponado" tras una explosión cercana (CombatFX pone su filtro en cada grupo)
local worldGroup
local function getWorldGroup()
	if worldGroup and worldGroup.Parent then
		return worldGroup
	end
	local ok = pcall(function()
		local group = Instance.new("SoundGroup")
		group.Name = "Mundo"
		group.Volume = 1
		group.Parent = game:GetService("SoundService")
		worldGroup = group
	end)
	return ok and worldGroup or nil
end
Sounds.GetWorldGroup = getWorldGroup

-- Sonido en el grupo de las armas (con la mezcla de arriba)
function Sounds.PlayGun(name, parent, pitch, volume)
	local sound = Sounds.Play(name, parent, pitch, volume)
	if sound then
		local group = getGunGroup()
		if group then
			sound.SoundGroup = group
		end
		if parent then
			-- Los disparos se oyen lejos (los de los demás también)
			sound.RollOffMode = Enum.RollOffMode.InverseTapered
			sound.RollOffMinDistance = 12
			sound.RollOffMaxDistance = 600
		end
	end
	return sound
end

-- Sonido de disparo de cada arma: { sonido, tono, volumen, tipo }. El tipo decide las capas que se
-- añaden encima (estampido grave y clic del mecanismo) para que cada arma tenga cuerpo propio.
Sounds.WeaponShots = {
	ARX27 = { "Shot", 0.95, 1, "Rifle" },
	VortexBR = { "Shot", 1.15, 0.9, "Rifle" },
	Specter9 = { "Shot", 1.2, 0.8, "Light" },
	NovaDrift = { "Shot", 1.3, 0.75, "Light" },
	SplatX = { "Shot", 1.7, 0.6, "Paint" }, -- "pop" agudo de aire comprimido
	Crossbow = { "Swing", 1.7, 0.8, "Bow" }, -- "fium" de la cuerda
	Signal7 = { "ShotHeavy", 0.75, 1.1, "Sniper" },
	GhostlineXR = { "Shot", 0.55, 0.55, "Silenced" }, -- con supresor: grave y apagado
	RaptorDMR = { "ShotHeavy", 1.05, 0.9, "Heavy" },
	HavocPump = { "ShotHeavy", 0.85, 1.1, "Shotgun" },
	BreachHammer = { "ShotHeavy", 0.7, 1.2, "Shotgun" },
	TitanLMG = { "ShotHeavy", 1.2, 0.7, "Heavy" },
	NovaLauncher = { "ShotHeavy", 0.5, 1.3, "Launcher" },
	Calabazooka = { "ShotHeavy", 0.45, 1.3, "Launcher" },
	Viper = { "Shot", 1.1, 0.8, "Light" },
	HandCannon = { "ShotHeavy", 0.9, 1, "Heavy" },
	PhantomSidewind = { "Shot", 1.35, 0.8, "Light" },
}

-- Capas por tipo: { tono y volumen del estampido, tono y volumen del clic del mecanismo }
Sounds.ShotLayers = {
	Light = { Boom = { 3.0, 0.07 }, Mech = { 1.9, 0.12 } },
	Rifle = { Boom = { 2.4, 0.13 }, Mech = { 1.6, 0.13 } },
	Heavy = { Boom = { 1.9, 0.22 }, Mech = { 1.3, 0.16 } },
	Sniper = { Boom = { 1.4, 0.38 }, Mech = { 1.1, 0.18 } },
	Shotgun = { Boom = { 1.6, 0.36 }, Mech = { 1.0, 0.16 } },
	Launcher = { Boom = { 1.0, 0.3 } },
	Silenced = { Mech = { 1.4, 0.22 } },
	Paint = {},
	Bow = {},
}

-- Cola de tus disparos (eco del entorno): { tono, volumen } del estampido grave, ya filtrado
Sounds.ShotTails = {
	Light = { 0.9, 0.05 },
	Rifle = { 0.75, 0.09 },
	Heavy = { 0.65, 0.12 },
	Sniper = { 0.5, 0.2 },
	Shotgun = { 0.55, 0.16 },
	Launcher = { 0.45, 0.14 },
}
local lastTail = 0

local function shotType(weaponName, def)
	local profile = weaponName and Sounds.WeaponShots[weaponName]
	if profile and profile[4] then
		return profile[4]
	end
	if def and def.Explosive then
		return "Launcher"
	elseif def and def.Pellets > 1 then
		return "Shotgun"
	elseif def and def.Damage >= 80 then
		return "Sniper"
	end
	return "Rifle"
end
Sounds.ShotType = shotType

-- Disparo de un arma: su sonido propio más las capas de su tipo. Con parent (los disparos de
-- los demás) suena en 3D; si está lejos se oye apagado y con retraso (el sonido viaja más
-- despacio que la bala). listener = posición de quien escucha (la cámara).
function Sounds.PlayShot(weaponName, def, parent, listener)
	local profile = weaponName and Sounds.WeaponShots[weaponName]
	local name, pitch, volume = "Shot", 1, 1
	if profile then
		name, pitch, volume = profile[1], profile[2], profile[3]
	elseif def ~= nil and (def.Pellets > 1 or def.Damage >= 80) then
		name = "ShotHeavy"
	end
	local layers = Sounds.ShotLayers[shotType(weaponName, def)] or {}
	local distance = 0
	if parent and listener and parent:IsA("BasePart") then
		distance = (parent.Position - listener).Magnitude
	end
	local far = distance > 140
	local kind = shotType(weaponName, def)
	local function play()
		local body = Sounds.PlayGun(name, parent, pitch, volume)
		if far and body then
			-- Lejos: sin agudos (se oye el "pum" sordo de los disparos a lo lejos)
			pcall(function()
				local muffle = Instance.new("EqualizerSoundEffect")
				muffle.HighGain = -20
				muffle.MidGain = -6
				muffle.LowGain = 2
				muffle.Parent = body
			end)
		end
		if layers.Boom then
			Sounds.PlayGun("Boom", parent, layers.Boom[1], layers.Boom[2] * (parent and 0.8 or 1))
		end
		-- El clic del mecanismo solo se oye de cerca
		if layers.Mech and distance < 60 then
			Sounds.PlayGun("Mech", parent, layers.Mech[1], layers.Mech[2])
		end
		-- Cola: tus disparos dejan un eco grave y apagado que rebota en el mapa (capa "entorno").
		-- Como mucho una cada 0,2 s: en ráfaga no se amontonan
		local tail = Sounds.ShotTails[kind]
		if tail and parent == nil and os.clock() - lastTail >= 0.2 then
			lastTail = os.clock()
			task.delay(0.07, function()
				-- (en el grupo de las armas: el volumen de armas también la baja)
				local echo = Sounds.PlayGun("Boom", nil, tail[1], tail[2])
				if echo then
					pcall(function()
						local eq = Instance.new("EqualizerSoundEffect")
						eq.HighGain = -24
						eq.MidGain = -8
						eq.LowGain = 0
						eq.Parent = echo
					end)
				end
			end)
		end
		return body
	end
	if distance > 60 then
		-- ~1100 studs por segundo; como mucho medio segundo de retraso
		task.delay(math.min(0.5, distance / 1100), play)
		return nil
	end
	return play()
end

-- Reproduce un sonido. Si parent es nil, suena en 2D (para el jugador local).
-- pitch y volume (opcionales) multiplican los valores del sonido: así cada arma suena distinta.
function Sounds.Play(name, parent, pitch, volume)
	local info = Sounds[name]
	if type(info) ~= "table" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = info.Id
	sound.Volume = info.Volume * (volume or 1)
	sound.PlaybackSpeed = info.Pitch * (pitch or 1) * (0.95 + math.random() * 0.1)
	sound.RollOffMaxDistance = 300
	local group = getWorldGroup()
	if group then
		sound.SoundGroup = group
	end
	sound.Parent = parent or workspace.CurrentCamera or workspace
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
	return sound
end

return Sounds
