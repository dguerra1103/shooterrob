-- Etiquetas en el chat: [VIP] dorada para quien tenga el pase VIP y el nivel de cada jugador,
-- con color según el nivel. Solo cambia cómo se ve el mensaje (TextChatService, chat nuevo de Roblox).
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ChatTags = {}

-- Color del nivel: gris, verde, azul, morado y dorado según se sube
local function levelColor(level)
	if level >= 40 then
		return "#FFC83C"
	elseif level >= 25 then
		return "#C064FF"
	elseif level >= 12 then
		return "#4AA8FF"
	elseif level >= 5 then
		return "#6EE06E"
	end
	return "#C8C8D2"
end

local function tagsFor(player)
	local tags = ""
	if player:GetAttribute("VIP") then
		tags ..= '<font color="#FFC83C">[VIP]</font> '
	end
	local stats = player:FindFirstChild("leaderstats")
	local level = stats and stats:FindFirstChild("Nivel")
	if level and typeof(level.Value) == "number" then
		tags ..= string.format('<font color="%s">[Nv %d]</font> ', levelColor(level.Value), level.Value)
	end
	return tags
end

function ChatTags.Init()
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		return -- chat antiguo: no se puede personalizar así
	end
	TextChatService.OnIncomingMessage = function(message)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local player = source and Players:GetPlayerByUserId(source.UserId)
		if player then
			properties.PrefixText = tagsFor(player) .. message.PrefixText
		end
		return properties
	end
end

return ChatTags
