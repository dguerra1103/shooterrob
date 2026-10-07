-- Armas de estilo "clásico" (como los shooters más jugados de Roblox): siluetas de armas reales,
-- piezas biseladas (aspecto low-poly), madera y metal y sin neón; el neón queda para las skins
-- especiales. Cada diseño respeta los puntos de su arma en Weapons (manos, mira y cañón), así que
-- las animaciones, el apuntado y los fogonazos siguen cuadrando.
-- Espacio del modelo: -Z = hacia delante, +Y = arriba. "Handle" va siempre en el origen.
-- Roles: Body (armazón), Panel (guardamanos/culata: madera o color), Dark (metal oscuro),
-- Metal (metal claro), Rubber (goma), Lens (cristal), Reticle (punto rojo de la mira), Accent (detalle).
-- Trim (ribete: metal oscuro de fábrica; con una skin, su color de acento).
local Classic = {}

local rad = math.rad
local V = Vector3.new

local function B(name, x, y, z, sx, sy, sz, role, rx, ry, rz)
	local cf = CFrame.new(x, y, z)
	if rx or ry or rz then
		cf *= CFrame.Angles(rad(rx or 0), rad(ry or 0), rad(rz or 0))
	end
	return { Name = name, Size = V(sx, sy, sz), CFrame = cf, Role = role }
end

-- Cilindros: a lo largo de Z (C), de X (CX) y vertical (CY)
local function C(name, x, y, z, length, diameter, role)
	return { Name = name, Size = V(length, diameter, diameter), CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, rad(90), 0), Role = role, Shape = "Cylinder" }
end
local function CX(name, x, y, z, length, diameter, role)
	return { Name = name, Size = V(length, diameter, diameter), CFrame = CFrame.new(x, y, z), Role = role, Shape = "Cylinder" }
end
local function CY(name, x, y, z, length, diameter, role)
	return { Name = name, Size = V(length, diameter, diameter), CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, rad(90)), Role = role, Shape = "Cylinder" }
end
local function Ball(name, x, y, z, d, role)
	return { Name = name, Size = V(d, d, d), CFrame = CFrame.new(x, y, z), Role = role, Shape = "Ball" }
end

local function add(list, items)
	for _, item in items do
		table.insert(list, item)
	end
end

-- Mueve un grupo de piezas (por ejemplo una empuñadura inclinada)
local function Group(base, items)
	for _, p in items do
		p.CFrame = base * p.CFrame
	end
	return items
end

-- Caja biselada a lo largo de Z: sección octogonal (dos cajas cruzadas y cuatro aristas a 45°)
local function bevel(list, name, x, y, z, sx, sy, sz, role, c)
	c = c or math.min(sx, sy) * 0.2
	table.insert(list, B(name, x, y, z, sx, sy - 2 * c, sz, role))
	table.insert(list, B(name .. "Core", x, y, z, sx - 2 * c, sy, sz, role))
	local d = c * math.sqrt(2)
	for _, xs in { -1, 1 } do
		for _, ys in { -1, 1 } do
			table.insert(list, B(name .. "Edge", x + xs * (sx / 2 - c), y + ys * (sy / 2 - c), z, d, d, sz, role, 0, 0, 45))
		end
	end
end

-- Caja biselada vertical (empuñaduras, cargadores): sección octogonal en el plano X-Z
local function bevelY(list, name, x, y, z, sx, sy, sz, role, c)
	c = c or math.min(sx, sz) * 0.2
	table.insert(list, B(name, x, y, z, sx, sy, sz - 2 * c, role))
	table.insert(list, B(name .. "Core", x, y, z, sx - 2 * c, sy, sz, role))
	local d = c * math.sqrt(2)
	for _, xs in { -1, 1 } do
		for _, zs in { -1, 1 } do
			table.insert(list, B(name .. "Edge", x + xs * (sx / 2 - c), y, z + zs * (sz / 2 - c), d, sy, d, role, 0, 45, 0))
		end
	end
end

-- Tubo hueco octogonal a lo largo de Z (miras): deja libre la línea de visión por dentro
local function tube(list, name, x, y, z, length, diameter, role, thick)
	thick = thick or diameter * 0.14
	local r = diameter / 2 - thick / 2
	local side = diameter * 0.4142 + 0.01
	for i = 0, 7 do
		local a = rad(i * 45)
		table.insert(list, {
			Name = name,
			Size = V(side, thick, length),
			CFrame = CFrame.new(x + math.sin(a) * r, y + math.cos(a) * r, z) * CFrame.Angles(0, 0, -a),
			Role = role,
		})
	end
end

---------------------------------------------------------------------------
-- Piezas comunes
---------------------------------------------------------------------------

-- Empuñadura de pistola inclinada con la mano derecha dentro
local function pistolGrip(list, at, role, size, angle)
	size = size or V(0.22, 0.56, 0.3)
	local g = {}
	bevelY(g, "Grip", 0, 0, 0, size.X, size.Y, size.Z, role)
	table.insert(g, B("GripTexture", 0, -0.02, 0.0, size.X + 0.01, size.Y * 0.6, size.Z * 0.55, "Rubber"))
	add(list, Group(CFrame.new(at.X, at.Y + 0.02, at.Z) * CFrame.Angles(rad(angle or 18), 0, 0), g))
end

local function triggerGroup(list, bottomY, z)
	table.insert(list, B("TriggerGuard", 0, bottomY - 0.16, z, 0.05, 0.04, 0.34, "Dark"))
	table.insert(list, B("TriggerGuardFront", 0, bottomY - 0.08, z - 0.16, 0.05, 0.16, 0.04, "Dark"))
	table.insert(list, B("Trigger", 0, bottomY - 0.07, z + 0.02, 0.03, 0.12, 0.03, "Metal", -12, 0, 0))
end

local function rail(list, y, z0, z1, width)
	local length = z0 - z1
	table.insert(list, B("Rail", 0, y, (z0 + z1) / 2, width or 0.16, 0.05, length, "Dark"))
	local count = math.max(2, math.floor(length / 0.16))
	for i = 0, count - 1 do
		local z = z0 - (i + 0.5) * length / count
		table.insert(list, B("RailTooth", 0, y + 0.035, z, (width or 0.16) + 0.02, 0.025, 0.06, "Dark"))
	end
end

-- Mira de punto rojo: tubo corto hueco con cristal y punto
local function redDot(list, aim, z, baseY, size)
	size = size or 0.26
	local bottom = aim.Y - size / 2
	if bottom > baseY then
		table.insert(list, B("DotRiser", 0, (baseY + bottom) / 2, z, 0.18, bottom - baseY + 0.02, 0.3, "Dark"))
	end
	tube(list, "DotHood", 0, aim.Y, z, 0.34, size, "Body", 0.045)
	table.insert(list, B("DotLens", 0, aim.Y, z - 0.15, size * 0.7, size * 0.7, 0.01, "Lens"))
	table.insert(list, B("DotReticle", 0, aim.Y, z - 0.14, 0.022, 0.022, 0.01, "Reticle"))
	table.insert(list, CX("DotKnob", size / 2 + 0.03, aim.Y, z + 0.04, 0.06, 0.08, "Dark"))
