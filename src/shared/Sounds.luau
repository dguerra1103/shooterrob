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
	Infected = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 1, Pitch = 0.4 }, -- golpe grave: ¡zombis!
}

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

-- Sonido de disparo de cada arma: { sonido, tono, volumen }
Sounds.WeaponShots = {
	ARX27 = { "Shot", 0.95, 1 },
	VortexBR = { "Shot", 1.15, 0.9 },
	Specter9 = { "Shot", 1.2, 0.8 },
	NovaDrift = { "Shot", 1.3, 0.75 },
	SplatX = { "Shot", 1.7, 0.6 }, -- "pop" agudo de aire comprimido
	Signal7 = { "ShotHeavy", 0.75, 1.1 },
	GhostlineXR = { "Shot", 0.55, 0.55 }, -- con supresor: grave y apagado
	RaptorDMR = { "ShotHeavy", 1.05, 0.9 },
	HavocPump = { "ShotHeavy", 0.85, 1.1 },
	BreachHammer = { "ShotHeavy", 0.7, 1.2 },
	TitanLMG = { "ShotHeavy", 1.2, 0.7 },
	NovaLauncher = { "ShotHeavy", 0.5, 1.3 },
	Calabazooka = { "ShotHeavy", 0.45, 1.3 },
	Viper = { "Shot", 1.1, 0.8 },
	HandCannon = { "ShotHeavy", 0.9, 1 },
	PhantomSidewind = { "Shot", 1.35, 0.8 },
}

-- Disparo de un arma (con su sonido propio si lo tiene)
function Sounds.PlayShot(weaponName, def, parent)
	local profile = weaponName and Sounds.WeaponShots[weaponName]
	if profile then
		return Sounds.Play(profile[1], parent, profile[2], profile[3])
	end
	local heavy = def ~= nil and (def.Pellets > 1 or def.Damage >= 80)
	return Sounds.Play(heavy and "ShotHeavy" or "Shot", parent)
end

return Sounds
