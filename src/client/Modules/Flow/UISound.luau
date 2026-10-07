-- UISoundController: todos los sonidos de la interfaz del flujo salen de aquí (ningún botón crea
-- su propio Sound). Un Sound por nombre en SoundService, reutilizado; el "pasar por encima" tiene
-- un mínimo entre reproducciones para no sonar a ametralladora al barrer una lista.
local SoundService = game:GetService("SoundService")

local UISound = {}

-- Sonidos que vienen con Roblox (sin assets propios que subir); el tono y el volumen los adaptan
local DEFS = {
	Hover = { Id = "rbxasset://sounds/button.wav", Volume = 0.12, Pitch = 1.8 },
	Click = { Id = "rbxasset://sounds/button.wav", Volume = 0.45, Pitch = 1.15 },
	Back = { Id = "rbxasset://sounds/button.wav", Volume = 0.4, Pitch = 0.8 },
	Play = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.55, Pitch = 0.75 },
	Whoosh = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.35, Pitch = 1.3 },
	MatchFound = { Id = "rbxassetid://3149249837", Volume = 0.55, Pitch = 1.15 },
	MatchFoundPing = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 1.25 },
	Reward = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 1.6 },
	Error = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.5, Pitch = 0.5 },
	Equip = { Id = "rbxassetid://16480568148", Volume = 0.5, Pitch = 1 },
	Countdown = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.45, Pitch = 1 },
	Go = { Id = "rbxassetid://3149249837", Volume = 0.5, Pitch = 1.45 },
	Join = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1.9 },
	Tick = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.25, Pitch = 1.5 },
	-- Pantalla final
	Victory = { Id = "rbxassetid://3149249837", Volume = 0.6, Pitch = 0.85 }, -- impacto grave
	VictorySting = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 1.05 },
	Defeat = { Id = "rbxassetid://3149249837", Volume = 0.32, Pitch = 0.62 }, -- impacto suave
	MVP = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.55, Pitch = 1.5 },
	RewardPop = { Id = "rbxasset://sounds/button.wav", Volume = 0.4, Pitch = 1.6 },
	LevelUp = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 0.75 },
	Unlock = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.4, Pitch = 1.6 },
	-- Tienda
	Purchase = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 1.3 },
	Claim = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 1.45 },
}
UISound.Defs = DEFS

-- Audio propio de la interfaz (Fase 4). TODO: AÑADIR AUDIO PROPIO (grabado o con licencia; nunca
-- sacado de otros juegos). Pon aquí "rbxassetid://<id>" para sustituir el sonido genérico de ese
-- nombre; vacío = el de arriba. Con sonido propio no se cambia el tono (se grabó así).
UISound.Custom = {
	Hover = "",
	Click = "",
	Back = "",
	Play = "",
	MatchFound = "",
	Countdown = "",
	Go = "",
	Reward = "",
	Equip = "",
	Purchase = "",
	Error = "",
	Victory = "",
	Defeat = "",
	LevelUp = "",
}
local function customId(name)
	local id = UISound.Custom[name]
	return type(id) == "string" and id ~= "" and id or nil
end

local sounds = {}
local lastPlayed = {}
local MIN_GAP = { Hover = 0.06, Tick = 0.04 }

local function get(name)
	local sound = sounds[name]
	if sound and sound.Parent then
		return sound
	end
	local def = DEFS[name]
	if not def then
		return nil
	end
	sound = Instance.new("Sound")
	sound.Name = "UI_" .. name
	sound.SoundId = customId(name) or def.Id
	sound.Volume = def.Volume
	sound.PlaybackSpeed = def.Pitch
	sound.Parent = SoundService
	sounds[name] = sound
	return sound
end

-- pitch: multiplicador opcional (la cuenta atrás sube de tono en cada número)
function UISound.Play(name, pitch, volume)
	local def = DEFS[name]
	if not def then
		return
	end
	local now = os.clock()
	local gap = MIN_GAP[name]
	if gap and lastPlayed[name] and now - lastPlayed[name] < gap then
		return
	end
	lastPlayed[name] = now
	local sound = get(name)
	if not sound then
		return
	end
	sound.PlaybackSpeed = customId(name) and (pitch or 1) or def.Pitch * (pitch or 1)
	sound.Volume = def.Volume * (volume or 1)
	sound.TimePosition = 0
	sound:Play()
	return sound
end

-- Sonido compuesto (golpe + campanilla): partida encontrada
function UISound.MatchFound()
	UISound.Play("MatchFound")
	UISound.Play("MatchFoundPing")
end

-- Los ids que conviene precargar en el arranque
function UISound.Assets()
	local list = {}
	for _, name in { "Click", "Hover", "Play", "MatchFound", "MatchFoundPing", "Countdown", "Go" } do
		local sound = get(name)
		if sound then
			table.insert(list, sound)
		end
	end
	return list
end

return UISound