end

-- Mira holográfica: ventana rectangular sobre una base
local function holo(list, aim, z, baseY)
	local bottom = aim.Y - 0.15
	table.insert(list, B("HoloBase", 0, (baseY + bottom) / 2, z, 0.26, bottom - baseY + 0.02, 0.46, "Body"))
	table.insert(list, B("HoloTop", 0, aim.Y + 0.14, z - 0.06, 0.3, 0.04, 0.16, "Body"))
	for _, s in { -1, 1 } do
		table.insert(list, B("HoloSide", s * 0.13, aim.Y, z - 0.06, 0.04, 0.32, 0.16, "Body"))
	end
	table.insert(list, B("HoloLens", 0, aim.Y, z - 0.08, 0.22, 0.24, 0.01, "Lens"))
	table.insert(list, B("HoloReticle", 0, aim.Y, z - 0.07, 0.03, 0.03, 0.01, "Reticle"))
	table.insert(list, B("HoloButtons", 0.14, bottom - 0.04, z + 0.12, 0.03, 0.06, 0.12, "Dark"))
end

-- Mira telescópica: tubo hueco, campana delantera, ocular, torretas y anillas
local function scope(list, aim, zCenter, baseY, length, bell)
	length = length or 1.1
	bell = bell or 0.36
	local front = zCenter - length / 2
	local back = zCenter + length / 2
	tube(list, "ScopeTube", 0, aim.Y, zCenter, length, 0.22, "Dark")
	tube(list, "ScopeBell", 0, aim.Y, front - 0.12, 0.3, bell, "Dark")
	tube(list, "ScopeEyepiece", 0, aim.Y, back + 0.1, 0.24, 0.3, "Dark")
	table.insert(list, B("ScopeLensFront", 0, aim.Y, front - 0.26, bell * 0.72, bell * 0.72, 0.01, "Lens"))
	table.insert(list, B("ScopeLensBack", 0, aim.Y, back + 0.2, 0.2, 0.2, 0.01, "Lens"))
	table.insert(list, CY("ScopeTurret", 0, aim.Y + 0.17, zCenter, 0.14, 0.13, "Dark"))
	table.insert(list, CY("ScopeTurretCap", 0, aim.Y + 0.25, zCenter, 0.04, 0.15, "Metal"))
	table.insert(list, CX("ScopeWindage", 0.17, aim.Y, zCenter, 0.14, 0.13, "Dark"))
	local ringBottom = aim.Y - 0.12
	for _, dz in { -length * 0.3, length * 0.3 } do
		table.insert(list, B("ScopeRing", 0, (baseY + ringBottom) / 2, zCenter + dz, 0.14, ringBottom - baseY + 0.03, 0.1, "Dark"))
		table.insert(list, B("ScopeRingCap", 0, aim.Y + 0.12, zCenter + dz, 0.12, 0.04, 0.1, "Dark"))
	end
end

-- Alza (dos postes a los lados de la línea) y punto de mira delantero
local function ironSights(list, aim, rearZ, frontZ, frontBaseY)
	for _, s in { -1, 1 } do
		table.insert(list, B("RearSightPost", s * 0.065, aim.Y - 0.02, rearZ, 0.045, 0.12, 0.06, "Dark"))
	end
	table.insert(list, B("RearSightBase", 0, aim.Y - 0.1, rearZ, 0.18, 0.05, 0.08, "Dark"))
	local postTop = aim.Y - 0.05
	if postTop > frontBaseY then
		table.insert(list, B("FrontSightPost", 0, (frontBaseY + postTop) / 2, frontZ, 0.05, postTop - frontBaseY, 0.06, "Dark"))
	end
	table.insert(list, B("FrontSightBead", 0, aim.Y - 0.02, frontZ, 0.03, 0.07, 0.04, "Accent"))
end

-- Dispositivo de boca: apagallamas, freno o supresor (acaba justo en el Muzzle)
local function muzzleDevice(list, kind, y, muzzleZ, barrelD)
	if kind == "Brake" then
		table.insert(list, B("MuzzleBrake", 0, y, muzzleZ + 0.18, barrelD * 2.4, barrelD * 1.6, 0.36, "Dark"))
		for _, s in { -1, 1 } do
			for i = 0, 1 do
				table.insert(list, B("BrakePort", s * barrelD * 1.2, y, muzzleZ + 0.1 + i * 0.14, 0.02, barrelD * 1.1, 0.07, "Body"))
			end
		end
		return 0.36
	elseif kind == "Suppressor" then
		table.insert(list, C("Suppressor", 0, y, muzzleZ + 0.35, 0.7, barrelD * 2.2, "Body"))
		table.insert(list, C("SuppressorCap", 0, y, muzzleZ + 0.02, 0.04, barrelD * 2.3, "Dark"))
		return 0.7
	elseif kind == "Flash" then
		table.insert(list, C("FlashHider", 0, y, muzzleZ + 0.13, 0.26, barrelD * 1.5, "Dark"))
		for i = 0, 2 do
			table.insert(list, B("FlashSlot", 0, y + barrelD * 0.5, muzzleZ + 0.06 + i * 0.07, barrelD * 1.55, 0.02, 0.035, "Body", 0, 0, i * 60))
		end
		return 0.26
	end
	return 0
end

