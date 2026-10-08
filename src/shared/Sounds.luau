-- Sonidos del juego. Los "rbxasset://" vienen incluidos con Roblox y funcionan sin subir nada.
-- Los "rbxassetid://91…" son de la biblioteca de Pro Sound Effects que Roblox licencia para todos los
-- juegos (creador "ProSoundEffects", marcados como de dominio público en Roblox): ver
-- FASE_11_PULIDO_GENERAL.md (sección B) con el nombre y la descripción de cada uno.
-- Region = { inicio, fin } en segundos: solo suena ese trozo del archivo (Sound.PlaybackRegion).
local Sounds = {
	Shot = { Id = "rbxasset://sounds/paintball.wav", Volume = 0.7, Pitch = 1.3 },
	ShotHeavy = { Id = "rbxasset://sounds/Rocket shot.wav", Volume = 0.6, Pitch = 1.6 },
	Empty = { Id = "rbxassetid://9119718459", Volume = 0.55, Pitch = 1.1, Region = { 0, 0.25 } }, -- clic seco metálico (gatillo en vacío)
	Reload = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.8, Pitch = 0.7 },
	Swing = { Id = "rbxasset://sounds/swordslash.wav", Volume = 0.6, Pitch = 1.2 },
	MeleeSwing = { Id = "rbxassetid://9120972321", Volume = 0.55, Pitch = 1.05, Region = { 0, 0.4 } }, -- «fium» de un golpe rápido
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
	MagOut = { Id = "rbxassetid://9113104517", Volume = 0.55, Pitch = 1, Region = { 0.18, 0.75 } }, -- sacar el cargador
	MagIn = { Id = "rbxassetid://9113104208", Volume = 0.65, Pitch = 1, Region = { 0, 0.45 } }, -- meter el cargador
	Bolt = { Id = "rbxassetid://9116361515", Volume = 0.6, Pitch = 1 }, -- cerrojo / corredera / palanca
	Equip = { Id = "rbxassetid://9114702107", Volume = 0.45, Pitch = 1, Region = { 0, 0.35 } }, -- sacar el arma
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
	local sound = Sounds.Play(name, parent, pitch, volume, "gun")
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

-- Audio por arma (Fase 2) y por familia (Fase 11). Orden: el hueco propio del arma
-- (Sounds.WeaponAudio) → el de su familia (Sounds.FamilyAudio) → el genérico de arriba.
-- "" = sin sonido propio (se mira la familia). Valor: "rbxassetid://<id>" o
-- { Id = "...", Volume = 1, Pitch = 1, Region = { inicio, fin }, Variants = { Id o { Id, Region } } }
-- (Variants: cada vez suena una al azar, sin repetir la anterior). false = esa capa no suena.
-- Nunca sonidos sacados de otros juegos: grabados, con licencia o de la biblioteca de Roblox.
--   ShotClose      disparo oído de cerca (el cuerpo del disparo)
--   ShotMechanical clic del mecanismo (solo de cerca)
--   ShotTail       eco/cola del disparo en el entorno (solo tus disparos)
--   Reload         inicio de la recarga (opcional)
--   MagOut, MagIn  sacar y meter el cargador
--   Bolt           cerrojo / corredera / bombeo / palanca de carga (recarga vacía)
--   Empty          gatillo en vacío (dry fire)
--   Equip          sacar el arma
--   Unequip        guardar el arma (Fase 9; vacío = en silencio, como antes)
--   Inspect        inspeccionar (Fase 9; vacío = en silencio)
--   Melee          golpe cuerpo a cuerpo con esta arma (Fase 9; vacío = el «fium» genérico)
-- Disparo por capas: ShotClose (cuerpo) + ShotMechanical (mecanismo) + ShotTail (cola): como mucho
-- tres sonidos por disparo más el estampido grave genérico (Sounds.ShotLayers) mientras no haya propio.
Sounds.WeaponAudioSlots = { "ShotClose", "ShotMechanical", "ShotTail", "Reload", "MagIn", "MagOut", "Bolt", "Empty", "Equip", "Unequip", "Inspect", "Melee" }
local function slots(custom: { [string]: any }?)
	local entry = {}
	for _, slot in Sounds.WeaponAudioSlots do
		entry[slot] = ""
	end
	if custom then
		for slot, value in custom do
			entry[slot] = value
		end
	end
	return entry
