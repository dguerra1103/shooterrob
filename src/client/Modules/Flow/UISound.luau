-- UISoundController: todos los sonidos de la interfaz del flujo salen de aquí (ningún botón crea
-- su propio Sound). Un Sound por nombre en SoundService, reutilizado; el "pasar por encima" tiene
-- un mínimo entre reproducciones para no sonar a ametralladora al barrer una lista.
local SoundService = game:GetService("SoundService")

local UISound = {}

-- Sonidos de Roblox: los de interfaz son el set oficial de Roblox (RBLX UI / Roblox GUI / Roblox_UI,
-- creador Roblox, dominio público; comprobados con la API de Roblox en la Fase 11). Los volúmenes
-- compensan que unos están grabados más altos que otros. El tono y el volumen los adaptan.
local DEFS = {
	Hover = { Id = "rbxassetid://10066942189", Volume = 0.3, Pitch = 1 }, -- RBLX UI Hover 03
	Click = { Id = "rbxassetid://15675059323", Volume = 0.32, Pitch = 1 }, -- Roblox_UI_Bright_Click
	Back = { Id = "rbxassetid://10066914500", Volume = 0.75, Pitch = 1 }, -- RBLX UI Back
	Play = { Id = "rbxassetid://10128760939", Volume = 0.85, Pitch = 1 }, -- RBLX UI Select 01
	Whoosh = { Id = "rbxassetid://15675012262", Volume = 0.28, Pitch = 1 }, -- Roblox_UI_Whoosh_04
	MatchFound = { Id = "rbxassetid://3149249837", Volume = 0.55, Pitch = 1.15 },
	MatchFoundPing = { Id = "rbxassetid://17208361335", Volume = 0.4, Pitch = 1 }, -- Roblox GUI - Notification High
	Reward = { Id = "rbxassetid://17208361335", Volume = 0.32, Pitch = 1.08 },
	Error = { Id = "rbxassetid://15675075163", Volume = 0.3, Pitch = 1 }, -- Roblox_UI_Delete
	Equip = { Id = "rbxassetid://17208323435", Volume = 0.38, Pitch = 1 }, -- Roblox GUI - Equip
	Countdown = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.45, Pitch = 1 },
	Go = { Id = "rbxassetid://3149249837", Volume = 0.5, Pitch = 1.45 },
	Join = { Id = "rbxassetid://10066968815", Volume = 0.6, Pitch = 1 }, -- RBLX UI Select 02
	Tick = { Id = "rbxassetid://15675032796", Volume = 0.18, Pitch = 1.1 }, -- Roblox_UI_Small_Click
	-- Pantalla final
	Victory = { Id = "rbxassetid://3149249837", Volume = 0.6, Pitch = 0.85 }, -- impacto grave
	VictorySting = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 1.05 },
	Defeat = { Id = "rbxassetid://3149249837", Volume = 0.32, Pitch = 0.62 }, -- impacto suave
	MVP = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.55, Pitch = 1.5 },
	RewardPop = { Id = "rbxassetid://15675032796", Volume = 0.32, Pitch = 1.2 },
	LevelUp = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 0.75 },
	Unlock = { Id = "rbxasset://sounds/swordlunge.wav", Volume = 0.4, Pitch = 1.6 },
	-- Tienda
	Purchase = { Id = "rbxassetid://10066947742", Volume = 0.55, Pitch = 1 }, -- RBLX UI Purchase
	Claim = { Id = "rbxassetid://17208361335", Volume = 0.35, Pitch = 1.15 },
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
