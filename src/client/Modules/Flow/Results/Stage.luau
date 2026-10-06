-- ResultsPresentation: la escena 3D de la pantalla final, dentro del mapa donde acabó la partida.
-- Busca un sitio despejado en la base del equipo que se enseña (entre sus apariciones y el centro del
-- mapa), coloca a los cinco con su avatar real (copias de ReplicatedStorage.ResultsCast, sin scripts
-- ni colisiones; si una no llega, la del personaje vivo), su arma con su skin y la pose de arma lista,
-- el MVP en el centro un paso por delante, con un foco encima, una corona y unas chispas muy suaves.
-- Solo existe mientras se ve la pantalla: :Destroy() lo quita todo (y no toca la iluminación global:
-- los efectos son instancias propias que se borran).
--   local stage = Stage.new()
--   stage:SetMap(mapName)            stage:SetResult(view)       (Data.Build)
--   stage:SetPlayers(lineup)         stage:SetMVP(id)            stage:SetScore(a, b)
--   stage:Build() → true/false       stage:CameraTargets()       stage:HighlightMVP()
--   stage:Destroy()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")

local Preview = require(script.Parent.Parent.Preview)

local player = Players.LocalPlayer

local Stage = {}
Stage.__index = Stage

-- Formación (X a la derecha de la cámara, Z hacia la cámara): MVP centro y delante, luego 2 y 3 a
-- los lados, 4 y 5 en los extremos un poco atrás, todos girados hacia el centro
Stage.Formation = {
	{ X = 0, Z = 1.4, Turn = 0 },
	{ X = -3.5, Z = 0, Turn = 10 },
	{ X = 3.5, Z = 0, Turn = -10 },
	{ X = -6.8, Z = -1.1, Turn = 18 },
	{ X = 6.8, Z = -1.1, Turn = -18 },
}
-- Animaciones (GameConfig.UIAnimations) o la pose equivalente si aún no hay
Stage.MVPAnimation = "VictoryPose"
Stage.SquadAnimation = "SquadVictoryIdle"

local CAST_WAIT = 2.5 -- segundos que se esperan las copias que llegan tarde (avatar desde descripción)

function Stage.new()
	local self = setmetatable({}, Stage)
	self.Players = {}
	self.Models = {}
	self.Effects = {}
	self.Alive = true
	return self
end

function Stage:SetMap(mapName)
	self.Map = mapName
end

function Stage:SetResult(view)
	self.View = view
end

function Stage:SetPlayers(lineup)
	self.Players = lineup or {}
end

function Stage:SetMVP(id)
	self.MVP = id
end

function Stage:SetScore(a, b)
	self.Score = { a, b }
end

---------------------------------------------------------------------------
-- Dónde: un hueco despejado en la base del equipo
---------------------------------------------------------------------------

local function teamSpawns(teamName)
	local map = workspace:FindFirstChild("Map")
	local team = teamName and Teams:FindFirstChild(teamName)
	local list, any = {}, {}
	if not map then
		return list
	end
	for _, d in map:GetDescendants() do
		if d:IsA("SpawnLocation") then
			table.insert(any, d.Position)
			if team and d.TeamColor == team.TeamColor then
				table.insert(list, d.Position)
			end
		end
	end
	return #list > 0 and list or any
end

local function average(points)
	local sum = Vector3.zero
	for _, p in points do
		sum += p
	end
	return #points > 0 and sum / #points or nil
end

local function mapCenter()
	local map = workspace:FindFirstChild("Map")
	if map and map:IsA("Model") then
		local ok, cf = pcall(map.GetBoundingBox, map)
		if ok and cf then
			return cf.Position
		end
	end
	return Vector3.zero
end

-- Rayo que solo choca con el mapa (ni personajes, ni bots, ni la propia escena)
local function mapRay(origin, direction)
	local params = RaycastParams.new()
	local map = workspace:FindFirstChild("Map")
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map, terrain }
	local ok, hit = pcall(workspace.Raycast, workspace, origin, direction, params)
	return ok and hit or nil
end

-- Suelo bajo un punto (o nil si no hay)
local function groundAt(position)
	local hit = mapRay(position + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0))
	return hit and hit.Position or nil
end

-- ¿Cabe la escena? Suelo plano bajo cada hueco y nada entre la fila y la cámara
local function fits(origin, forward, right)
	local floorY = origin.Y
	for _, slot in Stage.Formation do
		local p = origin + right * slot.X + forward * slot.Z
		local g = groundAt(p)
		if not g or math.abs(g.Y - floorY) > 1.2 then
			return false
		end
		-- (pared a la altura del pecho en el hueco)
		if mapRay(p + Vector3.new(0, 3, 0) - forward * 1.5, forward * 3) then
			return false
		end
	end
	-- La cámara ve la fila sin nada delante
	local eye = origin + Vector3.new(0, 3.5, 0)
	if mapRay(eye, forward * 15 + Vector3.new(0, 1, 0)) then
		return false
	end
	return true