end
Sounds.WeaponAudio = {
	ARX27 = slots(), -- arma de referencia: la primera que debería tener su audio propio
	VortexBR = slots(),
	Specter9 = slots(),
	NovaDrift = slots(),
	SplatX = slots(),
	TitanLMG = slots(),
	HavocPump = slots(),
	BreachHammer = slots(),
	RaptorDMR = slots(),
	Crossbow = slots(),
	Signal7 = slots(),
	GhostlineXR = slots(),
	Viper = slots(),
	PhantomSidewind = slots(),
	HandCannon = slots(),
	NovaLauncher = slots(),
	Calabazooka = slots(),
}

-- Familia de audio de cada arma (las que no están aquí usan los genéricos: paintball, ballesta y
-- lanzacohetes no suenan a arma de fuego). Pitch: tono de esa arma dentro de su familia.
Sounds.WeaponAudioFamily = {
	ARX27 = "Rifle",
	VortexBR = "Rifle",
	Specter9 = "SMG",
	NovaDrift = "SMG",
	Viper = "Pistol",
	PhantomSidewind = "Pistol",
	HandCannon = "Magnum",
	HavocPump = "Shotgun",
	BreachHammer = "Shotgun",
	RaptorDMR = "Marksman",
	Signal7 = "Sniper",
	GhostlineXR = "Suppressed",
	TitanLMG = "LMG",
}
Sounds.WeaponAudioPitch = {
	VortexBR = 1.05,
	NovaDrift = 1.06,
	PhantomSidewind = 1.05,
	BreachHammer = 0.92,
}

-- Grabaciones reales de la biblioteca de Pro Sound Effects en Roblox (ids comprobados con la API de
-- Roblox: creador ProSoundEffects, dominio público). Se eligieron midiendo cada archivo (un solo
-- disparo, ataque, cola) y Region recorta lo que sobra (otro disparo, manejo, ruido de fondo).
local AK_SINGLE = { "rbxassetid://9116343332", { Id = "rbxassetid://9116337694", Region = { 0, 1.2 } } } -- AK-47, disparos sueltos de cerca
local TAIL_DISTANT = { Id = "rbxassetid://9114697150", Volume = 0.22, Region = { 0, 1.3 } } -- disparo lejano (cola del entorno)
local HANDLING = {
	MagOutRifle = { Id = "rbxassetid://9116347612", Volume = 0.6, Region = { 0.17, 0.5 } }, -- AK-47, manejo del cargador
	MagInRifle = { Id = "rbxassetid://9116348211", Volume = 0.7, Region = { 0.36, 0.75 } }, -- AK-47, cargador encajando
	MagOutPistol = { Id = "rbxassetid://9113104517", Volume = 0.55, Region = { 0.18, 0.75 } },
	MagInPistol = { Id = "rbxassetid://9113104208", Volume = 0.65, Region = { 0, 0.45 } },
	Charge = { Id = "rbxassetid://9116361515", Volume = 0.6 }, -- palanca de carga (cámara de ametralladora M85)
	BoltAction = { Id = "rbxassetid://9116357621", Volume = 0.6, Region = { 0, 0.8 } }, -- cerrojo que abre y cierra
	Slide = { Id = "rbxassetid://9117396156", Volume = 0.6 }, -- corredera / cargador de pistola
	Pump = { Id = "rbxassetid://9112911123", Volume = 0.7 }, -- bombeo de escopeta expulsando el cartucho
	SmgCock = { Id = "rbxassetid://9116344855", Volume = 0.6, Region = { 0, 0.32 } }, -- montar un subfusil (MP 40)
	ShellIn = { Id = "rbxassetid://9117396164", Volume = 0.5, Region = { 0.82, 1.2 } }, -- cartucho entrando
	Grab = { Id = "rbxassetid://9114702107", Volume = 0.45, Region = { 0, 0.35 } }, -- agarrar el arma con fuerza
	Holster = { Id = "rbxassetid://9114701864", Volume = 0.45, Region = { 0, 0.45 } }, -- pistola de la funda
	Stow = { Id = "rbxassetid://9116362330", Volume = 0.3 }, -- guardar (manejo de un arma larga)
	Inspect = { Id = "rbxassetid://9117396530", Volume = 0.4 }, -- manejo: agarre, traqueteo y clic
	DryFire = { Id = "rbxassetid://9119718459", Volume = 0.55, Pitch = 1.1, Region = { 0, 0.25 } },
	Swing = { Id = "rbxassetid://9120972321", Volume = 0.55, Region = { 0, 0.4 } },
}
local function family(shot, extra)
	local entry = {
		ShotClose = shot,
		ShotMechanical = false, -- (las grabaciones ya llevan el mecanismo)
		ShotTail = TAIL_DISTANT,
		MagOut = HANDLING.MagOutRifle,
		MagIn = HANDLING.MagInRifle,
		Bolt = HANDLING.Charge,
		Empty = HANDLING.DryFire,
		Equip = HANDLING.Grab,
		Unequip = HANDLING.Stow,
		Inspect = HANDLING.Inspect,
		Melee = HANDLING.Swing,
	}
	for slot, value in extra or {} do
		entry[slot] = value
	end
	return entry
