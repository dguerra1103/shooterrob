-- Modo Captura la bandera.
-- Cada equipo tiene una bandera en su base. Coge la enemiga (acércate a ella) y llévala a tu base
-- mientras tu bandera siga allí para puntuar. Si matan al portador la bandera cae al suelo:
-- sus dueños la devuelven tocándola y si nadie la toca vuelve sola.
--
-- Estado publicado en ReplicatedStorage para la interfaz:
--   FlagState_<Equipo>   = "Home" | "Carried" | "Dropped"
--   FlagCarrier_<Equipo> = nombre del portador ("" si nadie)
-- y en el jugador: atributo CarryingFlag = true/false
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local PlayerData = require(script.Parent.PlayerData)

local Flags = {}

-- Asignado por Round: function(player, team) que suma el punto
Flags.OnCapture = nil

local SETTINGS = GameConfig.Flag
local POLE_HEIGHT = 8

local folder
local flags = {} -- [teamName] = flag
local active = false
local heartbeat

local function findBases()
	local bases = {}
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name == "FlagBase" then
			local team = inst:GetAttribute("Team")
			if type(team) == "string" then
				bases[team] = inst
			end
		end
	end
	return bases
end

-- ¿El mapa tiene una base para cada equipo?
function Flags.IsAvailable()
	local bases = findBases()
	for _, cfg in GameConfig.Teams do
		if not bases[cfg.Name] then
			return false
		end
	end
	return true
end

local function publish(flag)
	ReplicatedStorage:SetAttribute("FlagState_" .. flag.Team.Name, flag.State)
	ReplicatedStorage:SetAttribute("FlagCarrier_" .. flag.Team.Name, flag.Carrier and flag.Carrier.Name or "")
	local text = "BANDERA " .. string.upper(flag.Team.Name)
	if flag.State == "Carried" then
		text ..= "\n¡ROBADA!"
	elseif flag.State == "Dropped" then
		text ..= "\nCAÍDA"
	end
	flag.Label.Text = text
end