---------------------------------------------------------------------------
-- Constructor de fusiles (y subfusiles, escopetas, francotiradores...)
---------------------------------------------------------------------------
-- o: Aim, Right, Left, Muzzle (puntos del arma), RecRear/RecFront/RecY/RecH/RecW (cajón),
-- HgFront/HgH/HgW/HgRole/HgY (guardamanos), BarrelD, Device, Stock, StockRole, StockLen,
-- Mag, MagZ, Sight, SightZ, ScopeLen, Bipod, RailTop (bool), Foregrip ("auto"/false)
local function rifle(o)
	local p = {}
	local by = o.Muzzle.Y
	local recY = o.RecY or by
	local recH, recW = o.RecH or 0.46, o.RecW or 0.3
	local recTop, recBottom = recY + recH / 2, recY - recH / 2
	local recZ = (o.RecRear + o.RecFront) / 2
	table.insert(p, B("Handle", 0, 0, 0, 0.2, 0.2, 0.2, "Body"))
	bevel(p, "Receiver", 0, recY, recZ, recW, recH, o.RecRear - o.RecFront, o.RecRole or "Body")
	table.insert(p, B("EjectionPort", recW / 2 + 0.005, recY + 0.05, recZ - 0.05, 0.02, 0.12, 0.32, "Dark"))
	table.insert(p, B("ChargingHandle", 0, recTop - 0.04, o.RecRear - 0.05, recW * 0.6, 0.06, 0.14, "Metal"))
	table.insert(p, B("BoltRelease", -recW / 2 - 0.01, recY - 0.05, recZ + 0.15, 0.02, 0.08, 0.12, "Metal"))
	local sightBase = recTop
	if o.RailTop ~= false then
		rail(p, recTop + 0.025, o.RecRear - 0.12, o.RecFront + 0.05, recW * 0.55)
		sightBase = recTop + 0.05
	end

	-- Guardamanos
	local hgH, hgW = o.HgH or 0.32, o.HgW or 0.3
	local hgY = o.HgY or by
	local hgBottom = hgY - hgH / 2
	if o.HgFront then
		local hgZ = (o.RecFront + o.HgFront) / 2
		local hgLen = o.RecFront - o.HgFront
		bevel(p, "Handguard", 0, hgY, hgZ, hgW, hgH, hgLen, o.HgRole or "Body")
		local slots = math.max(2, math.floor(hgLen / 0.28))
		for i = 0, slots - 1 do
			local z = o.RecFront - (i + 0.5) * hgLen / slots
			for _, s in { -1, 1 } do
				-- (o.Trim: las ranuras son ribetes que toman el color de la skin)
				table.insert(p, B("HgSlot", s * (hgW / 2 + 0.004), hgY + 0.02, z, 0.02, hgH * 0.3, 0.14, o.Trim and "Trim" or "Dark"))
			end
		end
		if o.HgRail then
			rail(p, hgY + hgH / 2 + 0.02, o.RecFront - 0.05, o.HgFront + 0.08, hgW * 0.5)
		end
	end

	-- Cañón y boca
	local barrelD = o.BarrelD or 0.11
	local deviceLen = muzzleDevice(p, o.Device, by, o.Muzzle.Z, barrelD)
	local barrelFront = o.Muzzle.Z + deviceLen
	local barrelBack = o.HgFront or o.RecFront
	if barrelBack > barrelFront then
		table.insert(p, C("Barrel", 0, by, (barrelBack + barrelFront) / 2, barrelBack - barrelFront + 0.05, barrelD, "Dark"))
	end

	-- Empuñadura, gatillo y cargador
	pistolGrip(p, o.Right, o.GripRole or "Body", o.GripSize, o.GripAngle)
	triggerGroup(p, recBottom, o.Right.Z - 0.3)
	local magZ = o.MagZ or (o.Right.Z - 0.62)
	if o.Mag == "Curved" then
		local m = {}
		bevelY(m, "Mag", 0, -0.22, 0, 0.2, 0.46, 0.34, "Dark")
		bevelY(m, "MagLower", 0, -0.5, -0.07, 0.2, 0.3, 0.32, "Dark")
		table.insert(m, B("MagBase", 0, -0.66, -0.1, 0.22, 0.05, 0.34, "Body"))
		for _, part in m do
			if part.Name:find("MagLower") or part.Name == "MagBase" then
				part.CFrame = CFrame.new(0, -0.36, 0) * CFrame.Angles(rad(-14), 0, 0) * CFrame.new(0, 0.36, 0) * part.CFrame
			end
		end
		add(p, Group(CFrame.new(0, recBottom + 0.02, magZ) * CFrame.Angles(rad(-6), 0, 0), m))
	elseif o.Mag == "Box" or o.Mag == "Straight" then
		local straight = o.Mag == "Straight"
		local m = {}
		bevelY(m, "Mag", 0, straight and -0.3 or -0.22, 0, straight and 0.17 or 0.21, straight and 0.6 or 0.44, straight and 0.2 or 0.34, "Dark")
		table.insert(m, B("MagBase", 0, straight and -0.62 or -0.46, 0, straight and 0.19 or 0.23, 0.05, straight and 0.22 or 0.36, "Body"))
		add(p, Group(CFrame.new(0, recBottom + 0.02, magZ) * CFrame.Angles(rad(straight and -4 or 0), 0, 0), m))
	elseif o.Mag == "Drum" then
		table.insert(p, CX("Drum", 0, recBottom - 0.3, magZ, 0.34, 0.62, "Dark"))
		table.insert(p, CX("DrumCap", 0.18, recBottom - 0.3, magZ, 0.03, 0.44, "Metal"))
		table.insert(p, B("DrumNeck", 0, recBottom - 0.03, magZ, 0.2, 0.08, 0.3, "Dark"))
	elseif o.Mag == "Belt" then
		bevel(p, "AmmoBox", -0.05, recBottom - 0.22, magZ, 0.42, 0.42, 0.48, "Panel")
		table.insert(p, B("AmmoBoxLid", -0.05, recBottom - 0.005, magZ, 0.44, 0.04, 0.5, "Dark"))
		for i = 0, 3 do
			table.insert(p, B("BeltRound", -0.19 + i * 0.03, recBottom + 0.03, magZ - 0.12 + i * 0.08, 0.04, 0.06, 0.06, "Gold"))
		end
	end

	-- Empuñadura delantera si la mano izquierda queda por debajo del guardamanos
	if o.Foregrip ~= false and o.Left and o.Left.Y < hgBottom - 0.06 then
		local top = hgBottom + 0.02
		local bottom = o.Left.Y - 0.12
		bevelY(p, "Foregrip", 0, (top + bottom) / 2, o.Left.Z, 0.16, top - bottom, 0.18, "Body")
	end

	-- Culata
	local stockRole = o.StockRole or "Body"
	if o.Stock == "Tube" then
		table.insert(p, C("BufferTube", 0, recY + 0.06, o.RecRear + 0.3, 0.6, 0.15, "Dark"))
		bevel(p, "Stock", 0, recY - 0.02, o.RecRear + 0.62, 0.24, 0.44, 0.5, stockRole)
		table.insert(p, B("ButtPad", 0, recY - 0.04, o.RecRear + 0.9, 0.26, 0.5, 0.07, "Rubber"))
	elseif o.Stock == "Solid" or o.Stock == "Wood" then
		local len = o.StockLen or 0.95
		local s = {}
		bevel(s, "Stock", 0, 0, len / 2, 0.26, 0.42, len, stockRole)
		bevel(s, "StockToe", 0, -0.2, len * 0.65, 0.24, 0.24, len * 0.7, stockRole)
		table.insert(s, B("CheekRiser", 0, 0.24, len * 0.45, 0.2, 0.08, len * 0.5, o.Stock == "Wood" and stockRole or "Rubber"))
		table.insert(s, B("ButtPad", 0, -0.08, len + 0.03, 0.27, 0.58, 0.07, "Rubber"))
		add(p, Group(CFrame.new(0, recY - 0.02, o.RecRear - 0.02) * CFrame.Angles(rad(o.StockDrop or 4), 0, 0), s))
	end

	-- Miras
	local sightZ = o.SightZ or (o.Aim.Z - 0.7)
	if o.Sight == "Dot" then
		redDot(p, o.Aim, sightZ, sightBase)
	elseif o.Sight == "Holo" then
		holo(p, o.Aim, sightZ, sightBase)
	elseif o.Sight == "Scope" then
		scope(p, o.Aim, sightZ, sightBase, o.ScopeLen, o.ScopeBell)
	elseif o.Sight == "Iron" then
		ironSights(p, o.Aim, o.Aim.Z - 0.25, o.Muzzle.Z + deviceLen + 0.15, by + barrelD / 2)
	end

	-- Bípode plegado bajo el guardamanos
	if o.Bipod and o.HgFront then
		local z = o.HgFront + 0.12
		table.insert(p, B("BipodMount", 0, hgBottom - 0.03, z, 0.18, 0.06, 0.12, "Dark"))
		for _, s in { -1, 1 } do
			table.insert(p, B("BipodLeg", s * 0.06, hgBottom - 0.06, z + 0.35, 0.05, 0.05, 0.7, "Dark"))
			table.insert(p, B("BipodFoot", s * 0.06, hgBottom - 0.06, z + 0.72, 0.07, 0.07, 0.06, "Rubber"))
		end
	end
	return p
