-- Props reutilizables de los mapas 5v5. Cada prop está pensado para dar escala, cobertura o
-- identidad de zona con pocas piezas (una caja = 1 pieza que choca + 2-3 detalles que no).
-- cf = centro de la base, mirando a -Z (la "cara" del prop).
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local P = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local get = Materials.get
local M = Enum.Material

---------------------------------------------------------------------------
-- Cobertura
---------------------------------------------------------------------------

-- Contenedor de 20 x 8,5 x 8 (cobertura alta). look = color del contenedor
function P.container(cf, look, label)
	look = get(look or "ContainerRed")
	return Kit.container(cf, look[1], label)
end

-- Caja de madera (size de lado)
function P.crate(cf, size)
	return Kit.crate(cf, size or 4)
end

-- Montón de cajas: "L" (2 abajo + 1 arriba, cobertura media con asomada por arriba) o "Wall"
-- (3 en fila, cobertura baja) o "Tower" (2 apiladas, cobertura alta)
function P.crateStack(cf, kind)
	kind = kind or "L"
	local crates = {}
	local function add(c)
		table.insert(crates, c)
	end
	if kind == "Wall" then
		for i = -1, 1 do
			add(P.crate(cf * CFrame.new(i * 4.1, 0, 0) * CFrame.Angles(0, rad(i * 4), 0), 4))
		end
	elseif kind == "Tower" then
		add(P.crate(cf, 4.5))
		add(P.crate(cf * CFrame.new(0.2, 4.5, 0.1) * CFrame.Angles(0, rad(12), 0), 4))
	else
		add(P.crate(cf * CFrame.new(-2.2, 0, 0), 4.2))
		add(P.crate(cf * CFrame.new(2.2, 0, 0.3) * CFrame.Angles(0, rad(-6), 0), 4))
		add(P.crate(cf * CFrame.new(-1.6, 4.2, 0.2) * CFrame.Angles(0, rad(10), 0), 3.4))
	end
	return crates
end

-- Palé de madera (decorado, a ras de suelo)
function P.pallet(cf, sx, sz)
	sx, sz = sx or 4.4, sz or 4.4
	G.deco("Pallet", V(sx, 0.5, sz), cf * CFrame.new(0, 0.25, 0), { RGB(170, 132, 86), M.WoodPlanks })
end

-- Palé con bloques de hormigón apilados (cobertura: layers 2 = baja, 3 = media)
function P.blockPallet(cf, layers)
	layers = layers or 3
	P.pallet(cf)
	local h = layers * 1.25
	local body = G.box("BlockStack", V(4.2, h, 4.2), cf * CFrame.new(0, 0.5 + h / 2, 0), "Block")
	Kit.contactShadow(cf, 4.4, 4.4)
	-- Juntas entre hiladas y fleje
	for l = 1, layers - 1 do
		G.deco("BlockJoint", V(4.26, 0.1, 4.26), cf * CFrame.new(0, 0.5 + l * 1.25, 0), "ConcreteDark")
	end
	G.deco("Strap", V(0.15, h + 0.1, 4.3), cf * CFrame.new(0.9, 0.5 + h / 2, 0), { RGB(40, 60, 120), M.SmoothPlastic })
	return body
end

-- Barrera de hormigón tipo "new jersey" (cobertura baja, 3 de alto)
function P.jersey(cf, length, look)
	length = length or 8
	look = look or "Concrete"
	local base = G.box("Jersey", V(2.4, 1.2, length), cf * CFrame.new(0, 0.6, 0), look)
	G.box("JerseyTop", V(1.2, 1.9, length), cf * CFrame.new(0, 2.15, 0), look)
	G.deco("JerseyStripe", V(1.26, 0.5, length * 0.98), cf * CFrame.new(0, 2.6, 0), "YellowPaint")
	Kit.contactShadow(cf, 2.6, length)
	return base
end

-- Bidón metálico y barril de plástico
function P.barrel(cf, look)
	look = get(look or { RGB(50, 90, 160), M.Metal })
	Kit.barrel(cf, look[1])
end

function P.cone(cf)
	Kit.cone(cf)
end

-- Fila de conos
function P.cones(a, b, count)
	for i = 0, count - 1 do
		P.cone(CFrame.new(a:Lerp(b, count > 1 and i / (count - 1) or 0.5)))
	end
end

---------------------------------------------------------------------------
-- Obra
---------------------------------------------------------------------------

