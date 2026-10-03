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
}

-- Reproduce un sonido. Si parent es nil, suena en 2D (para el jugador local).
function Sounds.Play(name, parent)
	local info = Sounds[name]
	if type(info) ~= "table" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = info.Id
	sound.Volume = info.Volume
	sound.PlaybackSpeed = info.Pitch * (0.95 + math.random() * 0.1)
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

return Sounds
