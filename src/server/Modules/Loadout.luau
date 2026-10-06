-- Entrega las armas (Tools) a cada jugador cuando aparece.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weapons = require(Shared.Weapons)
local WeaponModels = require(Shared.WeaponModels)
local Remotes = require(Shared.Remotes)
local Outfits = require(Shared.Outfits)
local GameConfig = require(Shared.GameConfig)

local PlayerData = require(script.Parent.PlayerData)

local Loadout = {}

-- Los modos de juego pueden cambiar las armas: function(player) -> { "Arma1", "Arma2", ... } o nil
Loadout.Override = nil

function Loadout.MakeTool(weaponName, skinId, charmId)
	local def = Weapons.Get(weaponName)
	local tool = Instance.new("Tool")
	tool.Name = def.DisplayName
	tool.ToolTip = def.DisplayName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	-- La mano derecha agarra la empuñadura del arma. El arma del mundo va a escala de una persona (la de
	-- primera persona, el viewmodel, se construye aparte a tamaño completo)
	local scale = GameConfig.WorldWeaponScale or 1
	tool.Grip = CFrame.new((def.RightHand or Vector3.zero) * scale)
	tool:SetAttribute("WorldScale", scale)
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

	local model = WeaponModels.Build(weaponName, skinId, nil, charmId, scale)
	tool:SetAttribute("Charm", charmId or "Default")
	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()
	return tool
end

-- Sin traje comprado, en los mapas realistas: uniforme militar con el color del equipo en el
-- brazalete (como los bots), salvo que el jugador prefiera su avatar (Ajustes → Uniforme). nil = nada
function Loadout.UniformFor(player, data)
	local map = workspace:FindFirstChild("Map")
	if GameConfig.SoldierUniform == false or not map or map:GetAttribute("Realistic") ~= true then
		return nil
	end
	local settings = data and data.Settings
	if type(settings) == "table" and settings.Uniform == 0 then
		return nil
	end
	return Outfits.Soldier(player.Team and player.Team.TeamColor.Color or nil)
end

local function giveLoadout(player, character)
	local data = PlayerData.WaitFor(player, 15)
	if player.Character ~= character then
		return
	end
	local list = Loadout.Override and Loadout.Override(player) or Loadout.DefaultList(data)

	-- Traje de operador (solo R15)
	-- (los zombis de la Infección no llevan traje: taparía la piel verde y los ojos)
	local zombie = ReplicatedStorage:GetAttribute("Infection") == "On" and player.Team ~= nil
		and player.Team.Name == ReplicatedStorage:GetAttribute("TeamB")
	local outfit = nil
	if data and data.EquippedOutfit ~= "Default" and not zombie then
		outfit = data.EquippedOutfit
	elseif not zombie then
		outfit = Loadout.UniformFor(player, data)
	end
	if outfit then
		character:WaitForChild("UpperTorso", 5)
		-- Espera a que cargue la ropa del avatar: si no, sus BodyColors y camisa taparían el traje
		local started = os.clock()
		while not player:HasAppearanceLoaded() and os.clock() - started < 5 do
			task.wait(0.1)
		end
		if player.Character ~= character then
			return
		end
		Outfits.Apply(character, outfit)
	end

	Loadout.Give(player, list)
end

-- Armas elegidas por el jugador (principal, secundaria y cuchillo)
function Loadout.DefaultList(data)
	local primary = data and data.Primary or "ARX27"
	local secondary = data and data.Secondary or Weapons.Secondary
	local melee = data and data.Melee or Weapons.Melee
	return { primary, secondary, melee }
end

