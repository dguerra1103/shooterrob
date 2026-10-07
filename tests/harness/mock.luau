-- Entorno Roblox simulado (mínimo) para ejecutar los constructores de mapas y armas en Lune.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Vector3, CFrame, Color3 = roblox.Vector3, roblox.CFrame, roblox.Color3

local M = {}

local PARENTS = {
	Part = "BasePart",
	SpawnLocation = "Part",
	WedgePart = "BasePart",
	CornerWedgePart = "BasePart",
	TrussPart = "BasePart",
	MeshPart = "BasePart",
	BasePart = "PVInstance",
	Model = "PVInstance",
	Tool = "Model",
	Workspace = "Model",
	PVInstance = "Instance",
	PointLight = "Light",
	SpotLight = "Light",
	SurfaceLight = "Light",
	Light = "Instance",
	TextLabel = "GuiObject",
	TextButton = "GuiObject",
	Frame = "GuiObject",
	ImageLabel = "GuiObject",
	GuiObject = "Instance",
	SurfaceGui = "LayerCollector",
	BillboardGui = "LayerCollector",
	ScreenGui = "LayerCollector",
	LayerCollector = "Instance",
	ParticleEmitter = "Instance",
	Attachment = "Instance",
	Folder = "Instance",
	Terrain = "BasePart",
}

local function isA(className, target)
	local c = className
	while c do
		if c == target then
			return true
		end
		c = PARENTS[c]
	end
	return target == "Instance"
end

-- Señales: como en Roblox, Disconnect quita la función (y Destroy de la instancia desconecta todas
-- sus señales). M.liveConnections cuenta las conexiones vivas (para buscar fugas).
M.liveConnections = 0
local signalMeta = {}
signalMeta.__index = signalMeta
function signalMeta:Connect(fn, once)
	local fns = rawget(self, "__fns") or {}
	rawset(self, "__fns", fns)
	local conn = { Connected = true }
	local entry = { Fn = fn, Conn = conn, Once = once }
	function conn.Disconnect()
		if conn.Connected then
			conn.Connected = false
			M.liveConnections -= 1
			local i = table.find(fns, entry)
			if i then
				table.remove(fns, i)
			end
		end
	end
	conn.disconnect = conn.Disconnect
	M.liveConnections += 1
	table.insert(fns, entry)
	return conn
end
function signalMeta:Once(fn)
	return signalMeta.Connect(self, fn, true)
end
function signalMeta:Fire(...)
	for _, entry in table.clone(rawget(self, "__fns") or {}) do
		if entry.Conn.Connected then
			if entry.Once then
				entry.Conn.Disconnect()
			end
			entry.Fn(...)
		end
	end
end
function signalMeta:DisconnectAll()
	for _, entry in table.clone(rawget(self, "__fns") or {}) do
		entry.Conn.Disconnect()
	end
end
function signalMeta:Wait() end
local function newSignal()
	return setmetatable({}, signalMeta)
end

M.terrainFills = {}
M.allInstances = {}

local InstanceMeta = {}
local Methods = {}

local function new(className)
	local self = setmetatable({
		__props = {
			Name = className,
			ClassName = className,
		},
		__children = {},
		__attributes = {},
		__className = className,
	}, InstanceMeta)
	local p = self.__props
	if isA(className, "BasePart") then
		p.CFrame = CFrame.new()
		p.Size = Vector3.new(4, 1, 2)
		p.Color = Color3.fromRGB(163, 162, 165)
		p.Material = roblox.Enum.Material.Plastic
		p.Transparency = 0
		p.Reflectance = 0
		p.Anchored = false
		p.CanCollide = true
		p.CanQuery = true
		p.Shape = roblox.Enum.PartType.Block
		p.AssemblyLinearVelocity = Vector3.zero
	elseif className == "Attachment" then
		p.CFrame = CFrame.new()
	end
	table.insert(M.allInstances, self)
	return self
end