-- Caseta de obra (oficina prefabricada) de 20 x 9 x 8: cobertura alta y escala. Ventanas a -Z.
function P.portacabin(cf, look, opts)
	opts = opts or {}
	look = get(look or { RGB(232, 228, 216), M.SmoothPlastic })
	local body = G.box("Portacabin", V(20, 8.6, 8), cf * CFrame.new(0, 4.6, 0), look)
	Kit.contactShadow(cf, 20.4, 8.4)
	G.deco("CabinBase", V(20.4, 0.4, 8.4), cf * CFrame.new(0, 0.2, 0), "SteelDark")
	G.deco("CabinRoof", V(20.4, 0.4, 8.4), cf * CFrame.new(0, 9.1, 0), "SteelDark")
	for _, x in { -10, 10 } do
		G.deco("CabinCorner", V(0.5, 9, 8.5), cf * CFrame.new(x, 4.6, 0), "SteelDark")
	end
	for _, x in { -6, 1, 6.5 } do
		local w = G.deco("CabinWindow", V(3.2, 2.4, 0.2), cf * CFrame.new(x, 5.2, -4.05), { RGB(40, 52, 64), M.Glass })
		w.Transparency = 0.15
		G.deco("CabinFrame", V(3.5, 0.25, 0.3), cf * CFrame.new(x, 6.5, -4.05), "SteelDark")
	end
	G.deco("CabinDoor", V(2.6, 6.4, 0.2), cf * CFrame.new(-2.2, 3.8, -4.05), "SteelDark")
	if opts.Stripe then
		G.deco("CabinStripe", V(20.1, 0.6, 8.1), cf * CFrame.new(0, 7.6, 0), opts.Stripe)
	end
	if opts.Sign then
		local board = G.deco("CabinSign", V(7, 1.4, 0.2), cf * CFrame.new(5, 8, -4.12), { RGB(30, 40, 60), M.SmoothPlastic })
		Kit.sign(board, Enum.NormalId.Front, opts.Sign, RGB(250, 250, 250)).LightInfluence = 1
	end
	return body
end

-- Foco de obra en trípode (de noche, luz cálida hacia delante: -Z)
function P.workLight(cf, color)
	color = color or RGB(255, 222, 170)
	for i = 0, 2 do
		local a = rad(i * 120)
		local foot = cf * V(math.cos(a) * 1.2, 0, math.sin(a) * 1.2)
		G.beam(foot, cf * V(0, 5, 0), 0.15, 0.15, "SteelDark", true)
	end
	G.deco("WorkLightPole", V(0.2, 2, 0.2), cf * CFrame.new(0, 6, 0), "SteelDark")
	G.deco("WorkLightHead", V(2.4, 1.4, 0.7), cf * CFrame.new(0, 7.2, -0.2) * CFrame.Angles(rad(-20), 0, 0), "Yellow")
	local lens = G.deco("WorkLightLens", V(2.1, 1.1, 0.1), cf * CFrame.new(0, 7.15, -0.6) * CFrame.Angles(rad(-20), 0, 0), { color, M.Neon })
	local light = Kit.light(lens, "SpotLight", color, 30, 1.6, Enum.NormalId.Front)
	light.Angle = 70
end

-- Torre de focos (poste alto con 4 focos): ilumina un patio
function P.floodTower(cf, h, color)
	h = h or 18
	color = color or RGB(255, 236, 200)
	G.column(cf, h, 0.7, "SteelDark", "FloodPole")
	G.deco("FloodBar", V(5, 0.4, 0.4), cf * CFrame.new(0, h, 0), "SteelDark")
	for _, x in { -1.8, -0.6, 0.6, 1.8 } do
		local lamp = G.deco("FloodLamp", V(1, 1, 0.5), cf * CFrame.new(x, h + 0.7, -0.2) * CFrame.Angles(rad(-35), 0, 0), { color, M.Neon })
		if x == -0.6 then
			Kit.light(lamp, "SpotLight", color, 44, 1.8, Enum.NormalId.Front).Angle = 80
		end
	end
end

-- Hormigonera (cobertura baja-media)
function P.cementMixer(cf)
	local base = G.box("MixerFrame", V(3, 1.4, 4.4), cf * CFrame.new(0, 0.9, 0), "SteelDark")
	for _, x in { -1.6, 1.6 } do
		Kit.cylinder("MixerWheel", 0.5, 1.4, cf * CFrame.new(x, 0.7, 1.2) * CFrame.Angles(0, 0, rad(90)), RGB(30, 30, 32), M.SmoothPlastic, nil, true)
	end
	local drum = Kit.cylinder("MixerDrum", 3.4, 2.8, cf * CFrame.new(0, 3.1, -0.3) * CFrame.Angles(rad(-35), 0, 0), RGB(232, 120, 30), M.Metal)
	drum.CanCollide = true
	Kit.cylinder("MixerMouth", 0.6, 1.8, cf * CFrame.new(0, 4.5, -1.5) * CFrame.Angles(rad(-35), 0, 0), RGB(60, 60, 64), M.Metal, nil, true)
	Kit.contactShadow(cf, 3.4, 4.8)
	return base
end

