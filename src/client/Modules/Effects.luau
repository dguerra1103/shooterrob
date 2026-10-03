-- Efectos visuales: trazadoras, impactos y fogonazos.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Effects = {}

local folder = Instance.new("Folder")
folder.Name = "ClientFX"
folder.Parent = workspace

local function fxPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	for key, value in props do
		part[key] = value
	end
	part.Parent = folder
	return part
end

function Effects.Tracer(from, to, color)
	local distance = (to - from).Magnitude
	if distance < 0.5 then
		return
	end
	local part = fxPart({
		Color = color or Color3.fromRGB(255, 230, 120),
		Size = Vector3.new(0.07, 0.07, distance),
		CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2),
		Transparency = 0.2,
	})
	TweenService:Create(part, TweenInfo.new(0.12), { Transparency = 1, Size = Vector3.new(0.02, 0.02, distance) }):Play()
	Debris:AddItem(part, 0.15)
end

function Effects.Impact(position, normal, hitPart)
	local isCharacter = hitPart and hitPart.Parent and hitPart.Parent:FindFirstChildOfClass("Humanoid") ~= nil
	local color = isCharacter and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 240, 200)
	local part = fxPart({
		Color = color,
		Size = Vector3.new(0.45, 0.45, 0.05),
		CFrame = CFrame.lookAt(position, position + (normal or Vector3.yAxis)),
		Shape = Enum.PartType.Block,
	})
	TweenService:Create(part, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.9, 0.9, 0.02) }):Play()
	Debris:AddItem(part, 0.3)

	if not isCharacter and hitPart then
		local mark = fxPart({
			Color = Color3.fromRGB(30, 30, 30),
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.new(0.25, 0.25, 0.02),
			CFrame = CFrame.lookAt(position, position + (normal or Vector3.yAxis)),
			Transparency = 0.2,
		})
		TweenService:Create(mark, TweenInfo.new(4, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
		Debris:AddItem(mark, 4.2)
	end
end

function Effects.MuzzleFlash(attachment)
	if not attachment then
		return
	end
	local flash = fxPart({
		Color = Color3.fromRGB(255, 210, 90),
		Size = Vector3.new(0.35, 0.35, 0.6),
		CFrame = attachment.WorldCFrame * CFrame.Angles(0, 0, math.random() * math.pi),
		Transparency = 0.1,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 100)
	light.Range = 10
	light.Brightness = 3
	light.Parent = flash
	Debris:AddItem(flash, 0.05)
end

return Effects