end
Sounds.FamilyAudio = {
	-- Fusil: equilibrado (AK-47 de cerca, dos tomas que se alternan)
	Rifle = family({ Variants = AK_SINGLE, Volume = 0.62 }),
	-- Subfusil: ligero y rápido (Mini Uzi, un solo disparo del archivo)
	SMG = family({ Id = "rbxassetid://9114728853", Volume = 0.6, Pitch = 1.04, Region = { 0.02, 0.25 } }, {
		ShotTail = { Id = TAIL_DISTANT.Id, Volume = 0.14, Pitch = 1.1, Region = TAIL_DISTANT.Region },
		MagOut = HANDLING.MagOutPistol,
		MagIn = HANDLING.MagInPistol,
		Bolt = HANDLING.SmgCock,
	}),
	-- Pistola: rápida e inmediata (Beretta 9 mm, cuatro tomas)
	Pistol = family({
		Variants = { "rbxassetid://9114694651", "rbxassetid://9114694945", "rbxassetid://9114694502", "rbxassetid://9114694336" },
		Volume = 0.55,
		Region = { 0, 0.7 },
	}, {
		ShotTail = { Id = TAIL_DISTANT.Id, Volume = 0.12, Pitch = 1.15, Region = TAIL_DISTANT.Region },
		MagOut = HANDLING.MagOutPistol,
		MagIn = HANDLING.MagInPistol,
		Bolt = HANDLING.Slide,
		Equip = HANDLING.Holster,
	}),
	-- Revólver pesado (Smith & Wesson .357 Magnum)
	Magnum = family({ Id = "rbxassetid://9119296941", Volume = 0.62, Region = { 0, 1.2 } }, {
		MagOut = HANDLING.MagOutPistol,
		MagIn = HANDLING.MagInPistol,
		Bolt = HANDLING.Slide,
		Equip = HANDLING.Holster,
	}),
	-- Escopeta: pesada y agresiva (Remington 870 y Savage semiautomática)
	Shotgun = family({
		Variants = { { Id = "rbxassetid://9114708745", Region = { 0, 1.2 } }, { Id = "rbxassetid://9112912844", Region = { 0, 1.1 } } },
		Volume = 0.66,
	}, {
		ShotTail = { Id = TAIL_DISTANT.Id, Volume = 0.3, Pitch = 0.9, Region = TAIL_DISTANT.Region },
		MagIn = HANDLING.ShellIn,
		Bolt = HANDLING.Pump,
	}),
	-- Tirador: contundente (disparo seco con eco)
	Marksman = family({ Id = "rbxassetid://9114725315", Volume = 0.6, Region = { 0.02, 1.5 } }, {
		ShotTail = { Id = TAIL_DISTANT.Id, Volume = 0.28, Pitch = 0.92, Region = TAIL_DISTANT.Region },
	}),
	-- Francotirador: lento y contundente (Barrett .50)
	Sniper = family({ Id = "rbxassetid://9118173988", Volume = 0.7, Region = { 0, 1.6 } }, {
		ShotTail = { Id = TAIL_DISTANT.Id, Volume = 0.36, Pitch = 0.85, Region = TAIL_DISTANT.Region },
		Bolt = HANDLING.BoltAction,
	}),
	-- Francotirador con supresor (H&K SOCOM Mk 23 suprimida, más grave)
	Suppressed = family({ Id = "rbxassetid://9119135228", Volume = 0.6, Pitch = 0.85, Region = { 0, 0.4 } }, {
		ShotTail = false,
		Bolt = HANDLING.BoltAction,
	}),
	-- Ametralladora: muy pesada (el AK-47 más grave)
	LMG = family({ Variants = AK_SINGLE, Volume = 0.66, Pitch = 0.88 }, {
		ShotTail = { Id = TAIL_DISTANT.Id, Volume = 0.26, Pitch = 0.9, Region = TAIL_DISTANT.Region },
		Bolt = { Id = "rbxassetid://9116357355", Volume = 0.6, Region = { 0, 0.5 } },
	}),
}