-- Haz de ferralla (barras corrugadas) en el suelo: cobertura muy baja
function P.rebarBundle(cf, length)
	length = length or 10
	for i = 0, 5 do
		local x = (i % 3 - 1) * 0.35
		local y = 0.25 + math.floor(i / 3) * 0.32
		G.deco("Rebar", V(0.22, 0.22, length), cf * CFrame.new(x, y, (i % 2) * 0.3), { RGB(120, 66, 42), M.CorrodedMetal })
	end
	for _, z in { -length * 0.3, length * 0.3 } do
		G.deco("RebarTie", V(1.2, 0.8, 0.12), cf * CFrame.new(0, 0.4, z), "SteelDark")
	end
	local collider = G.box("RebarBlock", V(1.3, 0.8, length), cf * CFrame.new(0, 0.4, 0), "SteelDark")
	collider.Transparency = 1
end

-- Tubos de hormigón grandes apilados (cobertura media: 2 abajo + 1 arriba)
function P.pipeStack(cf, length)
	length = length or 8
	local look = get("ConcreteDark")
	for _, spec in { { -1.6, 1.5 }, { 1.6, 1.5 }, { 0, 4.1 } } do
		local pipe = Kit.pipe("ConcretePipe", length, 3, cf * CFrame.new(spec[1], spec[2], 0) * CFrame.Angles(0, rad(90), 0), look[1], look[2])
		pipe.CanCollide = true
	end
	Kit.contactShadow(cf, 6.4, length)
end

-- Vigas de acero apiladas sobre durmientes (cobertura baja)
function P.beamStack(cf, length, look)
	length = length or 14
	look = look or "RedSteel"
	for _, z in { -length * 0.35, length * 0.35 } do
		G.deco("Sleeper", V(4.6, 0.5, 0.8), cf * CFrame.new(0, 0.25, z), "WoodDark")
	end
	for row = 0, 1 do
		for i = 0, 2 - row do
			local x = (i - (2 - row) / 2) * 1.4
			local y = 0.5 + row * 1.2
			G.ibeam(cf * V(x, y + 0.6, -length / 2), cf * V(x, y + 0.6, length / 2), 1.2, look, true)
		end
	end
	G.box("BeamStackBlock", V(4.2, 2.9, length), cf * CFrame.new(0, 1.45, 0), look).Transparency = 1
end

