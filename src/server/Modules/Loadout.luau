-- Entrega las armas (Tools) a cada jugador cuando aparece.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local WeaponModels = require(Shared.WeaponModels)
local Remotes = require(Shared.Remotes)
local Outfits = require(Shared.Outfits)

local PlayerData = require(script.Parent.PlayerData)

local Loadout = {}

-- Los modos de juego pueden cambiar las armas: function(player) -> { "Arma1", "Arma2", ... } o nil
Loadout.Override = nil

function Loadout.MakeTool(weaponName, skinId)
	local def = Weapons.Get(weaponName)
	local tool = Instance.new("Tool")
	tool.Name = def.DisplayName
	tool.ToolTip = def.DisplayName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	-- La mano derecha agarra la empuñadura del arma
	tool.Grip = CFrame.new(def.RightHand or Vector3.zero)
	tool:SetAttribute("Weapon", weaponName)
	tool:SetAttribute("Skin", skinId)
	tool:SetAttribute("Slot", def.Slot)
	if def.Type == "Gun" then
		tool:SetAttribute("Ammo", def.MagSize)
		tool:SetAttribute("Reserve", def.ReserveAmmo)
		tool:SetAttribute("Reloading", false)
		tool.Unequipped:Connect(function()
			tool:SetAttribute("Reloading", false) -- cambiar de arma cancela la recarga
		end)
	end

	local model = WeaponModels.Build(weaponName, skinId)
	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()
	return tool
end

local function giveLoadout(player, character)
	local data = PlayerData.WaitFor(player, 15)
	if player.Character ~= character then
		return
	end
	local list = Loadout.Override and Loadout.Override(player)
	if not list then
		local primary = data and data.Primary or "ARX27"
		local secondary = data and data.Secondary or Weapons.Secondary
		list = { primary, secondary, Weapons.Melee }
	end

	-- Traje de operador (solo R15)
	if data and data.EquippedOutfit ~= "Default" then
		character:WaitForChild("UpperTorso", 5)
		Outfits.Apply(character, data.EquippedOutfit)
	end

	Loadout.Give(player, list)
end

-- Da al jugador exactamente estas armas (y equipa la primera).
-- Cada arma lleva su camuflaje de maestría si lo tiene elegido, o la skin general.
function Loadout.Give(player, list)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not backpack then
		return
	end
	local data = PlayerData.Get(player)
	for _, container in { backpack, character } do
		for _, child in container:GetChildren() do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end
	local first
	for _, weaponName in list do
		if Weapons.Get(weaponName) then
			local tool = Loadout.MakeTool(weaponName, PlayerData.SkinFor(data, weaponName))
			tool.Parent = backpack
			first = first or tool
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if first and humanoid and humanoid.Health > 0 then
		humanoid:EquipTool(first)
	end
end

local function onOutfitChanged(player, outfitId)
	local character = player.Character
	if character then
		if outfitId == "Default" then
			-- Para quitar el traje del todo hay que reaparecer (recupera la ropa original)
			Outfits.Remove(character)
		else
			Outfits.Apply(character, outfitId)
		end
	end
end

-- Vuelve a pintar las armas que lleva encima (skin general o camuflaje de maestría)
local function onSkinChanged(player)
	local data = PlayerData.Get(player)
	local containers = { player:FindFirstChild("Backpack"), player.Character }
	for _, container in containers do
		if container then
			for _, tool in container:GetChildren() do
				local weaponName = tool:IsA("Tool") and tool:GetAttribute("Weapon")
				if weaponName then
					local skinId = PlayerData.SkinFor(data, weaponName)
					if tool:GetAttribute("Skin") ~= skinId then
						WeaponModels.ApplySkin(tool, skinId, weaponName)
						tool:SetAttribute("Skin", skinId)
					end
				end
			end
		end
	end
end

-- Mientras el jugador está en la pantalla de inicio es invulnerable (escudo invisible)
local function addMenuShield(player, character)
	if player:GetAttribute("InMenu") and not character:FindFirstChild("MenuShield") then
		local shield = Instance.new("ForceField")
		shield.Name = "MenuShield"
		shield.Visible = false
		shield.Parent = character
	end
end

local function onPlayer(player)
	player:SetAttribute("InMenu", true)
	player.CharacterAdded:Connect(function(character)
		addMenuShield(player, character)
		giveLoadout(player, character)
	end)
	if player.Character then
		addMenuShield(player, player.Character)
		task.spawn(giveLoadout, player, player.Character)
	end
end

function Loadout.Init()
	PlayerData.OnSkinChanged = onSkinChanged
	PlayerData.OnOutfitChanged = onOutfitChanged
	Remotes.LeaveMenu.OnServerEvent:Connect(function(player)
		player:SetAttribute("InMenu", false)
		local shield = player.Character and player.Character:FindFirstChild("MenuShield")
		if shield then
			shield:Destroy()
		end
	end)
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return Loadout
