-- Ajustes del jugador en el cliente: calidad gráfica, campo de visión y sensibilidad.
-- Los cambios de Lighting hechos en el cliente solo afectan a este jugador.
--
-- Calidad:
--   Auto  : Baja en móviles (solo táctil) y Media en PC
--   Baja  : sin sombras, sin bloom, sin rayos de sol, sin nubes ni partículas del mapa (móviles)
--   Media : sombras y bloom, sin rayos de sol ni conos de luz, menos partículas del mapa
--   Alta  : todo como lo diseñó el mapa
--   Ultra : además, un desenfoque muy suave del horizonte (más allá de 250 studs) y más partículas
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)

local Settings = {}

local PARTICLE_FACTOR = { Baja = 0, Media = 0.4, Alta = 1, Ultra = 1.3 }

local current = table.clone(GameConfig.DefaultSettings)
ClientState.Settings = current

-- Calidad que se aplica de verdad ("Auto" según el dispositivo)
local function effectiveQuality()
	local q = current.Quality
	if q == "Auto" or not PARTICLE_FACTOR[q] then
		local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		return touchOnly and "Baja" or "Media"
	end
	return q
end

-- Partículas ambientales del mapa (nieve, hojas, chispas, humo): se escalan según la calidad
local function scaleEmitter(emitter)
	if not emitter:IsA("ParticleEmitter") then
		return
	end
	local map = workspace:FindFirstChild("Map")
	if not map or not emitter:IsDescendantOf(map) then
		return
	end
	local base = emitter:GetAttribute("BaseRate")
	if base == nil then
		base = emitter.Rate
		emitter:SetAttribute("BaseRate", base)
	end
	local factor = PARTICLE_FACTOR[effectiveQuality()] or 1
	emitter.Rate = base * factor
	emitter.Enabled = factor > 0
end

-- Focos con sombras reales: solo en calidad Alta y Ultra
local function applyLightShadow(inst)
	if inst:IsA("Light") and inst:GetAttribute("QualityShadow") then
		local q = effectiveQuality()
		inst.Shadows = q == "Alta" or q == "Ultra"
	end
end

-- Detalles caros que se ocultan en calidades bajas (solo en este cliente)
local HIDE_BELOW = {
	LightCone = "Alta",
	ContactShadow = "Media",
	Puddle = "Media",
	-- (detalles pequeños de los mapas realistas: en móviles modestos no se notan y ahorran dibujo)
	FloorPaper = "Media",
	Paper = "Media",
	PosterBand = "Media",
	Wire = "Media",
	ACGrille = "Media",
	Crack = "Media",
	ChairLeg = "Media",
	CamoSpot = "Media",
	SnowPoleBand = "Media",
	SignalLamp = "Media",
	AntennaBar = "Media",
	RubblePile = "Media",
}
local RANK = { Baja = 1, Media = 2, Alta = 3, Ultra = 4 }
local function applyDetail(inst)
	local minimum = HIDE_BELOW[inst.Name]
	if minimum and inst:IsA("BasePart") then
		inst.LocalTransparencyModifier = (RANK[effectiveQuality()] or 2) < RANK[minimum] and 1 or 0
	end
end

-- Fuegos del mapa (Encrucijada de noche): en calidad Baja, sin llamas (la luz se queda)
local function applyFire(inst)
	if inst:IsA("Fire") then
		local map = workspace:FindFirstChild("Map")
		if map and inst:IsDescendantOf(map) then
			inst.Enabled = effectiveQuality() ~= "Baja"
		end
	end
end

local function applyQuality()
	local q = effectiveQuality()
	ClientState.EffectiveQuality = q
	local low = q == "Baja"
	Lighting.GlobalShadows = not low
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Enabled = not low
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		rays.Enabled = q == "Alta" or q == "Ultra"
	end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds.Enabled = not low
	end
	-- Desenfoque lejano solo en Ultra (creado en el cliente)
	local dof = Lighting:FindFirstChild("QualityDOF")
	if q == "Ultra" then
		if not dof then
			dof = Instance.new("DepthOfFieldEffect")
			dof.Name = "QualityDOF"
			-- (muy suave y solo muy lejos: un enemigo a distancia de combate nunca sale borroso)
			dof.FarIntensity = 0.06
			dof.FocusDistance = 200
			dof.InFocusRadius = 50 -- (el máximo que admite)
			dof.NearIntensity = 0
			dof.Parent = Lighting
		end
		dof.Enabled = true
	elseif dof then
		dof.Enabled = false
	end
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, d in map:GetDescendants() do
			scaleEmitter(d)
			applyLightShadow(d)
			applyDetail(d)
			applyFire(d)
		end
	end
end

function Settings.Get()
	return current
end

-- Cambia un ajuste, lo aplica al momento y lo guarda en el servidor (agrupando cambios seguidos)
local saveQueued = false
function Settings.Set(key, value)
	if key == "Quality" then
		if not table.find(GameConfig.QualityLevels, value) then
			return
		end
	else
		local limits = GameConfig.SettingsLimits[key]
		if not limits or type(value) ~= "number" then
			return
		end
		value = math.clamp(math.floor(value * 100 + 0.5) / 100, limits[1], limits[2])
	end
	current[key] = value
	if key == "Quality" then
		applyQuality()
	end
	if not saveQueued then
		saveQueued = true
		task.delay(1.5, function()
			saveQueued = false
			Remotes.SaveSettings:FireServer(current)
		end)
	end
end

function Settings.Init()
	-- Ajustes guardados del jugador
	local function fromData(data)
		if type(data) ~= "table" or type(data.Settings) ~= "table" or saveQueued then
			return
		end
		local changedQuality = data.Settings.Quality ~= current.Quality
		for key, value in data.Settings do
			if GameConfig.DefaultSettings[key] ~= nil and type(value) == type(GameConfig.DefaultSettings[key]) then
				current[key] = value
			end
		end
		if changedQuality then
			applyQuality()
		end
	end
	ClientState.DataChanged.Event:Connect(fromData)
	fromData(ClientState.Data)

	-- Al cambiar de mapa el servidor rehace la iluminación: volvemos a aplicar la calidad
	ReplicatedStorage:GetAttributeChangedSignal("MapName"):Connect(function()
		task.delay(1, applyQuality)
	end)
	workspace.DescendantAdded:Connect(function(inst)
		if inst:IsA("ParticleEmitter") then
			task.defer(scaleEmitter, inst)
		elseif inst:IsA("Light") then
			task.defer(applyLightShadow, inst)
		elseif inst:IsA("Fire") then
			task.defer(applyFire, inst)
		elseif HIDE_BELOW[inst.Name] then
			task.defer(applyDetail, inst)
		end
	end)
	applyQuality()
end

return Settings
