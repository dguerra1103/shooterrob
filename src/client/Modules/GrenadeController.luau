-- Granada en el cliente: tecla G (L1 en mando, botón en móvil), indicador de recarga y explosiones.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local Effects = require(script.Parent.Effects)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local GrenadeController = {}

local DEF = Weapons.Grenade

local widget, label, fill

local function readyAt()
	return player:GetAttribute("GrenadeReadyAt") or 0
end

local function canThrow()
	if ClientState.IsBlocked() or ClientState.Frozen() or ReplicatedStorage:GetAttribute("Mode") == "GUN" then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and workspace:GetServerTimeNow() >= readyAt()
end

local function throw()
	if not canThrow() then
		return
	end
	-- Un poco hacia arriba para que la parábola llegue más lejos
	local direction = (camera.CFrame.LookVector + Vector3.new(0, 0.12, 0)).Unit
	Remotes.ThrowGrenade:FireServer(direction)
	Sounds.Play("Swing", nil, 0.8, 1)
end

local function updateWidget()
	local gunGame = ReplicatedStorage:GetAttribute("Mode") == "GUN"
	widget.Visible = not ClientState.InMainMenu and not gunGame
	if not widget.Visible then
		return
	end
	local left = readyAt() - workspace:GetServerTimeNow()
	if left <= 0 then
		label.Text = "💣 G"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(255, 90, 40)
	else
		label.Text = "💣 " .. math.ceil(left)
		label.TextColor3 = Color3.fromRGB(190, 190, 200)
		fill.Size = UDim2.fromScale(1 - left / DEF.Cooldown, 1)
		fill.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	end
end

function GrenadeController.Init()
	local gui = UI.new("ScreenGui", {
		Name = "Grenade",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Parent = player:WaitForChild("PlayerGui"),
	})
	widget = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -150),
		Size = UDim2.fromOffset(84, 34),
		BackgroundColor3 = Color3.fromRGB(20, 22, 34),
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, { UI.corner(10), UI.stroke(Color3.fromRGB(255, 120, 60), 2, 0.3) })
	fill = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.55,
		Parent = widget,
	}, { UI.corner(10) })
	label = UI.label({ Size = UDim2.fromScale(1, 1), Text = "💣 G", TextSize = 20, ZIndex = 2, Parent = widget })

	ContextActionService:BindAction("Grenade", function(_, state)
		if state == Enum.UserInputState.Begin then
			throw()
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.G, Enum.KeyCode.ButtonL1)
	ContextActionService:SetTitle("Grenade", "💣")
	ContextActionService:SetPosition("Grenade", UDim2.new(1, -200, 1, -270))

	Remotes.ExplosionFX.OnClientEvent:Connect(function(position, radius)
		if typeof(position) == "Vector3" then
			Effects.Explosion(position, type(radius) == "number" and radius or 14)
			-- Sonido en el punto de la explosión (se oye más fuerte cuanto más cerca)
			local spot = Instance.new("Attachment")
			spot.WorldPosition = position
			spot.Parent = workspace.Terrain
			Sounds.Play("ShotHeavy", spot, 0.45, 1.6)
			Debris:AddItem(spot, 5)
		end
	end)

	RunService.Heartbeat:Connect(updateWidget)
end

return GrenadeController