local function buildFlag(team)
	local model = Instance.new("Model")
	model.Name = "Flag_" .. team.Name

	local function part(name, size, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material
		p.Shape = shape or Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false -- no bloquea disparos
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.Parent = model
		return p
	end

	local pole = part("Pole", Vector3.new(0.3, POLE_HEIGHT, 0.3), Color3.fromRGB(220, 220, 225), Enum.Material.Metal)
	local cloth = part("Cloth", Vector3.new(0.15, 2.4, 3.6), team.TeamColor.Color, Enum.Material.Neon)
	cloth.CFrame = pole.CFrame * CFrame.new(0, POLE_HEIGHT / 2 - 1.4, 1.8)
	local tip = part("Tip", Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(255, 200, 40), Enum.Material.Neon, Enum.PartType.Ball)
	tip.CFrame = pole.CFrame * CFrame.new(0, POLE_HEIGHT / 2 + 0.3, 0)
	for _, p in { cloth, tip } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = pole
		weld.Part1 = p
		weld.Parent = p
	end
	model.PrimaryPart = pole

	local light = Instance.new("PointLight")
	light.Color = team.TeamColor.Color
	light.Range = 14
	light.Brightness = 2
	light.Parent = cloth

	-- Destellos del color del equipo
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(team.TeamColor.Color, Color3.new(1, 1, 1))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Speed = NumberRange.new(0.5, 1.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rate = 8
	sparkles.Parent = cloth

	-- Marcador visible a través de las paredes
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Marker"
	billboard.Size = UDim2.fromOffset(160, 56)
	billboard.StudsOffset = Vector3.new(0, POLE_HEIGHT / 2 + 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 1000
	billboard.Parent = pole
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 18
	label.TextColor3 = team.TeamColor.Color:Lerp(Color3.new(1, 1, 1), 0.25)
	label.TextStrokeTransparency = 0.2
	label.Text = ""
	label.Parent = billboard

	model.Parent = folder
	return model, label
end

local function setAnchored(flag, anchored)
	for _, p in flag.Model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = anchored
		end
	end
end

-- Coloca la bandera de pie en una posición del suelo
local function placeAt(flag, groundPosition)
	if flag.Weld then
		flag.Weld:Destroy()
		flag.Weld = nil
	end
	setAnchored(flag, true)
	flag.Model:PivotTo(CFrame.new(groundPosition + Vector3.new(0, POLE_HEIGHT / 2, 0)))
	flag.Position = groundPosition
end

local function homePosition(flag)
	-- Superficie de la base (sirve para piezas giradas o cilindros)
	return flag.Base.Position + Vector3.new(0, flag.Base.ExtentsSize.Y / 2, 0)
end

-- ¿El personaje (su HumanoidRootPart) está junto a un punto del suelo?
local function isNear(rootPosition, groundPosition, radius)
	local offset = rootPosition - groundPosition
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius and offset.Y > -2 and offset.Y < 8
end

local function setCarrier(flag, player)
	if flag.Carrier then
		flag.Carrier:SetAttribute("CarryingFlag", false)
	end
	flag.Carrier = player
	if player then
		player:SetAttribute("CarryingFlag", true)
	end
end

local function returnHome(flag, returner, silent)
	setCarrier(flag, nil)
	flag.State = "Home"
	flag.CarrierHumanoid = nil
	placeAt(flag, homePosition(flag))
	publish(flag)
	if silent then
		return
	elseif returner then
		Remotes.Notify:FireAllClients("Flag", returner.Name .. " devolvió la bandera " .. flag.Team.Name)
		PlayerData.AddXP(returner, GameConfig.XP.FlagReturn, "Bandera devuelta")
	else
		Remotes.Notify:FireAllClients("Flag", "La bandera " .. flag.Team.Name .. " volvió a su base")
	end
end

local function groundBelow(position, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local result = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), params)
	return result and result.Position or position - Vector3.new(0, 3, 0)
end

local function drop(flag)
	local carrier = flag.Carrier
	local humanoid = flag.CarrierHumanoid
	local root = flag.Model.PrimaryPart
	local ignore = { folder }
	if carrier and carrier.Character then
		table.insert(ignore, carrier.Character)
	end
	local position = groundBelow(flag.LastCarrierPosition or root.Position, ignore)

	-- Recompensa a quien eliminó al portador
	if humanoid then
		local attackerId = humanoid:GetAttribute("LastAttacker")
		local hitTime = humanoid:GetAttribute("LastHitTime")
		local killer = attackerId and Players:GetPlayerByUserId(attackerId)
		if killer and hitTime and os.clock() - hitTime < 10 and humanoid.Health <= 0 then
			PlayerData.AddXP(killer, GameConfig.XP.CarrierKill, "Portador eliminado")
		end
	end

	setCarrier(flag, nil)
	flag.CarrierHumanoid = nil
	flag.State = "Dropped"
	flag.DroppedAt = os.clock()
	placeAt(flag, position)
	publish(flag)
	Remotes.Notify:FireAllClients("Flag", "¡La bandera " .. flag.Team.Name .. " ha caído!")
end

local function pickup(flag, player, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	setCarrier(flag, player)
	flag.CarrierHumanoid = character:FindFirstChildOfClass("Humanoid")
	flag.State = "Carried"
	flag.LastCarrierPosition = root.Position

	-- Soldada a la espalda del portador
	setAnchored(flag, false)
	flag.Model:PivotTo(root.CFrame * CFrame.new(0, 1.2, 1) * CFrame.Angles(math.rad(-15), 0, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = flag.Model.PrimaryPart
	weld.Parent = flag.Model.PrimaryPart
	flag.Weld = weld

	publish(flag)
	Remotes.Notify:FireAllClients("Flag", player.Name .. " tiene la bandera " .. flag.Team.Name .. "!")
end

local function capture(flag, player)
	local team = player.Team
	returnHome(flag, nil, true)
	Remotes.Notify:FireAllClients("Big", "¡" .. player.Name .. " CAPTURÓ LA BANDERA!")
	PlayerData.AddXP(player, GameConfig.XP.Capture, "Captura")
	PlayerData.AddCoins(player, GameConfig.Coins.Capture)
	player:SetAttribute("Captures", (player:GetAttribute("Captures") or 0) + 1)
	if Flags.OnCapture then
		Flags.OnCapture(player, team)
	end
end

local function aliveCharacter(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, root
	end
	return nil, nil
end

local function isCarrying(player)
	for _, flag in flags do
		if flag.Carrier == player then
			return true
		end
	end
	return false
end

local lastTick = 0
local function step()
	if not active or os.clock() - lastTick < 0.1 then
		return
	end
	lastTick = os.clock()

	for _, flag in flags do
		if flag.State == "Carried" then
			local carrier = flag.Carrier
			local character, root = nil, nil
			if carrier and carrier.Parent then
				character, root = aliveCharacter(carrier)
			end
			if
				not character
				or flag.CarrierHumanoid == nil
				or character:FindFirstChildOfClass("Humanoid") ~= flag.CarrierHumanoid
				or carrier.Team == flag.Team
			then
				drop(flag)
			else
				flag.LastCarrierPosition = root.Position
				-- ¿Ha llegado a su base con su propia bandera en casa?
				local ownFlag = carrier.Team and flags[carrier.Team.Name]
				if
					ownFlag
					and ownFlag.State == "Home"
					and isNear(root.Position, homePosition(ownFlag), SETTINGS.CaptureRadius)
				then
					capture(flag, carrier)
				end
			end
		else
			if flag.State == "Dropped" and os.clock() - flag.DroppedAt >= SETTINGS.AutoReturnTime then
				returnHome(flag, nil)
			end
			for _, player in Players:GetPlayers() do
				if player.Team and flag.State ~= "Carried" then
					local character, root = aliveCharacter(player)
					if character and isNear(root.Position, flag.Position, SETTINGS.PickupRadius) then
						if player.Team == flag.Team then
							if flag.State == "Dropped" then
								returnHome(flag, player)
							end
						elseif not isCarrying(player) then
							pickup(flag, player, character)
						end
					end
				end
			end
		end
	end
end

-- Crea las banderas en sus bases (inicio de una ronda de CTF)
function Flags.Start()
	Flags.Stop()
	local bases = findBases()
	folder = Instance.new("Folder")
	folder.Name = "Flags"
	folder.Parent = workspace
	for _, team in Teams:GetTeams() do
		local base = bases[team.Name]
		if base then
			local flag = { Team = team, Base = base, State = "Home" }
			flag.Model, flag.Label = buildFlag(team)
			placeAt(flag, homePosition(flag))
			flags[team.Name] = flag
			publish(flag)
		end
	end
	active = true
	heartbeat = RunService.Heartbeat:Connect(step)
end

-- Quita las banderas (fin de la ronda)
function Flags.Stop()
	active = false
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	for teamName, flag in flags do
		setCarrier(flag, nil)
		ReplicatedStorage:SetAttribute("FlagState_" .. teamName, nil)
		ReplicatedStorage:SetAttribute("FlagCarrier_" .. teamName, nil)
	end
	table.clear(flags)
	if folder then
		folder:Destroy()
		folder = nil
	end
	for _, player in Players:GetPlayers() do
		player:SetAttribute("CarryingFlag", false)
	end
end

return Flags
