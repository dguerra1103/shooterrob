-- Zonas reservadas del HUD táctil (Fase 16). No es otro HUD: reparte el sitio entre los elementos
-- que ya existen (aviso de baja, medallas, objetivo de cada modo, radar, avisos...), que antes tenían
-- cada uno su posición fija y en una partida 5v5 se montaban unos encima de otros y de los botones.
--
-- Zonas (en coordenadas de la zona segura del dispositivo, las de las ScreenGui del HUD):
--   TOP_LEFT     bajo el minimapa: objetivo (A/B/C, bomba), radar, nombre de la zona;
--   TOP_FEED     arriba en el centro, bajo el marcador y por encima del centro libre: bandera que
--                llevas, avisos de bandera, aviso de baja, medallas, avisos de XP;
--   BOTTOM_NOTICE bajo el centro libre, entre los botones: progreso de plantar/desactivar, avisos de
--                texto, consejos y estamina (cada línea usa el hueco libre entre los botones).
-- (TOP_CENTER = marcador, TOP_RIGHT = tira de poco uso + registro de bajas, CENTER = mira, BOTTOM_LEFT
-- y BOTTOM_RIGHT = pulgares, RIGHT_CAMERA_ZONE = cámara: los colocan HUD, TouchLayout y MobileHUD.)
--
-- Cada zona apila sus elementos visibles por orden (el más importante primero). Lo que no cabe se
-- aparta de la pantalla (no se monta encima de nada) hasta que vuelva a caber. Nada se coloca encima
-- de la caja táctil de un botón: si choca, baja. Solo se usa en pantallas táctiles; en ordenador cada
-- elemento sigue donde estaba.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MobileHUD = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MobileHUD"))
local InputMode = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InputMode"))

local HUDZones = {}

local GAP = 4
local OFFSCREEN = UDim2.fromOffset(-4000, -4000)

type Rect = { Min: Vector2, Max: Vector2 }
type Item = {
	Id: string,
	Object: GuiObject,
	Zone: string,
	Order: number,
	Active: (() -> boolean)?,
	Gui: ScreenGui?,
	Fit: boolean?,
	Anchor: Vector2?,
	SizeFn: (() -> Vector2)?,
}

local zones: { [string]: { Min: Vector2, Max: Vector2, Span: boolean?, CenterX: number? } } = {}
local avoid: { Rect } = {}
local center: Vector2 = Vector2.zero
local clear = 0
local items: { Item } = {}
local byId: { [string]: Item } = {}
HUDZones.Placed = {} :: { [string]: Rect } -- dónde quedó cada elemento visible (para validar y depurar)
HUDZones.Overflow = {} :: { [string]: boolean } -- los que no cupieron (apartados)

function HUDZones.Enabled(): boolean
	return InputMode.TouchUI()
end

-- En plena pelea (partida en juego y vivo): lo que no hace falta para luchar (regalos, evento,
-- potenciadores) se guarda en táctil
function HUDZones.Fighting(): boolean
	local ok, ClientState = pcall(require, script.Parent.ClientState)
	if not ok then
		return false
	end
	local player = Players.LocalPlayer
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return ReplicatedStorage:GetAttribute("State") == "Playing" and not ClientState.InMainMenu and not ClientState.Dead
		and humanoid ~= nil and humanoid.Health > 0
end

-- Un elemento pasa a ser de una zona (su posición la decide HUDZones; su módulo sigue decidiendo si
-- se ve y qué pone). opts: Active (función: si ocupa sitio), Gui (su ScreenGui: si está apagada no
-- ocupa), Fit (se le ajusta el ancho al hueco), Anchor (punto de anclaje; por defecto arriba en el
-- centro, o arriba a la izquierda en TOP_LEFT), Size (función: el tamaño que reserva, si no es el de
-- su Size; p. ej. el aviso de baja reserva su tamaño de reposo aunque dé un pulso al aparecer)
function HUDZones.Register(id: string, object: GuiObject, zone: string, order: number, opts: { [string]: any }?)
	local o = opts or {}
	local item: Item = { Id = id, Object = object, Zone = zone, Order = order, Active = o.Active, Gui = o.Gui, Fit = o.Fit, Anchor = o.Anchor, SizeFn = o.Size }
	if byId[id] then
		local i = table.find(items, byId[id])
		if i then
			table.remove(items, i)
		end
	end
	byId[id] = item
	table.insert(items, item)
	table.sort(items, function(a, b)
		return a.Order < b.Order
	end)
	HUDZones.Layout()
end

function HUDZones.Managed(object: Instance): boolean
	for _, item in items do
		if item.Object == object then
			return HUDZones.Enabled()
		end
	end
	return false
end

-- Zonas y obstáculos (cajas táctiles de los botones, munición, vida, registro de bajas...), los
-- calcula HUD al recolocar
function HUDZones.SetZones(newZones, obstacles: { Rect }, middle: Vector2, radius: number)
	zones = newZones
	avoid = obstacles
	center = middle
	clear = radius
	HUDZones.Layout()
end

function HUDZones.Zones()
	return zones, avoid, center, clear
end

local function isActive(item: Item): boolean
	local object = item.Object
	if not object.Parent or not object.Visible then
		return false
	end
	if item.Gui and not item.Gui.Enabled then
		return false
	end
	if item.Active and not item.Active() then
		return false
	end
	return true
end