end

---------------------------------------------------------------------------
-- Constructor de pistolas
---------------------------------------------------------------------------
local function pistol(o)
	local p = {}
	local sy = o.SlideY or o.Muzzle.Y
	local sh = o.SlideH or 0.24
	local slideFront = o.Muzzle.Z + (o.Comp and 0.2 or 0.06)
	local slideBack = o.SlideBack or 0.58
	table.insert(p, B("Handle", 0, 0, 0, 0.18, 0.18, 0.18, "Body"))
	bevel(p, "Slide", 0, sy, (slideBack + slideFront) / 2, 0.23, sh, slideBack - slideFront, "Panel", 0.05)
	for i = 0, 4 do
		table.insert(p, B("Serration", 0, sy + 0.01, slideBack - 0.06 - i * 0.05, 0.235, sh * 0.7, 0.02, "Dark"))
	end
	table.insert(p, B("EjectionPort", 0.116, sy + 0.04, slideBack - 0.45, 0.01, 0.08, 0.2, "Dark"))
	local frameY = sy - sh / 2 - 0.07
	bevel(p, "Frame", 0, frameY, (slideBack + slideFront) / 2 + 0.04, 0.21, 0.15, slideBack - slideFront - 0.06, "Body", 0.04)
	table.insert(p, C("BarrelTip", 0, o.Muzzle.Y, slideFront - 0.01, 0.04, 0.11, "Dark"))
	if o.Comp then
		table.insert(p, B("Compensator", 0, sy, o.Muzzle.Z + 0.1, 0.24, sh, 0.2, "Dark"))
		table.insert(p, B("CompPort", 0, sy + sh / 2, o.Muzzle.Z + 0.1, 0.1, 0.02, 0.12, "Body"))
	end
	table.insert(p, B("Hammer", 0, sy + 0.02, slideBack + 0.03, 0.06, 0.1, 0.06, "Metal", -20, 0, 0))
	triggerGroup(p, frameY - 0.03, o.Right.Z - 0.3)
	pistolGrip(p, o.Right, o.GripRole or "Body", V(0.22, 0.62, 0.3), o.GripAngle or 16)
	if o.Dot then
		redDot(p, o.Aim, slideBack - 0.3, sy + sh / 2, 0.2)
	else
		for _, s in { -1, 1 } do
			table.insert(p, B("RearSightPost", s * 0.06, o.Aim.Y - 0.02, slideBack - 0.07, 0.045, 0.08, 0.06, "Dark"))
		end
		local postTop = o.Aim.Y - 0.04
		local base = sy + sh / 2
		if postTop > base then
			table.insert(p, B("FrontSightPost", 0, (base + postTop) / 2, slideFront + 0.08, 0.04, postTop - base, 0.05, "Dark"))
		end
		table.insert(p, B("FrontSightBead", 0, o.Aim.Y - 0.02, slideFront + 0.08, 0.03, 0.05, 0.04, "Accent"))
	end
	return p
end

---------------------------------------------------------------------------
-- Diseños (los puntos son los de cada arma en Weapons)
---------------------------------------------------------------------------

-- Fusil de asalto tipo M4 con punto rojo, empuñadura delantera y culata telescópica
function Classic.ARX27(pt)
	return rifle({
		Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle,
		RecRear = 0.75, RecFront = -0.55, RecY = 0.06, RecH = 0.44,
		HgFront = -1.75, HgH = 0.3, HgRail = true,
		Device = "Flash", Mag = "Curved", Stock = "Tube", StockRole = "Panel", Sight = "Dot",
		Trim = true, -- (arma de referencia: las ranuras del guardamanos llevan el acento de la skin)
	})
end