-- Grúa torre (hito del mapa): mástil de celosía, cabina, pluma con carro y una carga colgando
-- (un palé de bloques), contrapluma con contrapesos y balizas. Todo decorado. cf = base del
-- mástil; la pluma apunta a -Z. opts: Jib (largo), Counter, Load (true), Look
function P.towerCrane(cf, height, opts)
	opts = opts or {}
	local look = get(opts.Look or "Yellow")
	local jib, counter = opts.Jib or 54, opts.Counter or 18
	local w = 3.2
	-- Mástil: 4 montantes y diagonales por tramo en las 4 caras
	for _, c in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		G.deco("CraneChord", V(0.45, height, 0.45), cf * CFrame.new(c[1] * w / 2, height / 2, c[2] * w / 2), look)
	end
	local segment = 6
	local faces = {
		{ V(-1, 0, -1), V(1, 0, -1) },
		{ V(1, 0, -1), V(1, 0, 1) },
		{ V(1, 0, 1), V(-1, 0, 1) },
		{ V(-1, 0, 1), V(-1, 0, -1) },
	}
	for s = 0, math.floor(height / segment) - 1 do
		local y0, y1 = s * segment, (s + 1) * segment
		for f, face in faces do
			local a, b = face[1] * w / 2, face[2] * w / 2
			local flip = (s + f) % 2 == 0
			G.beam(cf * (V(a.X, y0, a.Z)), cf * (flip and V(b.X, y1, b.Z) or V(b.X, y0, b.Z)), 0.22, 0.22, look, true)
			if not flip then
				G.beam(cf * V(a.X, y0, a.Z), cf * V(b.X, y1, b.Z), 0.22, 0.22, look, true)
			end
		end
	end
	-- Corona giratoria, cabina y cúspide
	local top = cf * CFrame.new(0, height, 0)
	G.deco("CraneSlew", V(w + 1, 1.4, w + 1), top * CFrame.new(0, 0.7, 0), "SteelDark")
	local cab = G.deco("CraneCab", V(2.8, 3, 3), top * CFrame.new(w / 2 + 1.2, 1.6, -1), { RGB(236, 236, 230), M.SmoothPlastic })
	cab.CastShadow = false
	local cabGlass = G.deco("CraneCabGlass", V(2.6, 1.6, 0.1), top * CFrame.new(w / 2 + 1.2, 2.1, -2.55), { RGB(60, 80, 96), M.Glass })
	cabGlass.Transparency = 0.2
	for _, c in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		G.beam(top * V(c[1] * w / 2, 1.4, c[2] * w / 2), top * V(0, 9, 0), 0.3, 0.3, look, true)
	end
	-- Pluma (celosía triangular: cordón arriba, dos abajo, diagonales) hacia -Z
	local y = 2.2
	for _, x in { -1.1, 1.1 } do
		G.deco("JibChord", V(0.35, 0.35, jib), top * CFrame.new(x, y, -jib / 2), look)
	end
	G.deco("JibTopChord", V(0.35, 0.35, jib), top * CFrame.new(0, y + 2.2, -jib / 2 + 1), look)
	for i = 0, math.floor(jib / 4) - 1 do
		local z0, z1 = -i * 4, -(i + 1) * 4
		for _, x in { -1.1, 1.1 } do
			G.beam(top * V(x, y, z0), top * V(0, y + 2.2, z1), 0.18, 0.18, look, true)
		end
	end
	-- Tirantes desde la cúspide a la pluma y a la contrapluma
	G.beam(top * V(0, 9, 0), top * V(0, y + 2.2, -jib * 0.55), 0.15, 0.15, "SteelDark", true)
	G.beam(top * V(0, 9, 0), top * V(0, y + 1, counter - 1), 0.15, 0.15, "SteelDark", true)
	-- Contrapluma y contrapesos
	G.deco("CounterJib", V(2.6, 0.6, counter), top * CFrame.new(0, y, counter / 2), look)
	for i = 0, 2 do
		G.deco("Counterweight", V(2.8, 3, 1.6), top * CFrame.new(0, y - 1.6, counter - 2 - i * 1.7), "ConcreteDark")
	end
	-- Carro, cable y carga (palé de bloques)
	local trolleyZ = -jib * 0.62
	G.deco("Trolley", V(2.6, 0.6, 1.6), top * CFrame.new(0, y - 0.5, trolleyZ), "SteelDark")
	local drop = opts.Drop or height * 0.55
	G.deco("CraneCable", V(0.12, drop, 0.12), top * CFrame.new(0, y - 0.8 - drop / 2, trolleyZ), "Black")
	G.deco("CraneHook", V(0.8, 1, 0.8), top * CFrame.new(0, y - 1.3 - drop, trolleyZ), "Yellow")
	if opts.Load ~= false then
		local load = top * CFrame.new(0, y - 1.8 - drop - 4, trolleyZ) * CFrame.Angles(0, rad(20), 0)
		G.deco("LoadBlocks", V(4.2, 3.4, 4.2), load * CFrame.new(0, 1.7, 0), "Block")
		G.deco("LoadPallet", V(4.4, 0.5, 4.4), load * CFrame.new(0, -0.25, 0), { RGB(170, 132, 86), M.WoodPlanks })
		for _, s in { -1, 1 } do
			G.beam(load * V(s * 2, 3.4, 0), top * V(0, y - 1.8 - drop, trolleyZ), 0.1, 0.1, "Black", true)
		end
	end
	-- Balizas rojas (parpadean en el cliente)
	for _, p in { V(0, 9.4, 0), V(0, y + 2.6, -jib + 1), V(0, y + 0.6, counter) } do
		local beacon = Kit.ball("CraneBeacon", 0.7, top * CFrame.new(p), RGB(255, 40, 30), M.Neon, true)
		beacon:SetAttribute("Blink", 1)
	end
	-- Cartel de la constructora en la pluma
	local board = G.deco("CraneBoard", V(0.3, 1.6, 9), top * CFrame.new(1.35, y + 1.2, -6), look)
	Kit.sign(board, Enum.NormalId.Right, opts.Brand or "ROBUILD", RGB(30, 30, 34), RGB(30, 30, 34)).LightInfluence = 1
end

---------------------------------------------------------------------------
-- Señalización
---------------------------------------------------------------------------

-- Lona con la letra del sitio (A roja, B azul) colgada de una fachada: la cara visible es -Z
function P.letterBanner(cf, letter, look, w, h)
	w, h = w or 10, h or 14
	look = get(look)
	local cloth = G.deco("SiteBanner", V(w, h, 0.25), cf, { look[1], M.Fabric })
	cloth.CastShadow = false
	G.deco("BannerBar", V(w + 0.6, 0.5, 0.5), cf * CFrame.new(0, h / 2 + 0.1, 0), "SteelDark")
	G.deco("BannerBar", V(w + 0.6, 0.4, 0.4), cf * CFrame.new(0, -h / 2 - 0.1, 0), "SteelDark")
	local gui = Kit.sign(cloth, Enum.NormalId.Front, letter, RGB(250, 248, 240), look[1]:Lerp(Color3.new(0, 0, 0), 0.4))
	gui.LightInfluence = 0.6
	gui.PixelsPerStud = 12
	local label = gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Size = UDim2.fromScale(0.8, 0.62)
		label.Position = UDim2.fromScale(0.1, 0.19)
	end
	-- (franja clara arriba, como las lonas de la referencia)
	G.deco("BannerTrim", V(w, 0.5, 0.3), cf * CFrame.new(0, h / 2 - 0.9, 0), { RGB(240, 236, 228), M.Fabric })
	return cloth