-- Valor de un hueco: el propio del arma o, si está vacío, el de su familia. false = capa apagada.
local function slotValue(weaponName: string?, slot: string): any
	local entry = weaponName and Sounds.WeaponAudio[weaponName]
	local value = entry and entry[slot]
	if value == nil or value == "" then
		local familyName = weaponName and Sounds.WeaponAudioFamily[weaponName]
		local preset = familyName and Sounds.FamilyAudio[familyName]
		value = preset and preset[slot]
	end
	return value
end

-- La capa está apagada a propósito (p. ej. el clic del mecanismo de una grabación que ya lo lleva)
function Sounds.SlotDisabled(weaponName: string?, slot: string): boolean
	return slotValue(weaponName, slot) == false
end

-- Info de sonido a partir del valor de un hueco (nil si no vale)
local function slotInfo(value: any, weaponPitch: number): { [string]: any }?
	if type(value) == "string" and value ~= "" then
		return { Id = value, Volume = 1, Pitch = weaponPitch }
	elseif type(value) == "table" then
		local variants = {}
		for _, variant in value.Variants or {} do
			if type(variant) == "string" and variant ~= "" then
				table.insert(variants, { Id = variant })
			elseif type(variant) == "table" and type(variant.Id) == "string" and variant.Id ~= "" then
				table.insert(variants, variant)
			end
		end
		local id = type(value.Id) == "string" and value.Id ~= "" and value.Id or (variants[1] and variants[1].Id)
		if not id then
			return nil
		end
		return {
			Id = id,
			Volume = value.Volume or 1,
			Pitch = (value.Pitch or 1) * weaponPitch,
			Region = value.Region,
			Variants = #variants > 1 and variants or nil,
		}
	end
	return nil
end

-- Nombre del sonido a usar para un hueco de un arma: el suyo o el de su familia (se registra como
-- "W:<arma>:<hueco>" y se vuelve a registrar si cambia) o `fallback` (el genérico). nil si no hay.
function Sounds.WeaponSoundName(weaponName: string?, slot: string, fallback: string?): string?
	if not weaponName then
		return fallback
	end
	local value = slotValue(weaponName, slot)
	local info = slotInfo(value, Sounds.WeaponAudioPitch[weaponName] or 1)
	if not info then
		return fallback
	end
	local key = "W:" .. weaponName .. ":" .. slot
	local current = Sounds[key]
	if type(current) ~= "table" or current.Source ~= value then
		info.Source = value
		Sounds[key] = info
	end
	return key
end

-- Sonido de un hueco del arma en el grupo de las armas. Con sonido propio no se le cambia el tono
-- (se grabó así); con el genérico, el tono y volumen que se pidan, como antes.
-- customPitch (opcional): tono relativo también para el sonido propio (p. ej. cartuchos que suben).
function Sounds.PlayWeapon(weaponName: string?, slot: string, fallback: string?, parent: Instance?, pitch: number?, volume: number?, customPitch: number?)
	local name = Sounds.WeaponSoundName(weaponName, slot, fallback)
	if not name then
		return nil
	end
	if name ~= fallback then
		return Sounds.PlayGun(name, parent, customPitch or 1, 1)
	end
	return Sounds.PlayGun(name, parent, pitch, volume)
