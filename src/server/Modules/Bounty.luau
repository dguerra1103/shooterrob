-- "SE BUSCA" (GameConfig.Bounty): el jugador en racha lleva una recompensa por su cabeza. Se marca
-- con un cartel sobre la cabeza (los demás lo ven; él no) y quien lo elimine cobra las monedas.
-- El valor queda en el atributo "Bounty" del jugador (los bots lo usan para ir a por él).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local Bounty = {}

local TAG = "BountyTag"
local watched = {} -- jugadores a los que se les vuelve a poner el cartel al cambiar de personaje

local function config()
	return GameConfig.Bounty or {}
end

-- Monedas que vale una racha (0 si aún no llega)
function Bounty.Value(streak)
	local c = config()
	if not c.Enabled or streak < (c.Streak or math.huge) then
		return 0
	end
	return math.min((c.Base or 0) + (c.PerKill or 0) * (streak - c.Streak), c.Max or math.huge)
end

local function removeTag(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local tag = head and head:FindFirstChild(TAG)
	if tag then
		tag:Destroy()
	end
end

-- Cartel sobre la cabeza (lo crea o actualiza el número)
local function showTag(player, value)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local tag = head:FindFirstChild(TAG)
	if not tag then
		tag = Instance.new("BillboardGui")
		tag.Name = TAG
		tag.Size = UDim2.fromOffset(150, 44)
		tag.StudsOffset = Vector3.new(0, 2.8, 0)
		tag.MaxDistance = 140
		tag.LightInfluence = 0
		tag.PlayerToHideFrom = player
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
		frame.BackgroundTransparency = 0.15
		frame.Parent = tag
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 210, 60)
		stroke.Thickness = 2
		stroke.Parent = frame
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 225, 90)
		label.TextStrokeTransparency = 0.3
		label.Parent = frame
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 6)
		padding.PaddingRight = UDim.new(0, 6)
		padding.PaddingTop = UDim.new(0, 3)
		padding.PaddingBottom = UDim.new(0, 3)
		padding.Parent = label
		tag.Parent = head
	end
	local label = tag:FindFirstChild("Text", true)
	if label then
		label.Text = "💰 SE BUSCA · " .. value .. " 🪙"
	end
end

-- Si recibe un personaje nuevo sin haber muerto (rondas de Eliminación, paciente cero de la
-- Infección), sigue buscado: el cartel pasa al personaje nuevo
local function watch(player)
	if watched[player] then
		return
	end
	watched[player] = player.CharacterAdded:Connect(function(character)
		local head = character:WaitForChild("Head", 5)
		local value = player:GetAttribute("Bounty") or 0
		if head and value > 0 and player.Character == character then
			showTag(player, value)
		end
	end)
	player.AncestryChanged:Connect(function()
		if not player.Parent and watched[player] then
			watched[player]:Disconnect()
			watched[player] = nil
		end
	end)
end

-- Tras una baja de `player` con racha `streak`: sube (o pone) su recompensa
function Bounty.OnStreak(player, streak)
	local value = Bounty.Value(streak)
	if value <= 0 then
		return
	end
	watch(player)
	local before = player:GetAttribute("Bounty") or 0
	player:SetAttribute("Bounty", value)
	showTag(player, value)
	if before == 0 then
		Remotes.Notify:FireAllClients("Bounty", "SE BUSCA: " .. player.Name .. " · " .. value .. " 🪙 por su cabeza")
		Remotes.Notify:FireClient(player, "Wanted", value)
	end
end

-- Muere `victim`: devuelve las monedas que valía su cabeza (0 si nada) y le quita la marca
function Bounty.Clear(victim)
	local value = victim:GetAttribute("Bounty") or 0
	victim:SetAttribute("Bounty", nil)
	removeTag(victim)
	return value
end

-- Anuncia quién cobró (o que se perdió) la recompensa
function Bounty.Announce(victimName, value, claimerName)
	if claimerName then
		Remotes.Notify:FireAllClients("Bounty", claimerName .. " cobró la recompensa de " .. victimName .. " (" .. value .. " 🪙)")
	else
		Remotes.Notify:FireAllClients("Bounty", "La recompensa de " .. victimName .. " se ha perdido")
	end
end

-- Nueva ronda: nadie es buscado
function Bounty.Reset(player)
	player:SetAttribute("Bounty", nil)
	removeTag(player)
end

return Bounty