-- Escopeta de corredera: cañón y depósito tubular, corredera y culata de madera
function Classic.HavocPump(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local p = rifle({
		Aim = o.Aim, Right = o.Right, Left = o.Left, Muzzle = o.Muzzle,
		RecRear = 0.82, RecFront = -0.35, RecY = 0.06, RecH = 0.44, RecW = 0.3, RailTop = false,
		BarrelD = 0.17, Device = nil, Mag = nil, Stock = "Wood", StockRole = "Panel", StockLen = 1.0, StockDrop = 6,
		GripRole = "Panel", Sight = nil, Foregrip = false,
	})
	table.insert(p, C("MagTube", 0, -0.1, -1.2, 1.7, 0.14, "Dark"))
	table.insert(p, B("VentRib", 0, 0.23, -1.36, 0.06, 0.03, 2.0, "Dark"))
	-- Corredera de madera con estrías
	bevel(p, "Pump", 0, -0.16, o.Left.Z, 0.26, 0.32, 0.72, "Panel")
	for i = 0, 4 do
		table.insert(p, B("PumpGroove", 0, -0.16, o.Left.Z - 0.28 + i * 0.14, 0.27, 0.24, 0.03, "Dark"))
	end
	-- Alza tipo anillo y punto de mira de cuenta
	for _, s in { -1, 1 } do
		table.insert(p, B("GhostRingPost", s * 0.07, o.Aim.Y - 0.04, o.Aim.Z - 0.3, 0.04, 0.2, 0.06, "Dark"))
	end
	table.insert(p, B("GhostRingBase", 0, (0.28 + o.Aim.Y - 0.14) / 2, o.Aim.Z - 0.3, 0.2, o.Aim.Y - 0.14 - 0.28 + 0.03, 0.1, "Dark"))
	table.insert(p, B("FrontSightPost", 0, (0.24 + o.Aim.Y - 0.05) / 2, o.Muzzle.Z + 0.12, 0.04, o.Aim.Y - 0.05 - 0.24, 0.05, "Dark"))
	table.insert(p, B("FrontSightBead", 0, o.Aim.Y - 0.02, o.Muzzle.Z + 0.12, 0.04, 0.05, 0.05, "Accent"))
	table.insert(p, B("ShellLatch", 0, -0.16, 0.1, 0.12, 0.04, 0.3, "Metal"))
	for i = 0, 2 do
		table.insert(p, B("SideShell", -0.17, 0.0 - i * 0.0, 0.5 - i * 0.12, 0.05, 0.09, 0.1, "Shell"))
	end
	return p
end

-- Subfusil tipo MP5: alza de tambor, punto de mira encapuchado y culata retráctil
function Classic.Specter9(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local p = rifle({
		Aim = o.Aim, Right = o.Right, Left = o.Left, Muzzle = o.Muzzle,
		RecRear = 0.7, RecFront = -0.45, RecY = 0.02, RecH = 0.4, RecW = 0.28, RailTop = false,
		HgFront = -1.05, HgH = 0.34, HgW = 0.3, HgY = 0.0,
		BarrelD = 0.1, Device = "Flash", Mag = "Straight", Stock = "Tube", Sight = nil,
	})
	-- Alza de tambor (anillo hueco) y punto de mira encapuchado
	table.insert(p, B("DiopterBase", 0, (0.22 + o.Aim.Y - 0.08) / 2, o.Aim.Z, 0.16, o.Aim.Y - 0.08 - 0.22 + 0.02, 0.12, "Dark"))
	tube(p, "Diopter", 0, o.Aim.Y, o.Aim.Z, 0.1, 0.16, "Dark", 0.04)
	table.insert(p, B("FrontHoodBase", 0, (0.17 + o.Aim.Y - 0.08) / 2, -0.95, 0.12, o.Aim.Y - 0.08 - 0.17 + 0.02, 0.1, "Dark"))
	tube(p, "FrontHood", 0, o.Aim.Y, -0.95, 0.08, 0.16, "Dark", 0.035)
	table.insert(p, B("FrontSightBead", 0, o.Aim.Y - 0.035, -0.95, 0.025, 0.05, 0.03, "Accent"))
	table.insert(p, B("CockingTube", 0, 0.16, -0.85, 0.12, 0.1, 0.5, "Dark"))
	table.insert(p, B("CockingLever", -0.1, 0.16, -0.75, 0.06, 0.05, 0.1, "Metal"))
	return p
end

-- Francotirador de cerrojo con culata de madera, mira grande y bípode
function Classic.Signal7(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local p = rifle({
		Aim = o.Aim, Right = o.Right, Left = o.Left, Muzzle = o.Muzzle,
		RecRear = 0.95, RecFront = -0.45, RecY = 0.07, RecH = 0.34, RecW = 0.26, RailTop = false,
		HgFront = -1.95, HgH = 0.3, HgW = 0.28, HgY = -0.06, HgRole = "Panel",
		BarrelD = 0.15, Device = "Brake", Mag = "Box", MagZ = 0.05, Stock = "Wood", StockRole = "Panel", StockLen = 1.1,
		GripRole = "Panel", Sight = "Scope", SightZ = 0.0, ScopeLen = 1.0, Bipod = true, Foregrip = false,
	})
	table.insert(p, CX("BoltHandle", 0.22, 0.12, 0.72, 0.3, 0.06, "Metal"))
	table.insert(p, Ball("BoltKnob", 0.38, 0.1, 0.72, 0.13, "Dark"))
	table.insert(p, C("BoltShroud", 0, 0.1, 0.98, 0.12, 0.16, "Dark"))
	return p
end

-- Fusil de ráfaga tipo SCAR en color arena con mira holográfica
function Classic.VortexBR(pt)
	return rifle({
		Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle,
		RecRear = 0.75, RecFront = -0.5, RecY = 0.07, RecH = 0.46, RecW = 0.32,
		HgFront = -1.6, HgH = 0.34, HgW = 0.32, HgRail = true,
		Device = "Brake", Mag = "Box", Stock = "Solid", StockLen = 0.85, Sight = "Holo",
	})
end

-- Subfusil compacto tipo UMP con punto rojo y supresor
function Classic.NovaDrift(pt)
	return rifle({
		Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle,
		RecRear = 0.62, RecFront = -0.55, RecY = 0.02, RecH = 0.48, RecW = 0.3,
		HgFront = -0.95, HgH = 0.36, HgW = 0.3, HgY = 0.0,
		BarrelD = 0.1, Device = "Suppressor", Mag = "Straight", Stock = "Solid", StockLen = 0.7, StockRole = "Panel",
		Sight = "Dot",
	})
end

-- Fusil de tirador con madera, mira corta y freno de boca
function Classic.RaptorDMR(pt)
	return rifle({
		Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle,
		RecRear = 0.8, RecFront = -0.5, RecY = 0.04, RecH = 0.42, RecW = 0.3,
		HgFront = -1.65, HgH = 0.34, HgW = 0.3, HgRole = "Panel",
		BarrelD = 0.11, Device = "Brake", Mag = "Box", Stock = "Wood", StockRole = "Panel", StockLen = 0.95,
		GripRole = "Panel", Sight = "Scope", ScopeLen = 0.62, ScopeBell = 0.3, Foregrip = false,
	})
end

-- Escopeta automática pesada con tambor y guardamanos ventilado
function Classic.BreachHammer(pt)
	local p = rifle({
		Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle,
		RecRear = 0.85, RecFront = -0.45, RecY = 0.04, RecH = 0.54, RecW = 0.36, RailTop = false,
		HgFront = -1.75, HgH = 0.4, HgW = 0.36, HgY = 0.06,
		BarrelD = 0.17, Device = "Brake", Mag = "Drum", MagZ = 0.0, Stock = "Solid", StockLen = 0.8,
		Sight = "Iron",
	})
	table.insert(p, B("CarryRail", 0, 0.34, 0.2, 0.12, 0.06, 0.9, "Dark"))
	return p
end

-- Ametralladora ligera tipo M249: caja de munición, escudo térmico, asa y bípode
function Classic.TitanLMG(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local p = rifle({
		Aim = o.Aim, Right = o.Right, Left = o.Left, Muzzle = o.Muzzle,
		RecRear = 0.9, RecFront = -0.6, RecY = 0.06, RecH = 0.54, RecW = 0.36,
		HgFront = -1.45, HgH = 0.36, HgW = 0.34, HgY = 0.06,
		BarrelD = 0.13, Device = "Flash", Mag = "Belt", MagZ = -0.15, Stock = "Solid", StockLen = 0.9,
		Sight = "Dot", Bipod = true,
	})
	table.insert(p, B("FeedCover", 0, 0.36, 0.1, 0.34, 0.06, 0.8, "Dark"))
	table.insert(p, B("HeatShield", 0, 0.16, -1.75, 0.18, 0.06, 0.55, "Panel"))
	table.insert(p, B("CarryHandle", -0.2, 0.3, -0.85, 0.05, 0.05, 0.5, "Dark"))
	table.insert(p, B("CarryHandleArm", -0.2, 0.2, -0.65, 0.05, 0.2, 0.05, "Dark"))
	return p
end

-- Francotirador pesado tipo Barrett: freno grande, mira, bípode y monópode
function Classic.GhostlineXR(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local p = rifle({
		Aim = o.Aim, Right = o.Right, Left = o.Left, Muzzle = o.Muzzle,
		RecRear = 1.15, RecFront = -0.6, RecY = 0.04, RecH = 0.46, RecW = 0.32,
		HgFront = -1.95, HgH = 0.36, HgW = 0.32, HgRail = true,
		BarrelD = 0.18, Device = "Brake", Mag = "Box", MagZ = 0.0, Stock = "Solid", StockLen = 0.85, StockRole = "Panel",
		Sight = "Scope", SightZ = -0.05, ScopeLen = 1.1, ScopeBell = 0.4, Bipod = true, Foregrip = false,
	})
	table.insert(p, B("Monopod", 0, -0.42, 1.6, 0.08, 0.3, 0.08, "Dark"))
	return p
end

-- Lanzacohetes tipo RPG: tubo, escudo térmico de madera, cohete y alza
function Classic.NovaLauncher(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local y = o.Muzzle.Y
	local p = {
		B("Handle", 0, 0, 0, 0.2, 0.2, 0.2, "Body"),
		C("Tube", 0, y, 0.15, 2.4, 0.3, "Body"),
		C("Flare", 0, y, 1.45, 0.4, 0.42, "Body"),
		C("FlareLip", 0, y, 1.66, 0.04, 0.44, "Dark"),
		C("HeatShield", 0, y, -0.05, 0.9, 0.36, "Accent2"),
		C("HeatBandA", 0, y, -0.5, 0.05, 0.38, "Dark"),
		C("HeatBandB", 0, y, 0.4, 0.05, 0.38, "Dark"),
		-- Cohete asomando por delante
		C("RocketNeck", 0, y, -1.15, 0.3, 0.2, "Dark"),
		C("Warhead", 0, y, -1.55, 0.55, 0.46, "Panel"),
		C("WarheadCone", 0, y, -1.98, 0.34, 0.3, "Panel"),
		C("WarheadTip", 0, y, -2.25, 0.25, 0.14, "Dark"),
		C("RocketFins", 0, y, -1.0, 0.06, 0.34, "Dark"),
		B("TriggerHousing", 0, y - 0.2, o.Right.Z - 0.25, 0.1, 0.16, 0.42, "Dark"),
	}
	triggerGroup(p, y - 0.24, o.Right.Z - 0.3)
	pistolGrip(p, o.Right, "Body")
	-- Empuñadura delantera bajo el tubo
	bevelY(p, "Foregrip", 0, (y - 0.15 + o.Left.Y - 0.12) / 2, o.Left.Z, 0.16, (y - 0.15) - (o.Left.Y - 0.12), 0.18, "Body")
	-- Alza plegable y punto de mira
	for _, s in { -1, 1 } do
		table.insert(p, B("RearSightPost", s * 0.065, o.Aim.Y - 0.03, o.Aim.Z - 0.3, 0.045, 0.14, 0.06, "Dark"))
	end
	table.insert(p, B("RearSightBase", 0, (y + 0.15 + o.Aim.Y - 0.1) / 2, o.Aim.Z - 0.3, 0.18, o.Aim.Y - 0.1 - y - 0.15 + 0.02, 0.08, "Dark"))
	table.insert(p, B("FrontSightPost", 0, (y + 0.15 + o.Aim.Y - 0.06) / 2, -0.75, 0.05, o.Aim.Y - 0.06 - y - 0.15, 0.06, "Dark"))
	table.insert(p, B("FrontSightBead", 0, o.Aim.Y - 0.03, -0.75, 0.03, 0.06, 0.04, "Accent"))
	return p
end

-- Pistola de polímero
function Classic.Viper(pt)
	return pistol({ Aim = pt.AimPoint, Right = pt.RightHand, Muzzle = pt.Muzzle, SlideY = 0.05, SlideH = 0.24, SlideBack = 0.55 })
end

-- Pistola táctica con compensador y punto rojo
function Classic.PhantomSidewind(pt)
	return pistol({ Aim = pt.AimPoint, Right = pt.RightHand, Muzzle = pt.Muzzle, SlideY = 0.0, SlideH = 0.26, SlideBack = 0.6, Comp = true, Dot = true })
end

-- Revólver de cañón largo con cachas de madera
function Classic.HandCannon(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Muzzle = pt.Muzzle }
	local p = { B("Handle", 0, 0, 0, 0.18, 0.18, 0.18, "Body") }
	bevel(p, "Frame", 0, 0.04, 0.1, 0.24, 0.38, 0.62, "Body", 0.05)
	table.insert(p, C("Cylinder", 0, 0.02, -0.06, 0.4, 0.46, "Body"))
	for i = 0, 5 do
		local a = rad(i * 60)
		table.insert(p, C("CylinderFlute", math.sin(a) * 0.2, 0.02 + math.cos(a) * 0.2, -0.06, 0.3, 0.08, "Dark"))
	end
	bevel(p, "Barrel", 0, 0.08, -0.82, 0.18, 0.22, 1.1, "Body", 0.04)
	table.insert(p, B("TopRib", 0, 0.205, -0.82, 0.09, 0.05, 1.1, "Body"))
	table.insert(p, C("EjectorHousing", 0, -0.08, -0.62, 0.7, 0.1, "Body"))
	table.insert(p, C("Bore", 0, o.Muzzle.Y, o.Muzzle.Z + 0.02, 0.04, 0.12, "Dark"))
	table.insert(p, B("Hammer", 0, 0.17, 0.4, 0.07, 0.12, 0.1, "Metal", -25, 0, 0))
	triggerGroup(p, -0.15, o.Right.Z - 0.32)
	pistolGrip(p, o.Right, "Panel", V(0.22, 0.6, 0.3), 22)
	for _, s in { -1, 1 } do
		table.insert(p, B("RearSightPost", s * 0.055, o.Aim.Y - 0.02, 0.3, 0.04, 0.08, 0.05, "Dark"))
	end
	table.insert(p, B("FrontSightPost", 0, (0.23 + o.Aim.Y - 0.04) / 2, -1.3, 0.04, o.Aim.Y - 0.04 - 0.23, 0.08, "Dark"))
	table.insert(p, B("FrontSightBead", 0, o.Aim.Y - 0.02, -1.3, 0.03, 0.05, 0.06, "Accent"))
	return p
end

-- Marcadora de paintball: cuerpo de color, depósito de bolas arriba a la izquierda (deja libre la
-- línea de mira), cañón largo con bandas, botella de aire detrás y empuñadura delantera
function Classic.SplatX(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local y = o.Muzzle.Y
	local p = { B("Handle", 0, 0, 0, 0.2, 0.2, 0.2, "Body") }
	bevel(p, "Body", 0, 0.05, 0.05, 0.26, 0.34, 0.9, "Body", 0.06)
	table.insert(p, B("BodyStripe", 0, 0.05, 0.05, 0.27, 0.06, 0.92, "Accent"))
	table.insert(p, C("Barrel", 0, y, (o.Muzzle.Z - 0.4) / 2, -o.Muzzle.Z - 0.4, 0.13, "Dark"))
	for i = 0, 2 do
		table.insert(p, C("BarrelBand", 0, y, -0.65 - i * 0.28, 0.06, 0.16, "Panel"))
	end
	table.insert(p, C("BarrelTip", 0, y, o.Muzzle.Z + 0.06, 0.12, 0.17, "Accent"))
	-- Depósito de bolas con cuello inclinado y bolas asomando
	-- (más a la izquierda y más bajo para no tapar media pantalla al apuntar)
	table.insert(p, B("FeedNeck", -0.24, 0.27, -0.1, 0.1, 0.3, 0.12, "Dark", 0, 0, 50))
	table.insert(p, Ball("Hopper", -0.46, 0.4, -0.1, 0.46, "Accent2"))
	table.insert(p, CY("HopperRing", -0.46, 0.4, -0.1, 0.08, 0.48, "Dark"))
	table.insert(p, CY("HopperLid", -0.46, 0.61, -0.1, 0.06, 0.28, "Dark"))
	-- Bolas de pintura asomando por arriba
	for i, off in { V(-0.07, 0, 0.06), V(0.07, 0.01, -0.03), V(-0.01, 0.03, -0.09) } do
		table.insert(p, Ball("PaintBall" .. i, -0.46 + off.X, 0.68 + off.Y, -0.1 + off.Z, 0.12, "Accent"))
	end
	-- Botella de aire detrás (hace de culata)
	table.insert(p, C("AirTank", 0, -0.02, 0.85, 0.66, 0.26, "Panel"))
	table.insert(p, C("AirTankCap", 0, -0.02, 1.2, 0.06, 0.2, "Metal"))
	table.insert(p, C("Regulator", 0, -0.02, 0.5, 0.12, 0.18, "Metal"))
	triggerGroup(p, -0.12, o.Right.Z - 0.3)
	pistolGrip(p, o.Right, "Rubber")
	-- Empuñadura delantera
	bevelY(p, "Foregrip", 0, (-0.12 + o.Left.Y - 0.1) / 2, o.Left.Z, 0.15, -0.12 - (o.Left.Y - 0.1), 0.17, "Rubber")
	table.insert(p, B("ForegripMount", 0, -0.08, o.Left.Z, 0.12, 0.1, 0.3, "Dark"))
	ironSights(p, o.Aim, 0.3, -1.25, y + 0.065)
	return p
end

-- Katana: mango largo con cinta, tsuba redonda y hoja larga con una leve curva (hacia -Z)
function Classic.Katana(_pt)
	local p = { B("Handle", 0, 0, 0.1, 0.16, 0.2, 0.9, "Rubber") }
	for i = 0, 4 do
		table.insert(p, B("Wrap" .. i, 0, 0, 0.42 - i * 0.16, 0.17, 0.21, 0.05, "Panel", 0, 0, 45))
	end
	table.insert(p, B("Pommel", 0, 0, 0.58, 0.18, 0.22, 0.06, "Dark"))
	table.insert(p, C("Tsuba", 0, 0, -0.38, 0.06, 0.46, "Dark"))
	table.insert(p, B("Habaki", 0, 0.01, -0.45, 0.08, 0.2, 0.1, "Metal"))
	-- Hoja de acero claro (Accent) y filo metálico
	table.insert(p, B("Blade", 0, 0.02, -1.3, 0.05, 0.2, 1.7, "Accent"))
	table.insert(p, B("BladeTip", 0, 0.07, -2.38, 0.05, 0.18, 0.5, "Accent", 8, 0, 0))
	table.insert(p, B("Point", 0, 0.12, -2.68, 0.05, 0.1, 0.18, "Accent", 30, 0, 0))
	table.insert(p, B("Edge", 0, -0.06, -1.3, 0.055, 0.04, 1.66, "Metal"))
	return p
end

-- Martillo de juguete (de los que pitan): mango de rayas y cabeza grande de colores
function Classic.ToyHammer(_pt)
	local p = { B("Handle", 0, 0, 0.0, 0.18, 0.18, 1.0, "Panel") }
	for i = 0, 2 do
		table.insert(p, C("HandleStripe" .. i, 0, 0, 0.3 - i * 0.3, 0.1, 0.2, "Accent2"))
	end
	table.insert(p, C("Grip", 0, 0, 0.45, 0.3, 0.22, "Rubber"))
	table.insert(p, CX("Head", 0, 0, -0.75, 1.0, 0.62, "Body"))
	for _, x in { -0.52, 0.52 } do
		table.insert(p, CX("HeadCap", x, 0, -0.75, 0.08, 0.66, "Accent"))
	end
	table.insert(p, CX("HeadBand", 0, 0, -0.75, 0.16, 0.64, "Accent2"))
	return p
end

-- Guadaña (Halloween): mango largo de madera oscura con anillas y una hoja curva que sale hacia
-- un lado en la punta y se curva hacia el mango, con el filo morado brillante por dentro
function Classic.Scythe(_pt)
	local p = {
		B("Handle", 0, 0, -0.35, 0.13, 0.13, 2.3, "Body"),
		B("Grip", 0, 0, 0.55, 0.16, 0.16, 0.5, "Rubber"),
		B("Pommel", 0, 0, 0.85, 0.2, 0.2, 0.12, "Dark"),
	}
	for i, z in { -0.2, -1.1 } do
		table.insert(p, B("ShaftRing" .. i, 0, 0, z, 0.17, 0.17, 0.08, "Accent2"))
	end
	table.insert(p, B("BladeMount", 0, 0, -1.55, 0.2, 0.22, 0.2, "Dark"))
	-- Hoja: tramos cada vez más girados (curva hacia +X y hacia atrás)
	local x, z, angle = 0.1, -1.55, 0
	for i = 1, 5 do
		local length = 0.42 - i * 0.03
		local rad = math.rad(angle)
		local cx, cz = x + math.cos(rad) * length / 2, z - math.sin(rad) * length / 2
		table.insert(p, B("Blade" .. i, cx, 0, cz, length, 0.05, 0.3 - i * 0.035, "Accent", 0, angle, 0))
		table.insert(p, B("BladeEdge" .. i, cx + math.sin(rad) * (0.15 - i * 0.017), 0, cz + math.cos(rad) * (0.15 - i * 0.017), length, 0.055, 0.04, "Accent2", 0, angle, 0))
		x, z = x + math.cos(rad) * length, z - math.sin(rad) * length
		angle -= 16
	end
	return p
end

-- Calabazooka (evento de Halloween): el lanzacohetes con una calabaza con cara como proyectil
function Classic.Calabazooka(pt)
	local p = {}
	for _, part in Classic.NovaLauncher(pt) do
		if part.Name ~= "Warhead" and part.Name ~= "WarheadCone" and part.Name ~= "WarheadTip" and part.Name ~= "RocketFins" then
			table.insert(p, part)
		end
	end
	local y = pt.Muzzle.Y
	table.insert(p, C("PumpkinNeck", 0, y, -1.5, 0.4, 0.16, "Dark"))
	table.insert(p, Ball("Pumpkin", 0, y, -1.95, 0.62, "Panel"))
	table.insert(p, C("PumpkinStem", 0, y + 0.34, -1.95, 0.06, 0.08, "Accent2"))
	table.insert(p, B("PumpkinStemTop", 0, y + 0.38, -1.95, 0.06, 0.14, 0.06, "Accent2"))
	for _, x in { -0.11, 0.11 } do
		table.insert(p, B("PumpkinEye", x, y + 0.08, -2.24, 0.1, 0.09, 0.04, "Accent", 0, 0, x > 0 and 20 or -20))
	end
	table.insert(p, B("PumpkinMouth", 0, y - 0.1, -2.24, 0.26, 0.06, 0.04, "Accent"))
	return p
end

-- Garras de zombi (modo Infección): mano verde con tres uñas de hueso largas y curvas
function Classic.Claws(_pt)
	local p = {
		B("Handle", 0, 0, 0.15, 0.34, 0.26, 0.5, "Body"),
		B("Wrist", 0, -0.02, 0.48, 0.3, 0.24, 0.2, "Dark"),
		B("Knuckles", 0, 0.06, -0.12, 0.4, 0.2, 0.16, "Body"),
	}
	for i, x in { -0.13, 0, 0.13 } do
		local spread = (i - 2) * 6
		table.insert(p, B("ClawBase" .. i, x, 0.06, -0.38, 0.07, 0.09, 0.4, "Accent", -6, spread, 0))
		table.insert(p, B("ClawTip" .. i, x * 1.25, 0.0, -0.72, 0.05, 0.07, 0.34, "Accent", -22, spread, 0))
		table.insert(p, B("Blood" .. i, x * 1.3, -0.04, -0.86, 0.055, 0.06, 0.1, "Accent2", -22, spread, 0))
	end
	return p
end

-- Puntos que cambian respecto al diseño original (el lanzacohetes se coge por el tubo, no por el cohete)
-- Ballesta: culata y cuerpo de madera, arco de metal con su cuerda, virote con punta roja y
-- estribo delante. Sin cargador (un virote cada vez).
function Classic.Crossbow(pt)
	local o = { Aim = pt.AimPoint, Right = pt.RightHand, Left = pt.LeftHand, Muzzle = pt.Muzzle }
	local y = o.Muzzle.Y
	local p = rifle({
		Aim = o.Aim, Right = o.Right, Left = o.Left, Muzzle = o.Muzzle,
		RecRear = 0.55, RecFront = -0.35, RecY = 0.0, RecH = 0.3, RecW = 0.24, RecRole = "Body", RailTop = false,
		HgFront = -1.45, HgH = 0.22, HgW = 0.22, HgY = -0.02, HgRole = "Body",
		BarrelD = 0.05, Stock = "Wood", StockRole = "Body", StockLen = 0.8,
		GripRole = "Body", Foregrip = false,
	})
	-- Arco: dos palas inclinadas hacia atrás desde la punta
	local prodZ = -1.3
	for _, s in { -1, 1 } do
		table.insert(p, B("BowLimb", s * 0.52, y + 0.02, prodZ + 0.13, 0.98, 0.08, 0.11, "Panel", 0, s * -14, 0))
		table.insert(p, B("BowTip", s * 0.99, y + 0.02, prodZ + 0.26, 0.06, 0.12, 0.08, "Dark"))
		-- Cuerda tensa hasta la nuez (detrás, sobre el cuerpo)
		local tip = V(s * 0.99, y + 0.02, prodZ + 0.26)
		local nut = V(s * 0.04, y + 0.04, -0.15)
		local mid = (tip + nut) / 2
		local len = (tip - nut).Magnitude
		local yaw = math.deg(math.atan2(tip.X - nut.X, tip.Z - nut.Z))
		table.insert(p, B("BowString", mid.X, mid.Y, mid.Z, 0.025, 0.025, len, "Dark", 0, yaw, 0))
	end
	table.insert(p, B("BowRiser", 0, y + 0.02, prodZ, 0.26, 0.14, 0.14, "Panel"))
	-- Virote cargado: varilla, punta roja y plumas
	table.insert(p, C("Bolt", 0, y + 0.1, -0.85, 1.3, 0.04, "Dark"))
	table.insert(p, B("BoltTip", 0, y + 0.1, -1.53, 0.07, 0.07, 0.12, "Accent", 45, 0, 0))
	for _, s in { -1, 1 } do
		table.insert(p, B("BoltFletch", s * 0.035, y + 0.11, -0.28, 0.01, 0.06, 0.16, "Accent"))
	end
	-- Estribo delante (para tensar)
	table.insert(p, B("StirrupL", -0.12, y - 0.12, prodZ - 0.12, 0.03, 0.2, 0.03, "Panel"))
	table.insert(p, B("StirrupR", 0.12, y - 0.12, prodZ - 0.12, 0.03, 0.2, 0.03, "Panel"))
	table.insert(p, B("StirrupBottom", 0, y - 0.22, prodZ - 0.12, 0.27, 0.03, 0.03, "Panel"))
	ironSights(p, o.Aim, 0.35, -1.0, y + 0.06)
	return p
end

Classic.Points = {
	NovaLauncher = { LeftHand = V(0, -0.4, -0.7) },
	Calabazooka = { LeftHand = V(0, -0.4, -0.7) },
}

return Classic