-- Tamaño en pantalla (Size en píxeles × su UIScale; con ancho relativo, el ancho de la zona)
local function sizeOf(item: Item, zoneWidth: number): Vector2
	if item.SizeFn then
		return item.SizeFn()
	end
	local object = item.Object
	local size = object.Size
	local width = size.X.Offset + size.X.Scale * zoneWidth
	local height = size.Y.Offset
	local scale = object:FindFirstChildOfClass("UIScale")
	local factor = scale and scale.Scale or 1
	return Vector2.new(width, height) * factor
end

local function hitsAvoid(min: Vector2, max: Vector2): Rect?
	for _, r in avoid do
		if MobileHUD.RectsCut(min, max, r.Min, r.Max, 0) then
			return r
		end
	end
	return nil
end

local function setPosition(object: GuiObject, anchor: Vector2, position: UDim2)
	if object.AnchorPoint ~= anchor then
		object.AnchorPoint = anchor
	end
	if object.Position ~= position then
		object.Position = position
	end
end

-- Recoloca todo (barato: unos pocos elementos; solo escribe si algo cambia)
function HUDZones.Layout()
	if not HUDZones.Enabled() then
		return
	end
	local placed, overflow = {}, {}
	local cursor: { [string]: number } = {}
	for _, item in items do
		local zone = zones[item.Zone]
		if not zone or not isActive(item) then
			continue
		end
		local dims = sizeOf(item, zone.Max.X - zone.Min.X)
		local left = item.Zone == "TOP_LEFT"
		local anchor = item.Anchor or (left and Vector2.new(0, 0) or Vector2.new(0.5, 0))
		local y = cursor[item.Zone] or zone.Min.Y
		local spot: Rect? = nil
		for _ = 1, 12 do
			if y + dims.Y > zone.Max.Y + 0.5 then
				break
			end
			local x0, x1 = zone.Min.X, zone.Max.X
			if zone.Span then
				-- (los avisos de una línea usan el hueco libre entre los botones a su altura; si es muy
				-- estrecho, la línea siguiente)
				local a, b = MobileHUD.FreeSpan(avoid, y, y + dims.Y, zone.Min.X, zone.Max.X)
				if not a or not b or b - a < math.min(dims.X, 120) then
					y += dims.Y + GAP
					continue
				end
				x0, x1 = a, b
			end
			local w = math.min(dims.X, x1 - x0)
			local minX
			if left then
				minX = x0
			else
				minX = math.clamp(zone.CenterX or center.X, x0 + w / 2, x1 - w / 2) - w / 2
			end
			local min = Vector2.new(minX, y)
			local max = min + Vector2.new(w, dims.Y)
			local obstacle = hitsAvoid(min, max)
			if obstacle then
				-- (si toca un botón, la munición o la vida, baja hasta pasarlo)
				y = math.max(y + 1, obstacle.Max.Y + GAP)
				continue
			end
			spot = { Min = min, Max = max }
			break
		end
		if not spot then
			overflow[item.Id] = true
			setPosition(item.Object, anchor, OFFSCREEN)
			continue
		end
		local w = spot.Max.X - spot.Min.X
		local scale = item.Object:FindFirstChildOfClass("UIScale")
		local factor = scale and scale.Scale or 1
		if item.Fit and item.Object.Size.X.Scale == 0 and math.abs(item.Object.Size.X.Offset * factor - w) > 0.5 then
			item.Object.Size = UDim2.fromOffset(math.floor(w / factor), item.Object.Size.Y.Offset)
		end
		local px = spot.Min.X + w * anchor.X
		local py = spot.Min.Y + (spot.Max.Y - spot.Min.Y) * anchor.Y
		setPosition(item.Object, anchor, UDim2.fromOffset(math.floor(px + 0.5), math.floor(py + 0.5)))
		placed[item.Id] = spot
		cursor[item.Zone] = spot.Max.Y + GAP
	end
	HUDZones.Placed = placed
	HUDZones.Overflow = overflow
end

-- Problemas de la colocación actual (pruebas y depuración): elementos que se pisan entre sí, que
-- tocan la caja táctil de un botón o que entran en el centro libre
function HUDZones.Validate(): { { string } }
	local issues = {}
	local ids = {}
	for id in HUDZones.Placed do
		table.insert(ids, id)
	end
	table.sort(ids)
	for i = 1, #ids do
		local a = HUDZones.Placed[ids[i]]
		for j = i + 1, #ids do
			local b = HUDZones.Placed[ids[j]]
			if MobileHUD.RectsCut(a.Min, a.Max, b.Min, b.Max, 0) then
				table.insert(issues, { ids[i], ids[j] })
			end
		end
		if hitsAvoid(a.Min, a.Max) then
			table.insert(issues, { ids[i], "control" })
		end
		-- (el centro libre: el punto del rectángulo más cercano a la mira)
		local nearest = Vector2.new(math.clamp(center.X, a.Min.X, a.Max.X), math.clamp(center.Y, a.Min.Y, a.Max.Y))
		if clear > 0 and (nearest - center).Magnitude < clear - 0.5 then
			table.insert(issues, { ids[i], "centro" })
		end
	end
	return issues
end

-- Recolocación periódica (10 veces por segundo, solo en táctil): los elementos aparecen y
-- desaparecen solos durante la partida
local started = false
function HUDZones.Start()
	if started then
		return
	end
	started = true
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			HUDZones.Layout()
		end
	end)
end

return HUDZones