end

-- Cartel rectangular con texto (cara -Z). bg/fg = colores
function P.sign(cf, text, w, h, bg, fg, opts)
	opts = opts or {}
	local board = G.deco("SignBoard", V(w, h, 0.25), cf, { bg or RGB(30, 34, 40), M.SmoothPlastic })
	board.CastShadow = false
	local gui = Kit.sign(board, Enum.NormalId.Front, text, fg or RGB(250, 250, 250), opts.Stroke or (bg or RGB(30, 34, 40)))
	gui.LightInfluence = opts.Glow and 0 or 1
	gui.PixelsPerStud = opts.PPS or 20
	if opts.Back then
		local back = Kit.sign(board, Enum.NormalId.Back, text, fg or RGB(250, 250, 250), opts.Stroke or (bg or RGB(30, 34, 40)))
		back.LightInfluence = gui.LightInfluence
		back.PixelsPerStud = gui.PixelsPerStud
	end
	return board
end

-- Flecha de ruta pintada en pared ("A →"): ayuda a orientarse sin flechas gigantes
function P.routeSign(cf, text, look)
	return P.sign(cf, text, 5, 1.6, get(look or "Red")[1], RGB(255, 255, 255), { PPS = 30 })
end

---------------------------------------------------------------------------
-- Ciudad y fondo
---------------------------------------------------------------------------

-- Edificio de fondo (sin interior, sin colisión): bloque con bandas de ventanas. opts.Lit = las
-- ventanas brillan (de noche), opts.Roof = trastos en la azotea, opts.Material
function P.cityBlock(cf, w, d, h, color, opts)
	opts = opts or {}
	local body = G.deco("CityBlock", V(w, h, d), cf * CFrame.new(0, h / 2, 0), { color, opts.Material or M.Concrete })
	body.CastShadow = false -- (lejos: su sombra solo oscurecería el mapa al atardecer)
	local floorH = opts.FloorH or 6
	local windowColor = opts.Lit and RGB(150, 112, 72) or (opts.WindowColor or color:Lerp(RGB(40, 50, 62), 0.7))
	local material = opts.Lit and M.Neon or M.SmoothPlastic
	local floors = math.floor((h - 3) / floorH)
	for f = 1, floors do
		local y = f * floorH
		-- (de noche no todas las plantas están encendidas)
		local lit = opts.Lit and ((f * 7 + math.floor(w)) % 3 ~= 0)
		local band = G.deco("CityWindows", V(w + 0.15, floorH * 0.32, d + 0.15), cf * CFrame.new(0, y - floorH * 0.4, 0), {
			lit and windowColor or (opts.WindowColor or color:Lerp(RGB(40, 50, 62), 0.7)),
			lit and material or M.SmoothPlastic,
		})
		band.CastShadow = false
	end
	G.deco("CityCornice", V(w + 0.6, 0.8, d + 0.6), cf * CFrame.new(0, h + 0.2, 0), { color:Lerp(Color3.new(0, 0, 0), 0.25), M.Concrete }).CastShadow = false
	if opts.Roof then
		G.deco("CityRoofBox", V(w * 0.3, 2.5, d * 0.3), cf * CFrame.new(w * 0.18, h + 1.25, -d * 0.12), "SteelDark").CastShadow = false
	end
end

