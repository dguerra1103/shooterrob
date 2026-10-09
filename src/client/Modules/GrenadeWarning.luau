-- Aviso de granada cercana (como en los shooters): cuando una granada enemiga cae cerca, sale un
-- icono de granada (dibujado, Fase 17: sin emoji) alrededor de la mira, en la dirección en la que está, más rojo cuanto más cerca.
-- No avisa de las tuyas ni de las de tu equipo (no te hacen daño).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)

local UI = require(script.Parent.UI)
local TouchIcons = require(script.Parent.TouchIcons)
local ClientState = require(script.Parent.ClientState)

local GrenadeWarning = {}

local MAX_ICONS = 3
local RING = 110 -- píxeles desde el centro de la pantalla

local player = Players.LocalPlayer
local gui
local icons = {}

local function warnRadius()
	local def = Weapons.Grenade
	return ((def and def.Explosive and def.Explosive.Radius) or 16) + 4
end

local function isThreat(grenade)
	if grenade:GetAttribute("Thrower") == player.Name then
		return false
	end
	if ReplicatedStorage:GetAttribute("TeamMode") == false then
		return true
	end
	local team = grenade:GetAttribute("Team")
	return team == nil or team == "" or player.Team == nil or team ~= player.Team.Name
end

local function makeIcon()
	local icon = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		TextSize = 26,
		BackgroundColor3 = Color3.fromRGB(200, 30, 30),
		BackgroundTransparency = 0.25,
		Visible = false,
		Parent = gui,
	}, { UI.corner(22), UI.stroke(Color3.fromRGB(255, 230, 200), 2, 0.1) })
	-- (la granada dibujada con las mismas piezas que el botón de granada)
	local glyph = Instance.new("Frame")
	glyph.Name = "Glyph"
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromScale(0.58, 0.58)
	glyph.BackgroundTransparency = 1
	glyph.Parent = icon
	TouchIcons.Draw("Grenade", glyph, 26)
	TouchIcons.Tint(glyph, Color3.new(1, 1, 1))
	return icon
end

local function update()
	local folder = workspace:FindFirstChild("Grenades")
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local used = 0
	if folder and camera and root and humanoid and humanoid.Health > 0 and not ClientState.InMainMenu then
		local radius = warnRadius()
		local viewport = camera.ViewportSize
		local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
		for _, grenade in folder:GetChildren() do
			if used >= MAX_ICONS then
				break
			end
			if grenade:IsA("BasePart") and isThreat(grenade) then
				local distance = (grenade.Position - root.Position).Magnitude
				if distance < radius then
					used += 1
					local icon = icons[used]
					-- Dirección de la granada vista desde la cámara (en el plano: delante = arriba)
					local relative = camera.CFrame:PointToObjectSpace(grenade.Position)
					local flat = Vector2.new(relative.X, relative.Z)
					local angle = flat.Magnitude > 0.01 and math.atan2(flat.X, -flat.Y) or 0
					local position = center + Vector2.new(math.sin(angle), -math.cos(angle)) * RING
					icon.Position = UDim2.fromOffset(position.X, position.Y)
					local danger = 1 - distance / radius
					icon.BackgroundTransparency = 0.6 - 0.45 * danger
					icon.Size = UDim2.fromOffset(38 + 14 * danger, 38 + 14 * danger)
					icon.Visible = true
				end
			end
		end
	end
	for i = used + 1, MAX_ICONS do
		icons[i].Visible = false
	end
end

function GrenadeWarning.Init()
	gui = UI.new("ScreenGui", {
		Name = "GrenadeWarning",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 3,
		Parent = player:WaitForChild("PlayerGui"),
	})
	for i = 1, MAX_ICONS do
		icons[i] = makeIcon()
	end
	RunService.Heartbeat:Connect(update)
end

GrenadeWarning.Update = update
return GrenadeWarning
