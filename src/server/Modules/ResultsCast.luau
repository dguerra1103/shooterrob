-- Reparto de la pantalla final: al acabar la partida, una copia visual de cada participante (jugadores
-- y bots) en ReplicatedStorage.ResultsCast, para que los clientes monten la escena de resultados con
-- los avatares reales (traje incluido). Se hace JUSTO antes de pasar a "Ended": después los bots se
-- quitan. Las copias no tienen scripts, sonidos ni herramientas (el arma la pone el cliente) y nunca
-- están en el mundo: solo sirven de plantilla. Quien está muerto o sin personaje sale de su
-- HumanoidDescription con su traje. Se borra todo al empezar la siguiente partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Outfits = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Outfits"))

local ResultsCast = {}

local folder

local function getFolder()
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "ResultsCast"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

-- Deja solo lo visual: piezas, uniones, ropa, accesorios y caras
local function sanitize(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") or d:IsA("Sound") or d:IsA("BillboardGui")
			or d:IsA("SurfaceGui") or d:IsA("ForceField") or d:IsA("Tool") or d:IsA("Highlight")
			or d:IsA("BodyMover") or d:IsA("Constraint") and not d:IsA("WeldConstraint") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Anchored = false
		end
	end
	-- (el muñeco de trapo cambia los Motor6D por rótulas: si faltan uniones, mejor no usarlo)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function usable(model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	local torso = model and model:FindFirstChild("UpperTorso")
	local waist = torso and torso:FindFirstChild("Waist")
	return humanoid ~= nil and root ~= nil and humanoid.Health > 0 and waist ~= nil and waist:IsA("Motor6D")
end

local function copy(model)
	local archivable = model.Archivable
	model.Archivable = true
	local ok, clone = pcall(function()
		return model:Clone()
	end)
	model.Archivable = archivable
	if not ok or not clone then
		return nil
	end
	sanitize(clone)
	return clone
end

local function store(id, clone)
	if not clone then
		return
	end
	clone.Name = id
	clone:SetAttribute("CastId", id)
	local old = getFolder():FindFirstChild(id)
	if old then
		old:Destroy()
	end
	clone.Parent = getFolder()
end

-- Avatar de Roblox desde su descripción (para quien estaba muerto al acabar), con su traje
local function fromDescription(id, userId, outfitId)
	task.spawn(function()
		local ok, model = pcall(function()
			local description = Players:GetHumanoidDescriptionFromUserId(userId)
			return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		end)
		if not ok or not model then
			return
		end
		if outfitId and outfitId ~= "Default" then
			pcall(Outfits.Apply, model, outfitId)
		end
		sanitize(model)
		if folder and folder.Parent then
			store(id, model)
		end
	end)
end

-- entries = { { Id, Model = personaje (puede ser nil), UserId?, Outfit? } }
function ResultsCast.Capture(entries)
	ResultsCast.Clear()
	getFolder()
	for _, entry in entries do
		if usable(entry.Model) then
			store(entry.Id, copy(entry.Model))
		elseif entry.UserId and entry.UserId > 0 then
			fromDescription(entry.Id, entry.UserId, entry.Outfit)
		end
	end
end

function ResultsCast.Clear()
	if folder then
		folder:ClearAllChildren()
	end
end

return ResultsCast
