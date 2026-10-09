-- Armas modeladas en Blender (tools/blender). El juego no puede cargar esa malla sin subirla como
-- recurso, así que cada arma viaja como su descomposición en primitivas (bloques, cuñas y cilindros:
-- Shared/WeaponMeshes/<Arma>) y aquí se funden en una sola pieza por grupo (papel + pieza móvil) con
-- GeometryService. El resultado es la plantilla que WeaponModels ya sabe usar
-- (ReplicatedStorage.WeaponViewModels/<Arma>: Handle con Attachments, piezas con atributo Role para
-- las skins y Piece para las que se mueven).
--
-- Lo hace el SERVIDOR al arrancar: las piezas fundidas se replican a todos como cualquier otra, así
-- que valen para el arma en primera persona, la del personaje, el lobby y la tienda. Mientras no esté
-- lista una plantilla (o si la fusión falla), el juego usa las piezas de siempre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeaponMeshKit = {}

WeaponMeshKit.Folder = "WeaponViewModels"
-- Armas con modelo nuevo (nombre del arma = nombre del módulo de datos y de la plantilla)
WeaponMeshKit.Weapons = { "ARX27", "Specter9", "Signal7", "HavocPump", "VortexBR", "Viper", "TitanLMG", "NovaDrift", "RaptorDMR", "BreachHammer", "GhostlineXR", "NovaLauncher", "HandCannon", "PhantomSidewind" }
-- false = sin fundir (cada primitiva es una pieza: más piezas, mismo aspecto); para depurar
WeaponMeshKit.Union = true

local function setup(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

-- { forma, sx, sy, sz, x, y, z, r00..r22 } → pieza de Roblox
local function primitive(p)
	local part
	if p[1] == "W" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		if p[1] == "C" then
			part.Shape = Enum.PartType.Cylinder
		end
	end
	part.Size = Vector3.new(p[2], p[3], p[4])
	part.CFrame = CFrame.new(p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16])
	setup(part)
	return part
end

local function tag(part, group)
	part:SetAttribute("Role", group.Role)
	if group.Piece then
		part:SetAttribute("Piece", group.Piece)
	end
end

-- Plantilla completa de un arma a partir de su módulo de datos
function WeaponMeshKit.BuildTemplate(data)
	local model = Instance.new("Model")
	model.Name = data.Name
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.1, 0.1, 0.1)
	handle.Transparency = 1
	handle.CFrame = CFrame.identity
	setup(handle)
	handle.Parent = model
	model.PrimaryPart = handle
	for name, position in data.Points do
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.Position = position
		attachment.Parent = handle
	end
	local fused, loose = 0, 0
	for _, group in data.Groups do
		local parts = table.create(#group.Prims)
		for i, prim in group.Prims do
			parts[i] = primitive(prim)
		end
		local pieces = parts
		if WeaponMeshKit.Union and #parts > 1 then
			-- La pieza fundida hereda la orientación de la principal: una sin girar (un bloque recto, o
			-- una semilla diminuta si el grupo no trae ninguno) para que su caja quede alineada con el
			-- arma y no infle las medidas del modelo
			local main
			for i, prim in group.Prims do
				if prim[1] == "B" and prim[8] == 1 and prim[12] == 1 and prim[16] == 1 then
					main = table.remove(parts, i)
					break
				end
			end
			if not main then
				main = Instance.new("Part")
				main.Size = Vector3.new(0.004, 0.004, 0.004)
				main.CFrame = CFrame.new(parts[1].Position)
				setup(main)
			end
			local rest = parts
			parts = table.clone(rest)
			table.insert(parts, main)
			local ok, result = pcall(function()
				return game:GetService("GeometryService"):UnionAsync(main, rest, {
					CollisionFidelity = Enum.CollisionFidelity.Box,
					RenderFidelity = Enum.RenderFidelity.Precise,
					SplitApart = false,
				})
			end)
			if ok and type(result) == "table" and #result >= 1 then
				pieces = result
				for _, part in parts do
					part:Destroy()
				end
				fused += 1
			else
				pieces = parts -- (sin fundir: cada primitiva es una pieza, semilla incluida)
				loose += 1
			end
		end
		for i, part in pieces do
			part.Name = #pieces > 1 and (group.Name .. i) or group.Name
			setup(part)
			if part:IsA("PartOperation") then
				part.UsePartColor = true -- (el color lo pone la skin, como en cualquier pieza)
			end
			tag(part, group)
			part.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
			part.Parent = model
		end
	end
	handle.Anchored = false
	model:SetAttribute("Fused", fused)
	model:SetAttribute("Loose", loose)
	return model
end

-- Crea las plantillas de todas las armas nuevas (servidor, al arrancar; no bloquea: cada arma en su
-- hilo). onDone(nombre, ok, plantilla o error) opcional
function WeaponMeshKit.Init(onDone)
	if RunService:IsClient() and RunService:IsRunning() then
		return -- (las crea el servidor y llegan replicadas)
	end
	local folder = ReplicatedStorage:FindFirstChild(WeaponMeshKit.Folder)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = WeaponMeshKit.Folder
		folder.Parent = ReplicatedStorage
	end
	local meshes = script.Parent:FindFirstChild("WeaponMeshes")
	for _, name in WeaponMeshKit.Weapons do
		if not folder:FindFirstChild(name) then
			task.spawn(function()
				local module = meshes and meshes:FindFirstChild(name)
				local ok, result = pcall(function()
					return WeaponMeshKit.BuildTemplate(require(module))
				end)
				if ok and result then
					result.Parent = folder
				else
					warn("[WeaponMeshKit] " .. name .. " no se ha podido crear (se usan las piezas de siempre): " .. tostring(result))
				end
				if onDone then
					onDone(name, ok, result)
				end
			end)
		end
	end
end

return WeaponMeshKit