end

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
	-- (sonido propio del arma o de su familia si lo tiene; de lejos, el mismo apagado. Si no, el
	-- genérico de siempre)
	local closeName = Sounds.WeaponSoundName(weaponName, "ShotClose", nil)
	if closeName then
		name, pitch, volume = closeName, 1, 1
	end
	local mechName = Sounds.WeaponSoundName(weaponName, "ShotMechanical", nil)
	local mechOff = Sounds.SlotDisabled(weaponName, "ShotMechanical")
	local tailName = Sounds.WeaponSoundName(weaponName, "ShotTail", nil)
	local tailOff = Sounds.SlotDisabled(weaponName, "ShotTail")
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
			-- (con grabación real, el estampido solo da un poco de peso por debajo)
			Sounds.PlayGun("Boom", parent, layers.Boom[1], layers.Boom[2] * (parent and 0.8 or 1) * (closeName and 0.6 or 1))
		end
		-- El clic del mecanismo solo se oye de cerca
		if mechName and distance < 60 then
			Sounds.PlayGun(mechName, parent, 1, 1)
		elseif layers.Mech and distance < 60 and not mechOff then
			Sounds.PlayGun("Mech", parent, layers.Mech[1], layers.Mech[2])
		end
		-- Cola: tus disparos dejan un eco grave y apagado que rebota en el mapa (capa "entorno").
		-- Como mucho una cada 0,2 s: en ráfaga no se amontonan
		local tail = not tailOff and Sounds.ShotTails[kind] or nil
		if tailName and parent == nil and os.clock() - lastTail >= 0.2 then
			lastTail = os.clock()
			Sounds.PlayGun(tailName, nil, 1, 1)
		elseif tail and parent == nil and os.clock() - lastTail >= 0.2 then
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
-- Sonidos 2D que suenan muchísimo (cada disparo, cada impacto): se reutilizan en vez de crear y
-- destruir una instancia cada vez. Cinco por nombre; si suenan todos, se corta el más antiguo
local POOLED = { Shot = true, ShotHeavy = true, Boom = true, Mech = true, Hit = true, Headshot = true, Kill = true, Click = true, Empty = true, Swing = true }
-- Variación de tono al azar en cada reproducción (que dos disparos seguidos no suenen idénticos):
-- ±5 % en general y ±2 % en las armas (Fase 9: más es caricaturesco)
Sounds.PitchVariation = 0.05
Sounds.GunPitchVariation = 0.02
local function randomPitch(poolKey)
	local variation = poolKey == "gun" and Sounds.GunPitchVariation or Sounds.PitchVariation
	return 1 + (math.random() * 2 - 1) * variation
end
local POOL_SIZE = 6

-- Variante de un sonido con varias tomas: una al azar sin repetir la última. Se registra como
-- "<nombre>#<n>" (así cada toma tiene su propio grupo de reutilización)
local lastVariant = {}
local function pickVariant(name, info)
	local count = #info.Variants
	local index = math.random(1, count)
	if count > 1 and index == lastVariant[name] then
		index = index % count + 1
	end
	lastVariant[name] = index
	local key = name .. "#" .. index
	local variant = info.Variants[index]
	local current = Sounds[key]
	if type(current) ~= "table" or current.Parent ~= info then
		Sounds[key] = {
			Id = variant.Id,
			Volume = info.Volume * (variant.Volume or 1),
			Pitch = info.Pitch * (variant.Pitch or 1),
			Region = variant.Region or info.Region,
			Parent = info,
		}
	end
	return key, Sounds[key]
end

-- Solo suena el trozo Region = { inicio, fin } del archivo (o el archivo entero)
local function applyRegion(sound, region)
	pcall(function()
		if region then
			sound.PlaybackRegionsEnabled = true
			sound.PlaybackRegion = NumberRange.new(region[1], region[2])
		elseif sound.PlaybackRegionsEnabled then
			sound.PlaybackRegionsEnabled = false
		end
	end)
end
local pools = {} -- [nombre] = { Sound }

local function pooledSound(name, info)
	local pool = pools[name]
	if not pool then
		pool = {}
		pools[name] = pool
	end
	-- (alguien pudo destruir uno: fuera de la lista)
	for i = #pool, 1, -1 do
		-- (o se quedó en una cámara que ya no es la actual: sonaría sin oírse)
		local holder = pool[i].Parent
		if holder == nil or (holder ~= workspace and holder ~= workspace.CurrentCamera) then
			table.remove(pool, i)
		end
	end
	local sound = nil
	for _, candidate in pool do
		if candidate.IsPlaying ~= true then
			sound = candidate
			break
		end
	end
	if not sound then
		if #pool >= POOL_SIZE then
			-- (todos sonando: no se corta ninguno; este va aparte, como antes)
			return nil
		end
		sound = Instance.new("Sound")
		sound.SoundId = info.Id
		sound.RollOffMaxDistance = 300
		sound.Parent = workspace.CurrentCamera or workspace
		table.insert(pool, sound)
	end
	-- (como nuevo: sin efectos que le pusiera otro uso, desde el principio)
	for _, child in sound:GetChildren() do
		if child:IsA("SoundEffect") or string.sub(child.ClassName, -11) == "SoundEffect" then
			child:Destroy()
		end
	end
	sound.TimePosition = 0
	return sound
