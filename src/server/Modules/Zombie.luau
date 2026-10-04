-- Aspecto y vida de los zombis del modo Infección (jugadores y bots): piel verde, ojos rojos
-- brillantes y más vida. Las garras y la velocidad vienen del arma (Weapons.Claws).
local Zombie = {}

Zombie.Skin = Color3.fromRGB(110, 165, 80)
local EYE = Color3.fromRGB(255, 40, 30)
local SKIN_PARTS = {
	"Head",
	"LeftHand",
	"RightHand",
	"LeftLowerArm",
	"RightLowerArm",
	"LeftUpperArm",
	"RightUpperArm",
	"Left Arm",
	"Right Arm",
}

local function eye(head, x)
	local part = Instance.new("Part")
	part.Name = "ZombieEye"
	part.Size = Vector3.new(0.2, 0.12, 0.05)
	part.Color = EYE
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = head.CFrame * CFrame.new(x * head.Size.X, head.Size.Y * 0.12, -head.Size.Z * 0.5)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part
	part.Parent = head
end

-- Pinta al personaje de zombi y le da la vida indicada
function Zombie.Apply(character, health)
	character:SetAttribute("Zombie", true)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and health then
		humanoid.MaxHealth = health
		humanoid.Health = health
	end
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors.HeadColor3 = Zombie.Skin
		bodyColors.LeftArmColor3 = Zombie.Skin
		bodyColors.RightArmColor3 = Zombie.Skin
	end
	for _, name in SKIN_PARTS do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = Zombie.Skin
		end
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") and not head:FindFirstChild("ZombieEye") then
		eye(head, -0.17)
		eye(head, 0.17)
	end
end

return Zombie