-- Hilera de edificios de fondo en arco alrededor del mapa (horizonte). center, radius, from/to en
-- grados, step = separación angular. palette = lista de colores
function P.skylineRing(center, radius, fromDeg, toDeg, step, palette, opts)
	opts = opts or {}
	local i = 0
	for a = fromDeg, toDeg, step do
		i += 1
		local r = radius + ((i * 37) % 5) * 9
		local p = center + V(math.cos(rad(a)) * r, 0, math.sin(rad(a)) * r)
		local w = 16 + (i * 13) % 14
		local d = 14 + (i * 7) % 12
		local h = (opts.MinH or 30) + (i * 23) % (opts.VarH or 60)
		if i % (opts.TowerEvery or 6) == 0 then
			h = h + (opts.TowerExtra or 60)
		end
		local cf = CFrame.lookAt(p, V(center.X, 0, center.Z))
		P.cityBlock(cf, w, d, h, palette[(i % #palette) + 1], { Lit = opts.Lit, Roof = i % 2 == 0, FloorH = opts.FloorH })
	end
end


---------------------------------------------------------------------------
-- Más obra y edificios de borde
---------------------------------------------------------------------------

-- Contenedor de escombros (rojo, abierto por arriba con escombro dentro): cobertura baja-media
function P.skip(cf, look)
	look = get(look or "ContainerRed")
	local body = G.box("Skip", V(5.6, 3.4, 10), cf * CFrame.new(0, 1.9, 0), look)
	G.deco("SkipRim", V(6, 0.4, 10.4), cf * CFrame.new(0, 3.65, 0), { look[1]:Lerp(Color3.new(0, 0, 0), 0.3), M.Metal })
	for _, s in { -1, 1 } do
		G.deco("SkipSlope", V(5.6, 0.3, 2.4), cf * CFrame.new(0, 1.2, s * 5.6) * CFrame.Angles(s * rad(40), 0, 0), look)
	end
	for i, p in { V(-1.2, 3.8, -2), V(1, 3.9, 1.5), V(0, 3.7, 3.2) } do
		G.deco("Rubble", V(1.6 + i * 0.3, 0.8, 1.4), cf * CFrame.new(p) * CFrame.Angles(i * 0.4, i, 0.2), i % 2 == 0 and "ConcreteDark" or "Plywood")
	end
	Kit.contactShadow(cf, 6, 11)
	return body
end

-- Palé de sacos de cemento (cobertura baja)
function P.sackPallet(cf)
	P.pallet(cf)
	local body = G.box("Sacks", V(4, 1.8, 4), cf * CFrame.new(0, 1.4, 0), { RGB(214, 204, 186), M.Fabric })
	for l = 0, 2 do
		G.deco("SackRow", V(4.1, 0.08, 4.1), cf * CFrame.new(0, 0.55 + l * 0.6, 0), { RGB(176, 166, 150), M.Fabric })
	end
	G.deco("SackLabel", V(1.6, 0.6, 0.05), cf * CFrame.new(0, 1.4, -2.03), { RGB(200, 60, 40), M.SmoothPlastic })
	return body
end

-- Bobina de cable (cobertura baja, redonda)
function P.cableSpool(cf, d)
	d = d or 3.6
	for _, x in { -0.9, 0.9 } do
		Kit.pipe("SpoolSide", 0.3, d, cf * CFrame.new(x, d / 2, 0), RGB(150, 110, 70), M.WoodPlanks, false)
	end
	local core = Kit.pipe("SpoolCable", 1.6, d * 0.7, cf * CFrame.new(0, d / 2, 0), RGB(40, 40, 44), M.SmoothPlastic, false)
	return core
end

-- Depósito de agua de azotea sobre patas (decorado)
function P.waterTank(cf)
	for _, x in { -1.4, 1.4 } do
		for _, z in { -1.4, 1.4 } do
			G.deco("TankLeg", V(0.3, 3, 0.3), cf * CFrame.new(x, 1.5, z), "SteelDark")
		end
	end
	Kit.cylinder("WaterTank", 4, 4.2, cf * CFrame.new(0, 5, 0), RGB(150, 140, 128), M.Metal, nil, true)
	Kit.cylinder("TankLid", 0.4, 4.6, cf * CFrame.new(0, 7.2, 0), RGB(90, 86, 82), M.Metal, nil, true)
end

-- Aplique de pared con luz cálida (cara -Z)
function P.wallLamp(cf, color)
	color = color or RGB(255, 210, 150)
	G.deco("LampArm", V(0.3, 0.3, 0.8), cf * CFrame.new(0, 0, -0.4), "SteelDark")
	local bulb = G.deco("LampBulb", V(0.8, 0.5, 0.6), cf * CFrame.new(0, -0.2, -0.9), { color, M.Neon })
	Kit.light(bulb, "PointLight", color, 12, 0.8)
end

-- Chapa ondulada: nervios verticales sobre una cara de muro (decorado). a, b = extremos al pie
function P.ribs(a, b, h, look, spacing)
	spacing = spacing or 2.4
	local length = (b - a).Magnitude
	local count = math.floor(length / spacing)
	for i = 1, count - 1 do
		local p = a:Lerp(b, i / count)
		G.deco("Rib", V(0.35, h, 0.35), CFrame.lookAt(p, p + (b - a)) * CFrame.new(0, h / 2, 0), look).CastShadow = false
	end
end

-- Montacargas de obra (jaula amarilla adosada a una fachada, decorado). cf = centro de la base
function P.hoist(cf, h)
	local look = get("Yellow")
	for _, x in { -2, 2 } do
		for _, z in { -2, 2 } do
			G.box("HoistPost", V(0.5, h, 0.5), cf * CFrame.new(x, h / 2, z), look)
		end
	end
	for y = 4, h, 4 do
		G.deco("HoistRing", V(4.4, 0.3, 0.3), cf * CFrame.new(0, y, -2), look)
		G.deco("HoistRing", V(4.4, 0.3, 0.3), cf * CFrame.new(0, y, 2), look)
		G.deco("HoistRing", V(0.3, 0.3, 4.4), cf * CFrame.new(-2, y, 0), look)
		G.deco("HoistRing", V(0.3, 0.3, 4.4), cf * CFrame.new(2, y, 0), look)
	end
	local car = G.deco("HoistCar", V(3.6, 3.4, 3.6), cf * CFrame.new(0, h * 0.55, 0), { RGB(230, 226, 214), M.Metal })
	car.CastShadow = false
	G.deco("HoistMesh", V(3.7, 2.6, 3.7), cf * CFrame.new(0, h * 0.55 + 0.2, 0), { RGB(60, 60, 64), M.DiamondPlate }).Transparency = 0.5
end

-- Edificio de borde (macizo, se ve pero no se entra): plantas con ventanas en bandas, cornisa,
-- azotea con pretil y trastos. Cierra el mapa con la escala de una ciudad. Devuelve el cuerpo
-- (para taparlo con T.cap). opts: FloorH, Windows (color), Lit, Roof = false
function P.facadeBlock(cf, w, d, h, look, opts)
	opts = opts or {}
	look = get(look)
	local body = G.box("EdgeBuilding", V(w, h, d), cf * CFrame.new(0, h / 2, 0), look)
	local floorH = opts.FloorH or 5
	local windowLook = { opts.Windows or RGB(58, 70, 84), M.Glass }
	for f = 1, math.floor((h - 2) / floorH) do
		local y = (f - 1) * floorH + floorH * 0.55
		local band = G.deco("EdgeWindows", V(w + 0.2, floorH * 0.38, d + 0.2), cf * CFrame.new(0, y, 0), windowLook)
		band.CastShadow = false
		band.Reflectance = 0.12
		if opts.Lit then
			-- De noche, algunas ventanas encendidas (sueltas, no la banda entera)
			local seed = f * 7 + math.floor(w * 3 + d)
			for k, spec in { { -0.3, -1 }, { 0.15, -1 }, { 0.32, 1 }, { -0.1, 1 } } do
				if (seed + k) % 3 ~= 0 then
					local alongX = k <= 2
					local offset = alongX and V(spec[1] * w, y, spec[2] * (d / 2 + 0.15)) or V(spec[2] * (w / 2 + 0.15), y, spec[1] * d)
					local size = alongX and V(math.min(5, w * 0.16), floorH * 0.34, 0.12) or V(0.12, floorH * 0.34, math.min(5, d * 0.16))
					G.deco("LitWindow", size, cf * CFrame.new(offset), { RGB(226, 176, 112), M.Neon }).CastShadow = false
				end
			end
		end
		-- Losa entre plantas (línea más clara)
		G.deco("EdgeSlab", V(w + 0.3, 0.35, d + 0.3), cf * CFrame.new(0, f * floorH, 0), { look[1]:Lerp(Color3.new(1, 1, 1), 0.12), look[2] }).CastShadow = false
	end
	G.deco("EdgeCornice", V(w + 0.8, 0.7, d + 0.8), cf * CFrame.new(0, h + 0.35, 0), { look[1]:Lerp(Color3.new(0, 0, 0), 0.2), look[2] }).CastShadow = false
	if opts.Roof ~= false then
		local roofCf = cf * CFrame.new(0, h, 0)
		P.waterTank(roofCf * CFrame.new(w * 0.25, 0, d * 0.2))
		G.deco("RoofBox", V(4, 2.4, 3), roofCf * CFrame.new(-w * 0.22, 1.2, -d * 0.18), "SteelDark")
	end
	return body
end

---------------------------------------------------------------------------
-- Azoteas
---------------------------------------------------------------------------

-- Antena de celosía (decorado alto con base que choca) y balizas
function P.antennaTower(cf, h)
	h = h or 24
	local base = G.box("AntennaBase", V(4, 1.6, 4), cf * CFrame.new(0, 0.8, 0), "SteelDark")
	local w = 2.4
	for _, c in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		G.beam(cf * V(c[1] * w / 2, 1.6, c[2] * w / 2), cf * V(c[1] * 0.4, h, c[2] * 0.4), 0.25, 0.25, "SteelDark", true)
	end
	for y = 4, h - 2, 4 do
		local k = 1 - (y / h) * 0.7
		G.deco("AntennaRing", V(w * k, 0.2, w * k), cf * CFrame.new(0, y, 0), "SteelDark")
	end
	for _, y in { h * 0.55, h * 0.8 } do
		G.deco("AntennaPanel", V(0.4, 2.4, 1.2), cf * CFrame.new(0.9, y, 0), { RGB(220, 222, 226), M.SmoothPlastic })
	end
	local beacon = Kit.ball("AntennaBeacon", 0.7, cf * CFrame.new(0, h + 0.5, 0), RGB(255, 40, 30), M.Neon, true)
	beacon:SetAttribute("Blink", 1)
	return base
end

-- Lucernario piramidal de cristal sobre un zócalo (cobertura baja)
function P.skylight(cf, w)
	w = w or 8
	local curb = G.box("SkylightCurb", V(w, 1.4, w), cf * CFrame.new(0, 0.7, 0), "SteelDark")
	local h = w * 0.35
	local slope = math.sqrt((w / 2) ^ 2 + h * h)
	for i = 0, 3 do
		local face = cf * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, rad(i * 90), 0)
		local pane = G.deco("SkylightGlass", V(w * 0.7, 0.2, slope), face * CFrame.new(0, h / 2, -w / 4) * CFrame.Angles(math.atan2(h, w / 2), 0, 0), "Glass")
		pane.Transparency = 0.35
	end
	return curb
end

-- Placas solares en fila (cobertura muy baja)
function P.solarRow(cf, count)
	for i = 0, (count or 3) - 1 do
		local panel = cf * CFrame.new(i * 4.4, 0, 0)
		G.deco("SolarLeg", V(0.3, 1.6, 0.3), panel * CFrame.new(0, 0.8, 1), "SteelDark")
		G.box("SolarPanel", V(4, 0.25, 3), panel * CFrame.new(0, 1.4, 0) * CFrame.Angles(rad(25), 0, 0), { RGB(30, 50, 90), M.Glass })
	end
end

-- Antena parabólica
function P.dish(cf)
	G.deco("DishPost", V(0.4, 2.4, 0.4), cf * CFrame.new(0, 1.2, 0), "SteelDark")
	local d = Kit.cylinder("Dish", 0.4, 3, cf * CFrame.new(0, 2.8, -0.3) * CFrame.Angles(rad(-55), 0, 0), RGB(230, 232, 236), M.SmoothPlastic, nil, true)
	d.CastShadow = true
end

-- Valla publicitaria con pantalla (cara -Z) sobre patas: el cuerpo choca
function P.billboardScreen(cf, w, h, text, color)
	for _, x in { -w * 0.35, w * 0.35 } do
		G.box("BillboardLeg", V(0.6, 4, 0.6), cf * CFrame.new(x, 2, 0.4), "SteelDark")
	end
	local frame = G.box("BillboardFrame", V(w, h, 1), cf * CFrame.new(0, 4 + h / 2, 0.4), "SteelDark")
	local screen = G.deco("BillboardScreen", V(w - 0.8, h - 0.8, 0.2), cf * CFrame.new(0, 4 + h / 2, -0.15), { color or RGB(30, 80, 170), M.SmoothPlastic })
	screen.CastShadow = false
	local gui = Kit.sign(screen, Enum.NormalId.Front, text or "", RGB(230, 244, 255), color or RGB(30, 80, 170))
	gui.LightInfluence = 0.15
	return frame
end

---------------------------------------------------------------------------
-- Vegetación y mobiliario
---------------------------------------------------------------------------

function P.tree(cf)
	Kit.tree(cf)
end

function P.palm(cf, h)
	Kit.palm(cf, h)
end

-- Jardinera de hormigón con arbusto (cobertura baja)
function P.planter(cf, sx, sz)
	sx, sz = sx or 6, sz or 3
	local box = G.box("Planter", V(sx, 2, sz), cf * CFrame.new(0, 1, 0), "ConcreteDark")
	G.deco("PlanterSoil", V(sx - 0.6, 0.2, sz - 0.6), cf * CFrame.new(0, 2.02, 0), { RGB(80, 58, 40), M.Ground })
	for i = 0, math.floor(sx / 2.5) - 1 do
		Kit.ball("Shrub", 2.2, cf * CFrame.new(-sx / 2 + 1.4 + i * 2.5, 2.6, 0), RGB(70, 128, 60), M.Grass, true)
	end
	return box
end

-- Máquina de aire acondicionado de azotea (cobertura baja)
function P.hvac(cf, look)
	local box = G.box("HVAC", V(5, 3, 4), cf * CFrame.new(0, 1.5, 0), look or { RGB(196, 198, 200), M.Metal })
	Kit.cylinder("HVACFan", 0.3, 2.8, cf * CFrame.new(-0.9, 3.1, 0), RGB(60, 62, 66), M.Metal, nil, true)
	G.deco("HVACGrille", V(0.1, 2, 3), cf * CFrame.new(2.55, 1.5, 0), "SteelDark")
	return box
end

-- Farola (luz cálida hacia -Z)
function P.lampPost(cf, color)
	Kit.streetLamp(cf, color)
end

return P