InstanceMeta.__index = function(self, key)
	local m = Methods[key]
	if m then
		return m
	end
	local p = rawget(self, "__props")
	if key == "Position" and p.CFrame then
		return p.CFrame.Position
	elseif key == "Orientation" and p.CFrame then
		local x, y, z = p.CFrame:ToOrientation()
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	elseif key == "Parent" then
		return p.Parent
	elseif (key == "WorldPosition" or key == "WorldCFrame") and self.__className == "Attachment" then
		local parent = p.Parent
		local world = (parent and parent.CFrame or CFrame.new()) * p.CFrame
		return key == "WorldCFrame" and world or world.Position
	elseif key == "Terrain" and self.__className == "Workspace" then
		return self:FindFirstChild("Terrain")
	elseif key == "ExtentsSize" and p.Size then
		local c = p.CFrame
		local s = p.Size
		local corners = {}
		local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = c * Vector3.new(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2)
					mn = mn:Min(w)
					mx = mx:Max(w)
				end
			end
		end
		return mx - mn
	end
	local v = p[key]
	if v ~= nil then
		return v
	end
	-- Hijo por nombre
	for _, child in rawget(self, "__children") do
		if child.__props.Name == key then
			return child
		end
	end
	-- Valores numéricos: 0 por defecto, como en Roblox
	if key == "Value" and (rawget(self, "__className") == "IntValue" or rawget(self, "__className") == "NumberValue") then
		return 0
	end
	-- Propiedades que pueden valer nil (no son eventos)
	if key == "Character" or key == "Team" or key == "PrimaryPart" or key == "Adornee" then
		return nil
	end
	-- Eventos
	if type(key) == "string" and key:match("^[A-Z]") then
		local ev = newSignal()
		p[key] = ev
		return ev
	end
	return nil
end

