-- Entrega las armas (Tools) a cada jugador cuando aparece.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local WeaponModels = require(Shared.WeaponModels)

local PlayerData = require(script.Parent.PlayerData)

local Loadout = {}

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
	local skin = data and data.EquippedSkin or "Default"
	local primary = data and data.Primary or "Rifle"

	local backpack = player:WaitForChild("Backpack")
	backpack:ClearAllChildren()

	local first
	for _, weaponName in { primary, Weapons.Secondary, Weapons.Melee } do
		local tool = Loadout.MakeTool(weaponName, skin)
		tool.Parent = backpack
		first = first or tool
	end

	local humanoid = character:WaitForChild("Humanoid")
	if humanoid.Health > 0 then
		humanoid:EquipTool(first)
	end
end

local function onSkinChanged(player, skinId)
	local containers = { player:FindFirstChild("Backpack"), player.Character }
	for _, container in containers do
		if container then
			for _, tool in container:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("Weapon") then
					WeaponModels.ApplySkin(tool, skinId)
					tool:SetAttribute("Skin", skinId)
				end
			end
		end
	end
end

local function onPlayer(player)
	player.CharacterAdded:Connect(function(character)
		giveLoadout(player, character)
	end)
	if player.Character then
		task.spawn(giveLoadout, player, player.Character)
	end
end

function Loadout.Init()
	PlayerData.OnSkinChanged = onSkinChanged
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return Loadout