end

-- Elige origen y orientación. Devuelve el CFrame de la escena: su +Z local apunta hacia la cámara
-- (la fila mira hacia el centro del mapa y la cámara se pone delante)
function Stage:FindSpot(teamName)
	local spawns = teamSpawns(teamName)
	local base = average(spawns) or mapCenter()
	local center = mapCenter()
	local toCenter = Vector3.new(center.X - base.X, 0, center.Z - base.Z)
	if toCenter.Magnitude < 1 then
		toCenter = Vector3.new(0, 0, 1)
	end
	local distance = toCenter.Magnitude
	local dir = toCenter.Unit
	local best
	-- Candidatos: del centro de la base hacia el del mapa, y un poco a los lados
	for _, t in { 0.08, 0.15, 0.22, 0.3, 0.4, 0.5 } do
		for _, side in { 0, 10, -10, 20, -20 } do
			local p = base + dir * (distance * t) + dir:Cross(Vector3.yAxis) * side
			local g = groundAt(p)
			if g then
				-- (la fila mira hacia el centro del mapa; la cámara se pone delante, en esa dirección)
				for _, yaw in { 0, 25, -25, 50, -50 } do
					local forward = (CFrame.Angles(0, math.rad(yaw), 0) * dir).Unit
					local right = forward:Cross(Vector3.yAxis).Unit * -1
					if fits(g, forward, right) then
						return CFrame.lookAt(g, g - forward)
					end
				end
				best = best or g
			end
		end
	end
	-- Sin hueco perfecto: el primero con suelo (o el centro de la base)
	local origin = best or base
	return CFrame.lookAt(origin, origin - dir)
end

---------------------------------------------------------------------------
-- Quién: copias de los avatares
---------------------------------------------------------------------------

local function castTemplate(id)
	local folder = ReplicatedStorage:FindFirstChild("ResultsCast")
	return folder and folder:FindFirstChild(id) or nil
end

local function makeModel(entry)
	local template = castTemplate(entry.Id)
	local model
	if template then
		local ok, clone = pcall(function()
			template.Archivable = true
			return template:Clone()
		end)
		if ok and clone then
			Preview.Strip(clone)
			model = clone
		end
	end
	if not model and entry.Id == "u" .. tostring(player.UserId) then
		-- (tu copia no llegó: la de tu personaje)
		model = Preview.CloneCharacter(player)
	end
	return model
end

-- Coloca un modelo de pie en su sitio, con su arma y su pose
function Stage:Place(index, entry, model)
	local slot = Stage.Formation[index]
	local root = model:FindFirstChild("HumanoidRootPart")
	if not slot or not root then
		model:Destroy()
		return
	end
	model.Name = "Result_" .. tostring(entry.Id)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hip = humanoid and ((tonumber(humanoid.HipHeight) or 2) + root.Size.Y / 2) or 3
	-- El MVP un poco más grande (se lee primero) y delante
	if index == 1 then
		pcall(function()
			model:ScaleTo(1.06)
		end)
		hip *= 1.06
	end
	-- (de cara a la cámara: los personajes miran a su -Z, así que media vuelta y el giro hacia el centro)
	local cf = self.Origin * CFrame.new(slot.X, hip, slot.Z) * CFrame.Angles(0, math.pi + math.rad(slot.Turn), 0)
	model.Parent = self.Folder
	root.Anchored = true
	root.CFrame = cf
	if entry.Weapon then
		Preview.GiveWeapon(model, entry.Weapon, entry.Skin)
	end
	local animation = index == 1 and Stage.MVPAnimation or Stage.SquadAnimation
	if not Preview.PlayNamed(model, animation) then
		pcall(Preview.PoseReady, model)
	end
	self.Models[index] = model
	-- Respiración mínima (la mueve el controlador mientras se ve)
	self.Base = self.Base or {}
	self.Base[index] = cf
end

---------------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------------

function Stage:Build()
	local view = self.View
	local teamName = view and view.MyTeam
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "ResultsStage"
	local scenes = workspace:FindFirstChild("PresentationScenes") or Instance.new("Folder")
	scenes.Name = "PresentationScenes"
	scenes.Parent = workspace
	self.Folder.Parent = scenes
	self.Origin = self:FindSpot(teamName)
	-- Personajes: los que ya están, y los que llegan tarde en cuanto llegan
	local pending = {}
	for i, entry in self.Players do
		if i > #Stage.Formation then
			break
		end
		local model = makeModel(entry)
		if model then
			self:Place(i, entry, model)
		else
			pending[i] = entry
		end
	end
	if next(pending) then
		task.spawn(function()
			local started = os.clock()
			while self.Alive and next(pending) and os.clock() - started < CAST_WAIT do
				task.wait(0.25)
				for i, entry in pending do
					if castTemplate(entry.Id) then
						local model = makeModel(entry)
						if model and self.Alive then
							self:Place(i, entry, model)
						end
						pending[i] = nil
					end
				end
			end
		end)
	end
	self:BuildLights()
	return true