InstanceMeta.__newindex = function(self, key, value)
	local p = rawget(self, "__props")
	if key == "Parent" then
		local old = p.Parent
		if old then
			local list = old.__children
			for i, c in list do
				if c == self then
					table.remove(list, i)
					break
				end
			end
		end
		p.Parent = value
		if value then
			table.insert(value.__children, self)
		end
		return
	elseif key == "Position" and (p.CFrame ~= nil or typeof(value) == "Vector3") then
		local c = p.CFrame or CFrame.new()
		p.CFrame = CFrame.new(value) * (c - c.Position)
		return
	elseif key == "Orientation" and typeof(value) == "Vector3" then
		local c = p.CFrame or CFrame.new()
		p.CFrame = CFrame.new(c.Position) * CFrame.fromOrientation(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
		return
	end
	if M.strictProps and not (type(key) == "string" and key:sub(1, 2) == "__") then
		M.checkProp(rawget(self, "__className"), key)
	end
	p[key] = value
end

-- Propiedades reales de cada clase (de globalTypes.d.luau): asignar una que no existe es un error,
-- igual que en Roblox
local API = {}
do
	local ok, defs = pcall(fs.readFile, "../globalTypes.d.luau")
	if ok then
		local current
		for line in defs:gmatch("[^\n]+") do
			local name = line:match("^declare extern type (%w+)")
			if name then
				current = { Parent = line:match(" extends (%w+)"), Props = {} }
				API[name] = current
			elseif line == "end" then
				current = nil
			elseif current then
				local prop = line:match("^\t(%w+):")
				if prop then
					current.Props[prop] = true
				end
			end
		end
	end
end
M.strictProps = next(API) ~= nil
M.badProps = {}
function M.checkProp(className, key)
	local c = className
	if not API[c] then
		return
	end
	while c and API[c] do
		if API[c].Props[key] then
			return
		end
		c = API[c].Parent
	end
	local msg = className .. " no tiene la propiedad " .. tostring(key)
	if not M.badProps[msg] then
		M.badProps[msg] = true
		error(msg, 3)
	end
end

InstanceMeta.__tostring = function(self)
	return self.__props.Name
end

function Methods:IsA(target)
	return isA(self.__className, target)
end
function Methods:GetChildren()
	return table.clone(self.__children)
end
function Methods:GetDescendants()
	local out = {}
	local function walk(inst)
		for _, c in inst.__children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Methods:FindFirstChild(name, recursive)
	for _, c in self.__children do
		if c.__props.Name == name then
			return c
		end
	end
	if recursive then
		for _, c in self.__children do
			local f = c:FindFirstChild(name, true)
			if f then
				return f
			end
		end
	end
	return nil
end
function Methods:WaitForChild(name, timeout)
	local c = self:FindFirstChild(name)
	if not c and timeout then
		return nil -- (con tiempo límite, en Roblox devolvería nil al agotarse)
	end
	if not c then
		error("WaitForChild: no existe " .. tostring(name) .. " en " .. self.__props.Name)
	end
	return c
end
function Methods:FindFirstChildOfClass(className)
	for _, c in self.__children do
		if c.__className == className then
			return c
		end
	end
	return nil
end
function Methods:FindFirstChildWhichIsA(className)
	for _, c in self.__children do
		if c:IsA(className) then
			return c
		end
	end
	return nil
end
function Methods:FindFirstAncestorOfClass(className)
	local p = self.__props.Parent
	while p do
		if p.__className == className then
			return p
		end
		p = p.__props.Parent
	end
	return nil
end
function Methods:IsDescendantOf(other)
	local p = self.__props.Parent
	while p do
		if p == other then
			return true
		end
		p = p.__props.Parent
	end
	return false
end
function Methods:SetAttribute(k, v)
	local old = self.__attributes[k]
	self.__attributes[k] = v
	local signals = rawget(self, "__attrSignals")
	if old ~= v and signals and signals[k] then
		signals[k]:Fire()
	end
	-- Evento general AttributeChanged (solo si alguien lo ha pedido)
	local general = rawget(self, "__props").AttributeChanged
	if old ~= v and general then
		general:Fire(k)
	end
end
function Methods:GetAttribute(k)
	return self.__attributes[k]
end
function Methods:GetAttributes()
	return table.clone(self.__attributes)
end
function Methods:GetAttributeChangedSignal(k)
	local signals = rawget(self, "__attrSignals")
	if not signals then
		signals = {}
		rawset(self, "__attrSignals", signals)
	end
	signals[k] = signals[k] or newSignal()
	return signals[k]
end
function Methods:GetPropertyChangedSignal()
	return newSignal()
end
function Methods:Destroy()
	if rawget(self, "__destroyed") then
		return
	end
	self.Parent = nil
	self.__destroyed = true
	-- Como en Roblox: se desconectan sus señales y se destruyen los descendientes
	for _, value in rawget(self, "__props") do
		if type(value) == "table" and getmetatable(value) == signalMeta then
			value:DisconnectAll()
		end
	end
	for _, signal in rawget(self, "__attrSignals") or {} do
		signal:DisconnectAll()
	end
	for _, c in table.clone(rawget(self, "__children") or {}) do
		c:Destroy()
	end
end
function Methods:ClearAllChildren()
	for _, c in table.clone(self.__children) do
		c:Destroy()
	end
end
function Methods:Clone()
	local copy = new(self.__className)
	for k, v in self.__props do
		if k ~= "Parent" then
			copy.__props[k] = v
		end
	end
	for k, v in self.__attributes do
		copy.__attributes[k] = v
	end
	for _, c in self.__children do
		c:Clone().Parent = copy
	end
	return copy
end

local function partsOf(model)
	local parts = {}
	if model:IsA("BasePart") then
		table.insert(parts, model)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	return parts
end

function Methods:GetPivot()
	if self:IsA("BasePart") then
		return self.CFrame
	end
	local pp = self.__props.PrimaryPart
	if pp then
		return pp.CFrame
	end
	local parts = partsOf(self)
	return parts[1] and parts[1].CFrame or CFrame.new()
end
function Methods:PivotTo(target)
	local pivot = self:GetPivot()
	local delta = target * pivot:Inverse()
	for _, part in partsOf(self) do
		part.__props.CFrame = delta * part.__props.CFrame
	end
end
function Methods:GetBoundingBox()
	local orientation = self:GetPivot()
	orientation = orientation - orientation.Position
	local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in partsOf(self) do
		local c, s = part.CFrame, part.Size
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = orientation:PointToObjectSpace(c * Vector3.new(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2))
					mn = mn:Min(w)
					mx = mx:Max(w)
				end
			end
		end
	end
	return orientation * CFrame.new((mn + mx) / 2), mx - mn
end
function Methods:GetExtentsSize()
	local _, s = self:GetBoundingBox()
	return s
end
function Methods:Emit() end
function Methods:AddItem(item, lifetime)
	if M.taskImpl then
		M.taskImpl.delay(lifetime or 10, function()
			if item.Parent then
				item:Destroy()
			end
		end)
	end
end
-- RemoteFunction desde el cliente: llama al OnServerInvoke del servidor como M.invokePlayer
function Methods:InvokeServer(...)
	local handler = rawget(self, "__props").OnServerInvoke
	if handler then
		return handler(M.invokePlayer, ...)
	end
	return nil
end
-- PolicyService: sin M.policyInfo falla (como si no se pudiera comprobar)
function Methods:GetPolicyInfoForPlayerAsync()
	if M.policyInfo then
		return M.policyInfo
	end
	error("PolicyService no disponible en el simulador")
end
-- Game Passes: M.ownedPasses[UserId .. ":" .. passId] = true
M.ownedPasses = {}
function Methods:UserOwnsGamePassAsync(userId, passId)
	return M.ownedPasses[tostring(userId) .. ":" .. tostring(passId)] == true
end
-- Productos: info de MarketplaceService (M.productInfo[id]) y compras pedidas (M.prompts)
M.productInfo = {}
M.prompts = {}
function Methods:GetProductInfo(id)
	local info = M.productInfo[id]
	if not info then
		error("producto no encontrado")
	end
	return info
end
function Methods:PromptProductPurchase(player, id)
	table.insert(M.prompts, { Kind = "Product", Id = id })
end
function Methods:PromptGamePassPurchase(player, id)
	table.insert(M.prompts, { Kind = "GamePass", Id = id })
end
-- Grupos: M.inGroup[UserId] (IsInGroup, con caché como en Roblox) y M.groupList[UserId] (GetGroupsAsync)
M.inGroup = {}
M.groupList = {}
-- Datos de entrada (invitaciones): M.joinData[UserId]
M.joinData = {}
function Methods:GetJoinData()
	return M.joinData[self.UserId] or {}
end
function Methods:IsInGroup(id)
	return M.inGroup[self.UserId] == id
end
function Methods:GetGroupsAsync(userId)
	return M.groupList[userId] or {}
end
function Methods:GetMouseDelta()
	return require("@lune/roblox").Vector2.new(0, 0)
end
M.renderSteps = {}
function Methods:BindToRenderStep(name, _, fn)
	M.renderSteps[name] = fn
end
function Methods:UnbindFromRenderStep() end
function Methods:GetFocusedTextBox() return nil end
M.keysDown = {}
function Methods:IsKeyDown(key) return M.keysDown[key.Name] == true end
function Methods:IsGamepadButtonDown(_, key) return M.keysDown[key.Name] == true end
-- TweenService:Create: el tween aplica las propiedades al instante al reproducirse
function Methods:Create(target, _info, props)
	local tween = new("Tween")
	rawset(tween, "__tweenTarget", target)
	rawset(tween, "__tweenProps", props)
	return tween
end
function Methods:Play()
	local target = rawget(self, "__tweenTarget")
	if target then
		for k, v in rawget(self, "__tweenProps") or {} do
			target[k] = v
		end
		self.PlaybackState = roblox.Enum.PlaybackState.Completed
		self.Completed:Fire(roblox.Enum.PlaybackState.Completed)
	elseif rawget(self, "__className") == "Sound" then
		self.IsPlaying = true
	end
end
function Methods:Cancel()
	self.PlaybackState = roblox.Enum.PlaybackState.Cancelled
end
function Methods:Stop()
	if rawget(self, "__className") == "Sound" then
		self.IsPlaying = false
	end
end
function Methods:FillBlock(cf, size, material)
	table.insert(M.terrainFills, { Kind = "Block", CFrame = cf, Size = size, Material = material.Name })
end
function Methods:FillBall(center, radius, material)
	table.insert(M.terrainFills, { Kind = "Ball", Center = center, Radius = radius, Material = material.Name })
end
function Methods:FillCylinder(cf, height, radius, material)
	table.insert(M.terrainFills, { Kind = "Cylinder", CFrame = cf, Height = height, Radius = radius, Material = material.Name })
end
function Methods:FillWedge(cf, size, material)
	table.insert(M.terrainFills, { Kind = "Wedge", CFrame = cf, Size = size, Material = material.Name })
end
function Methods:Clear()
	table.clear(M.terrainFills)
end
function Methods:GetService(name)
	local s = self:FindFirstChild(name)
	if not s then
		s = new(name)
		s.Name = name
		s.Parent = self
	end
	return s
end
M.players = {}
M.sent = {}
M.broadcast = {}
function Methods:GetPlayers()
	if self.__className == "Team" then
		local out = {}
		for _, p in M.players do
			if p.Team == self then
				table.insert(out, p)
			end
		end
		return out
	end
	return table.clone(M.players)
end
function Methods:GetPlayerByUserId(id)
	for _, p in M.players do
		if p.UserId == id then
			return p
		end
	end
	return nil
end
function Methods:GetTeams()
	local out = {}
	for _, c in self.__children do
		if c.__className == "Team" then
			table.insert(out, c)
		end
	end
	return out
end
function Methods:BindToClose() end
function Methods:IsLoaded()
	return true
end
function Methods:RemoveDefaultLoadingScreen() end
M.preloaded = {}
function Methods:PreloadAsync(list, callback)
	for _, item in list do
		table.insert(M.preloaded, item)
		if callback then
			callback(item, Enum and Enum.AssetFetchStatus and Enum.AssetFetchStatus.Success or "Success")
		end
	end
end
function Methods:GetServerTimeNow()
	return os.clock()
end
function Methods:SetNetworkOwner() end
function Methods:GetPartBoundsInRadius()
	return {}
end
function Methods:IsFriendsWith(userId)
	if M.friendsImpl then
		return M.friendsImpl(self, userId)
	end
	return false
end
function Methods:AddTag(tag)
	local tags = rawget(self, "__tags") or {}
	rawset(self, "__tags", tags)
	tags[tag] = true
end
function Methods:RemoveTag(tag)
	local tags = rawget(self, "__tags")
	if tags then
		tags[tag] = nil
	end
end
function Methods:HasTag(tag)
	local tags = rawget(self, "__tags")
	return tags ~= nil and tags[tag] == true
end
-- CollectionService (sin registro global: lo justo para iniciar) y BindableEvent:Fire
function Methods:GetTagged()
	return {}
end
function Methods:GetInstanceAddedSignal()
	return newSignal()
end
function Methods:GetInstanceRemovedSignal()
	return newSignal()
end
function Methods:Fire(...)
	self.Event:Fire(...)
end
-- Humanoid: estado (las pruebas lo cambian con _State)
function Methods:GetState()
	return rawget(self, "_State") or require("@lune/roblox").Enum.HumanoidStateType.Running
end
function Methods:SetStateEnabled() end
function Methods:ChangeState(state)
	rawset(self, "_State", state)
end
-- Cliente: ContextActionService y StarterGui
M.actions = {}
function Methods:BindAction(name, fn)
	M.actions[name] = fn
end
function Methods:SetTitle() end
function Methods:SetPosition() end
function Methods:SetImage() end
function Methods:GetButton() return nil end
function Methods:SetCoreGuiEnabled() end

-- Bots: modelo R15 mínimo, caminos y animaciones
function Methods:CreateHumanoidModelFromDescriptionAsync(description)
	local model = new("Model")
	local hum = new("Humanoid")
	hum.HipHeight = 2
	hum.Health = 100
	hum.Parent = model
	for _, name in { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm" } do
		local part = new("Part")
		part.Name = name
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = model
	end
	return model
end
function Methods:CreatePath()
	return {
		Status = roblox.Enum.PathStatus.Success,
		ComputeAsync = function() end,
		GetWaypoints = function()
			return { { Position = Vector3.new(10, 0, 0), Action = roblox.Enum.PathWaypointAction.Walk } }
		end,
	}
end
M.moveTo = {}
function Methods:MoveTo(position)
	table.insert(M.moveTo, position)
end
function Methods:EquipTool(tool)
	tool.Parent = self.Parent
end
function Methods:LoadAnimation()
	return { Play = function() end, Stop = function() end, AdjustSpeed = function() end }
end
M.loadCharacterCalls = 0
function Methods:LoadCharacter()
	M.loadCharacterCalls += 1
	if M.onLoadCharacter then
		M.onLoadCharacter(self)
	end
end
function Methods:HasAppearanceLoaded()
	return true
end
function Methods:Raycast(origin, direction, params)
	if M.raycastImpl then
		return M.raycastImpl(origin, direction, params)
	end
	return nil -- sin obstáculos en las pruebas
end
function Methods:Spherecast(origin, radius, direction, params)
	return nil
end
function Methods:GetPlayerFromCharacter(character)
	for _, p in M.players do
		if p.Character == character then
			return p
		end
	end
	return nil
end
function Methods:TakeDamage(amount)
	local ff = false
	local parent = self.Parent
	if parent then
		for _, c in parent:GetChildren() do
			if c.__className == "ForceField" then ff = true end
		end
	end
	if not ff then
		local before = self.Health or 100
		self.Health = math.max(0, before - amount)
		if before > 0 and self.Health <= 0 then
			self.Died:Fire() -- como en Roblox
		end
	end
end
function Methods:FireAllClients(...)
	table.insert(M.broadcast, { Remote = self.Name, Args = { ... } })
end
function Methods:FireClient(player, ...)
	table.insert(M.sent, { Remote = self.Name, Args = { ... } })
end
M.serverSent = {}
function Methods:FireServer(...)
	table.insert(M.serverSent, { Remote = self.Name, Args = { ... } })
end
M.dsData = {}
M.dsWrites = 0
local function deepcopy(v)
	if type(v) ~= "table" then return v end
	local t = {}
	for k, x in v do t[k] = deepcopy(x) end
	return t
end
function Methods:GetDataStore()
	return {
		GetAsync = function(_, k) return deepcopy(M.dsData[k]) end,
		SetAsync = function(_, k, v) M.dsWrites += 1; M.dsData[k] = deepcopy(v) end,
		UpdateAsync = function(_, k, fn)
			if M.dsFail then
				error("DataStore caído (simulado)")
			end
			local new = fn(deepcopy(M.dsData[k]))
			if new ~= nil then
				M.dsWrites += 1
				M.dsData[k] = deepcopy(new)
			end
			return deepcopy(new ~= nil and new or M.dsData[k])
		end,
	}
end
M.ordered = {}
function Methods:GetOrderedDataStore(name)
	M.ordered[name] = M.ordered[name] or {}
	local data = M.ordered[name]
	return {
		SetAsync = function(_, k, v) data[k] = v end,
		UpdateAsync = function(_, k, fn) local v = fn(data[k]); if v ~= nil then data[k] = v end; return data[k] end,
		GetSortedAsync = function(_, ascending, size)
			local rows = {}
			for k, v in data do table.insert(rows, { key = k, value = v }) end
			table.sort(rows, function(a, b) if ascending then return a.value < b.value end return a.value > b.value end)
			while #rows > size do table.remove(rows) end
			return { GetCurrentPage = function() return rows end }
		end,
	}
end
function Methods:GetNameFromUserIdAsync(id)
	return "Usuario" .. id
end
function Methods:JSONEncode(v)
	local serde = require("@lune/serde")
	return serde.encode("json", v)
end
function Methods:IsServer()
	return true
end
function Methods:IsClient()
	return false
end
-- (M.isStudio = false simula un servidor publicado: lo usa la prueba del modo QA)
function Methods:IsStudio()
	return M.isStudio ~= false
end

M.new = new

-- Random determinista sencillo
local RandomMeta = {}
RandomMeta.__index = RandomMeta
function RandomMeta:NextNumber(a, b)
	self.state = (self.state * 1103515245 + 12345) % 2147483648
	local r = self.state / 2147483648
	if a == nil then
		return r
	end
	return a + (b - a) * r
end
function RandomMeta:NextInteger(a, b)
	return math.floor(self:NextNumber(a, b + 1 - 1e-9))
end
local RandomLib = {
	new = function(seed)
		return setmetatable({ state = math.floor(seed or os.clock() * 1000) % 2147483648 }, RandomMeta)
	end,
}

-- Construye el árbol del juego a partir de las carpetas de src/
function M.buildGame(srcRoot)
	local game = new("DataModel")
	game.Name = "Game"
	local workspace = game:GetService("Workspace")
	local terrain = new("Terrain")
	terrain.Name = "Terrain"
	terrain.Parent = workspace
	local camera = new("Camera")
	camera.Name = "Camera"
	camera.Parent = workspace
	workspace.CurrentCamera = camera

	local function mount(dir, parent)
		for _, file in fs.readDir(dir) do
			local path = dir .. "/" .. file
			if fs.isDir(path) then
				-- (carpeta con init.luau = ModuleScript con hijos, como hace Rojo)
				local folder
				if fs.isFile(path .. "/init.luau") then
					folder = new("ModuleScript")
					folder.Source = fs.readFile(path .. "/init.luau")
				else
					folder = new("Folder")
				end
				folder.Name = file
				folder.Parent = parent
				mount(path, folder)
			elseif file:match("%.luau$") and file ~= "init.luau" then
				local name = file:gsub("%.server%.luau$", ""):gsub("%.client%.luau$", ""):gsub("%.luau$", "")
				local ms = new("ModuleScript")
				ms.Name = name
				ms.Source = fs.readFile(path)
				ms.Parent = parent
			end
		end
	end
	local shared = new("Folder")
	shared.Name = "Shared"
	shared.Parent = game:GetService("ReplicatedStorage")
	mount(srcRoot .. "/shared", shared)
	local server = new("Folder")
	server.Name = "Server"
	server.Parent = game:GetService("ServerScriptService")
	mount(srcRoot .. "/server", server)
	local client = new("Folder")
	client.Name = "Client"
	client.Parent = game:GetService("StarterPlayer")
	mount(srcRoot .. "/client", client)

	local cache = {}
	local env
	local function requireModule(ms)
		if cache[ms] ~= nil then
			return cache[ms]
		end
		local moduleEnv = table.clone(env)
		moduleEnv.script = ms
		local chunk = luau.load(ms.Source, {
			debugName = ms.Name,
			environment = moduleEnv,
			injectGlobals = false,
		})
		local result = chunk()
		cache[ms] = result
		return result
	end

	local function mockTypeof(v)
		if type(v) == "table" and getmetatable(v) == InstanceMeta then
			return "Instance"
		end
		return typeof(v)
	end

	-- CFrame.lookAt correcto (el de Lune ignora la inclinación)
	local RealCFrame = roblox.CFrame
	local function lookAt(at, target, up)
		up = up or Vector3.new(0, 1, 0)
		local look = (target - at)
		if look.Magnitude < 1e-6 then
			return RealCFrame.new(at)
		end
		look = look.Unit
		local right = look:Cross(up)
		if right.Magnitude < 1e-6 then
			return RealCFrame.new(0 / 0, 0 / 0, 0 / 0) -- igual que Roblox: dirección paralela a "up" = NaN
		end
		right = right.Unit
		local up2 = right:Cross(look)
		return RealCFrame.fromMatrix(at, right, up2, -look)
	end
	local CFrameLib = setmetatable({ lookAt = lookAt }, { __index = RealCFrame })
	M.lookAt = lookAt

	env = {
		game = game,
		workspace = workspace,
		Instance = { new = new },
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrameLib,
		Color3 = roblox.Color3,
		BrickColor = roblox.BrickColor,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		PhysicalProperties = roblox.PhysicalProperties,
		Enum = roblox.Enum,
		Random = RandomLib,
		RaycastParams = { new = function() return {} end },
		OverlapParams = { new = function() return {} end },
		TweenInfo = { new = function(...) return { ... } end },
		typeof = mockTypeof,
		require = requireModule,
		task = M.taskImpl or {
			spawn = function() end,
			delay = function() end,
			defer = function() end,
			wait = function() return 0 end,
		},
		tick = os.clock,
		debug = debug,
		warn = function(...) if M.onWarn then M.onWarn(...) end print("[warn]", ...) end,
		print = print,
		math = math,
		string = string,
		table = table,
		os = os,
		coroutine = coroutine,
		utf8 = utf8,
		bit32 = bit32,
		buffer = buffer,
		pairs = pairs,
		ipairs = ipairs,
		next = next,
		select = select,
		type = type,
		tostring = tostring,
		tonumber = tonumber,
		error = error,
		assert = assert,
		pcall = pcall,
		xpcall = xpcall,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		rawget = rawget,
		rawset = rawset,
		rawequal = rawequal,
		unpack = unpack or table.unpack,
	}
	return game, requireModule
end

-- Exporta las piezas (y luces) bajo `root` a una tabla serializable
function M.exportParts(root)
	local parts, lights = {}, {}
	local list = root:GetDescendants()
	for _, inst in list do
		if inst:IsA("BasePart") and inst.__className ~= "Terrain" then
			local c = inst.CFrame
			local comps = { c:GetComponents() }
			local col = inst.Color
			local material = inst.Material
			table.insert(parts, {
				n = inst.Name,
				s = inst.Shape and inst.Shape.Name or "Block",
				z = { inst.Size.X, inst.Size.Y, inst.Size.Z },
				c = comps,
				k = { col.R, col.G, col.B },
				m = material and material.Name or "Plastic",
				t = inst.Transparency or 0,
				r = inst.Reflectance or 0,
				cls = inst.__className,
			})
		elseif inst:IsA("Light") and inst.__props.Parent and inst.__props.Parent:IsA("BasePart") then
			local part = inst.__props.Parent
			local col = inst.Color or Color3.new(1, 1, 1)
			table.insert(lights, {
				cls = inst.__className,
				p = { part.Position.X, part.Position.Y, part.Position.Z },
				k = { col.R, col.G, col.B },
				range = inst.Range or 8,
				b = inst.Brightness or 1,
			})
		elseif inst.__className == "SurfaceGui" and inst.__props.Parent then
			-- Texto de carteles
			local label = inst:FindFirstChildOfClass("TextLabel")
			local part = inst.__props.Parent
			if label and part:IsA("BasePart") then
				local c = part.CFrame
				local col = label.TextColor3 or Color3.new(1, 1, 1)
				table.insert(parts, {
					n = "__text",
					text = label.Text,
					face = inst.Face and inst.Face.Name or "Front",
					z = { part.Size.X, part.Size.Y, part.Size.Z },
					c = { c:GetComponents() },
					k = { col.R, col.G, col.B },
					m = "Text",
				})
			end
		end
	end
	local fills = {}
	for _, f in M.terrainFills do
		local out = { kind = f.Kind, m = f.Material }
		if f.CFrame then
			out.c = { f.CFrame:GetComponents() }
		end
		if f.Size then
			out.z = { f.Size.X, f.Size.Y, f.Size.Z }
		end
		if f.Center then
			out.p = { f.Center.X, f.Center.Y, f.Center.Z }
			out.radius = f.Radius
		end
		if f.Height then
			out.h = f.Height
			out.radius = f.Radius
		end
		table.insert(fills, out)
	end
	return { parts = parts, lights = lights, terrain = fills }
end

return M