end

-- poolKey (opcional): grupo de reutilización aparte (las armas no comparten estampidos con la interfaz)
function Sounds.Play(name, parent, pitch, volume, poolKey)
	local info = Sounds[name]
	if type(info) ~= "table" then
		return
	end
	local soundName = name
	if info.Variants then
		soundName, info = pickVariant(name, info)
	end
	-- (los sonidos propios de las armas, "W:<arma>:<hueco>", también se reutilizan: suenan en cada disparo)
	local pooled = POOLED[name] or string.sub(name, 1, 2) == "W:"
	local sound = (parent == nil and pooled) and pooledSound(poolKey and (soundName .. "|" .. poolKey) or soundName, info) or nil
	if sound then
		applyRegion(sound, info.Region)
		sound.Volume = info.Volume * (volume or 1)
		sound.PlaybackSpeed = info.Pitch * (pitch or 1) * randomPitch(poolKey)
		sound.SoundGroup = getWorldGroup()
		if sound.Parent == nil then
			sound.Parent = workspace.CurrentCamera or workspace
		end
		sound:Play()
		return sound
	end
	sound = Instance.new("Sound")
	sound.SoundId = info.Id
	sound.Volume = info.Volume * (volume or 1)
	sound.PlaybackSpeed = info.Pitch * (pitch or 1) * randomPitch(poolKey)
	sound.RollOffMaxDistance = 300
	applyRegion(sound, info.Region)
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

-- Impactos de bala en el escenario (Fase 11; antes no sonaban): uno por material, en 3D donde da la
-- bala. Grabaciones de Pro Sound Effects; Region quita el silencio del principio.
Sounds.Impacts = {
	Stone = { -- hormigón, ladrillo, asfalto... (y el plástico de los mapas, que hace de pared)
		Variants = {
			{ Id = "rbxassetid://9113632114", Region = { 0.03, 0.7 } },
			{ Id = "rbxassetid://9113632248", Region = { 0.04, 0.7 } },
			{ Id = "rbxassetid://9113632257", Region = { 0.04, 0.7 } },
		},
		Volume = 0.5,
		Pitch = 1,
	},
	Wood = {
		Variants = { { Id = "rbxassetid://9120962381", Region = { 0, 0.2 } }, { Id = "rbxassetid://9120962232", Region = { 0, 0.26 } } },
		Volume = 0.55,
		Pitch = 1,
	},
	Metal = { -- golpe metálico con rebote
		Variants = { { Id = "rbxassetid://9113633916", Region = { 0.13, 0.9 } }, { Id = "rbxassetid://9113633912", Region = { 0.13, 0.9 } } },
		Volume = 0.42,
		Pitch = 1,
	},
	Glass = {
		Variants = { { Id = "rbxassetid://9113631735", Region = { 0, 0.6 } }, { Id = "rbxassetid://9113631722", Region = { 0, 0.6 } } },
		Volume = 0.45,
		Pitch = 1,
	},
	Dirt = {
		Variants = { { Id = "rbxassetid://9118598279", Region = { 0, 0.3 } }, { Id = "rbxassetid://9114087172", Region = { 0, 0.25 } } },
		Volume = 0.55,
		Pitch = 1,
	},
}
Sounds.Impacts.Plastic = Sounds.Impacts.Stone
Sounds.Impacts.Snow = { Variants = Sounds.Impacts.Dirt.Variants, Volume = 0.4, Pitch = 0.85 }
for kind, info in Sounds.Impacts do
	Sounds["Impact" .. kind] = info
end
Sounds.ImpactInterval = 0.05 -- como mucho un impacto cada 50 ms (escopetas y ráfagas no saturan)
local lastImpact = 0
-- Sonido de un impacto de bala en `parent` (una pieza en el punto del impacto). kind = Stone, Wood...
function Sounds.PlayImpact(kind: string, parent: Instance?)
	local now = os.clock()
	if now - lastImpact < Sounds.ImpactInterval then
		return nil
	end
	local name = Sounds.Impacts[kind] and "Impact" .. kind or "ImpactStone"
	lastImpact = now
	local sound = Sounds.Play(name, parent)
	if sound and parent then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 6
		sound.RollOffMaxDistance = 140
	end
	return sound
end

return Sounds