-- Devuelve sus armas de siempre a un jugador vivo (por ejemplo al acabar la Escalada)
function Loadout.GiveDefault(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		Loadout.Give(player, Loadout.DefaultList(PlayerData.Get(player)))
	end
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
			local tool = Loadout.MakeTool(weaponName, PlayerData.SkinFor(data, weaponName), data and data.EquippedCharm)
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
			-- Para quitar el traje del todo hay que reaparecer (recupera la ropa original); en los mapas
			-- realistas, en su lugar el uniforme
			local uniform = Loadout.UniformFor(player, PlayerData.Get(player))
			if uniform then
				Outfits.Apply(character, uniform)
			else
				Outfits.Remove(character)
			end
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

local spawnedAt = {} -- [player] = os.clock() de su última aparición

-- En plena ronda de Eliminación, quien no la empezó (y ya salió del menú) entra como espectador hasta
-- la siguiente: si no, podría aparecer de refresco a mitad de ronda. No cuenta como muerte.
local function makeSpectatorIfLate(player, character)
	if not ReplicatedStorage:GetAttribute("NoRespawn") or player:GetAttribute("ElimIn") or player:GetAttribute("InMenu") then
		return
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:SetAttribute("Spectator", true)
		humanoid.Health = 0
	end
end

local joinOrder = 0
local function onPlayer(player)
	player:SetAttribute("InMenu", true)
	-- Orden de llegada al servidor (el primero de una escuadra es su líder en la interfaz)
	joinOrder += 1
	player:SetAttribute("JoinOrder", joinOrder)
	player.CharacterAdded:Connect(function(character)
		spawnedAt[player] = os.clock()
		addMenuShield(player, character)
		-- (personaje que llega tarde a una ronda de Eliminación ya empezada)
		task.defer(function()
			character:WaitForChild("Humanoid", 5)
			makeSpectatorIfLate(player, character)
		end)
		giveLoadout(player, character)
	end)
	if player.Character then
		addMenuShield(player, player.Character)
		task.spawn(giveLoadout, player, player.Character)
	end
end

-- Clase elegida: en el menú o durante el despliegue antes de la partida se cambian las armas ya
-- mismo; en plena partida, al reaparecer
local function onClassApplied(player)
	local data = PlayerData.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local deploying = ReplicatedStorage:GetAttribute("Deploy") ~= nil
	if humanoid and humanoid.Health > 0 and (player:GetAttribute("InMenu") or deploying) and not Loadout.Override then
		Loadout.Give(player, Loadout.DefaultList(data))
	elseif not player:GetAttribute("InMenu") then
		Remotes.Notify:FireClient(player, "Info", "Clase equipada (al reaparecer)")
	end
end

function Loadout.Init()
	PlayerData.OnClassApplied = onClassApplied
	PlayerData.OnSkinChanged = onSkinChanged
	PlayerData.OnOutfitChanged = onOutfitChanged
	-- "Volver al menú": vuelve a ser invulnerable y queda fuera de los objetivos
	Remotes.EnterMenu.OnServerEvent:Connect(function(player)
		-- Solo desde la pantalla de muerte: si no, cualquiera podría volverse invulnerable en plena pelea
		-- (o justo al reaparecer: el clic pudo llegar después de la reaparición automática, y ese
		-- personaje aún tiene la protección de aparición, así que no se gana nada haciendo trampa)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local justSpawned = os.clock() - (spawnedAt[player] or -math.huge) < 1.5
		-- (fuera de la partida, p. ej. en la pantalla final, se puede volver siempre: no hay pelea)
		local playing = ReplicatedStorage:GetAttribute("State") == "Playing"
		if humanoid and humanoid.Health > 0 and not justSpawned and playing then
			return
		end
		player:SetAttribute("InMenu", true)
		player:SetAttribute("Ready", nil)
		if player.Character then
			addMenuShield(player, player.Character)
		end
	end)
	Remotes.LeaveMenu.OnServerEvent:Connect(function(player)
		player:SetAttribute("InMenu", false)
		player:SetAttribute("Ready", nil)
		-- Desde cuándo juega esta partida (para el rango; Round lo pone a cero al empezar cada una)
		if not player:GetAttribute("MatchJoinedAt") then
			player:SetAttribute("MatchJoinedAt", workspace:GetServerTimeNow())
		end
		local shield = player.Character and player.Character:FindFirstChild("MenuShield")
		if shield then
			shield:Destroy()
		end
		-- En plena ronda de Eliminación quien no la empezó entra como espectador hasta la siguiente
		-- (si no, podría aparecer de refresco a mitad de ronda)
		makeSpectatorIfLate(player, player.Character)
	end)
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		spawnedAt[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return Loadout