end

-- Luz de escena (local, se borra al salir): foco cálido sobre el MVP, relleno frío lateral y un
-- suelo de luz; partículas muy sutiles (chispas en victoria, polvo en derrota)
function Stage:BuildLights()
	local victory = self.View and self.View.Outcome == "Victory"
	local function anchorPart(name, cf)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(1, 1, 1)
		part.CFrame = cf
		part.Parent = self.Folder
		return part
	end
	local key = anchorPart("KeyLight", self.Origin * CFrame.new(0, 11, 4) * CFrame.Angles(math.rad(-70), 0, 0))
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Angle = 50
	spot.Range = 18
	spot.Brightness = 0
	spot.Color = Color3.fromRGB(255, 226, 170)
	spot.Shadows = true
	spot.Parent = key
	self.KeyLight = spot
	local fill = anchorPart("FillLight", self.Origin * CFrame.new(-6, 5, 8))
	local point = Instance.new("PointLight")
	point.Range = 16
	point.Brightness = 0.7
	point.Color = victory and Color3.fromRGB(150, 190, 255) or Color3.fromRGB(200, 205, 215)
	point.Parent = fill
	-- Partículas: pocas y lentas, detrás de la fila
	local emitterPart = anchorPart("Embers", self.Origin * CFrame.new(0, 1.5, -4))
	emitterPart.Size = Vector3.new(18, 1, 4)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = victory and 6 or 3
	emitter.Lifetime = NumberRange.new(2.5, 4)
	emitter.Speed = NumberRange.new(0.6, 1.6)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Acceleration = Vector3.new(0, victory and 0.8 or 0.2, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, victory and 0.12 or 0.25), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, victory and 0.2 or 0.6), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = victory and ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 120, 40)) or ColorSequence.new(Color3.fromRGB(170, 170, 175))
	emitter.LightEmission = victory and 1 or 0
	emitter.Parent = emitterPart
	-- Corrección de color y desenfoque de fondo (propios: se borran al salir, no se toca Lighting)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "ResultsGrade"
	grade.Contrast = 0.08
	grade.Saturation = victory and 0.1 or -0.15
	grade.TintColor = victory and Color3.fromRGB(255, 250, 242) or Color3.fromRGB(236, 238, 244)
	grade.Parent = Lighting
	table.insert(self.Effects, grade)
end

-- Destaca al MVP: el foco sube, corona encima de la cabeza y un destello dorado de chispas
function Stage:HighlightMVP()
	local model = self.Models[1]
	if self.KeyLight then
		local TweenService = game:GetService("TweenService")
		TweenService:Create(self.KeyLight, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Brightness = 3 }):Play()
	end
	local head = model and model:FindFirstChild("Head")
	if not head then
		return
	end
	local burst = Instance.new("ParticleEmitter")
	burst.Rate = 0
	burst.Lifetime = NumberRange.new(0.6, 1)
	burst.Speed = NumberRange.new(3, 6)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
	burst.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90))
	burst.LightEmission = 1
	burst.Drag = 4
	burst.Parent = head
	pcall(function()
		burst:Emit(28)
	end)
end

-- Puntos para la cámara: plano general del equipo y plano del MVP
function Stage:CameraTargets()
	local origin = self.Origin
	if not origin then
		return nil
	end
	return {
		Center = (origin * CFrame.new(0, 3, 0)).Position,
		MVP = (origin * CFrame.new(0, 3.6, Stage.Formation[1].Z)).Position,
		Forward = origin.LookVector * -1,
		Origin = origin,
	}
end

-- Vaivén mínimo (respiración) mientras se ve
function Stage:Step(t)
	for i, model in self.Models do
		local base = self.Base and self.Base[i]
		local root = model and model.Parent and model:FindFirstChild("HumanoidRootPart")
		if base and root then
			root.CFrame = base * CFrame.new(0, math.sin(t * 1.5 + i) * 0.025, 0)
		end
	end
end

function Stage:Destroy()
	self.Alive = false
	for _, effect in self.Effects do
		effect:Destroy()
	end
	table.clear(self.Effects)
	if self.Folder then
		self.Folder:Destroy()
		self.Folder = nil
	end
	table.clear(self.Models)
end

return Stage
