-- Piezas de centro comercial (Mall Rush): escalera mecánica, barandilla de cristal, escaparate con
-- rótulo, quiosco, puesto de comida, mesas, palmera en jardinera, banderola colgante y cúpula de
-- cristal. Colores fuertes pero con materiales de verdad (nada de neón por todas partes).
local Kit = require(script.Parent.Parent.MapKit)
local G = require(script.Parent.Geometry)

local Mall = {}
Mall.capHook = function(_part) end -- (lo sustituye TacKit por T.cap: tapar por arriba)

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad
local M = Enum.Material

-- Barandilla de cristal entre dos puntos del suelo: vidrio (decorado), pasamanos de acero y un panel
-- invisible que choca pero deja pasar balas y vista
function Mall.glassRail(a, b, h)
	h = h or 3.4
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	if length < 0.5 then
		return
	end
	local cf = CFrame.lookAt(mid, b)
	local glass = G.deco("RailGlass", V(0.15, h - 0.3, length), cf * CFrame.new(0, (h - 0.3) / 2, 0), { RGB(170, 220, 236), M.Glass })
	glass.Transparency = 0.6
	glass.CastShadow = false
	G.deco("RailTop", V(0.35, 0.25, length), cf * CFrame.new(0, h, 0), { RGB(210, 214, 220), M.Metal })
	G.deco("RailShoe", V(0.4, 0.3, length), cf * CFrame.new(0, 0.15, 0), { RGB(150, 154, 160), M.Metal })
	local stop = Kit.block("RailCollider", V(0.5, h + 0.4, length), cf * CFrame.new(0, (h + 0.4) / 2, 0), Color3.new(1, 1, 1), nil, Kit.shootThroughFolder())
	stop.Transparency = 1
	stop.CastShadow = false
end

-- Escalera mecánica de bottom a top (puntos del centro): peldaños metálicos, laterales de cristal
-- y pasamanos negros
function Mall.escalator(bottom, top, width)
	width = width or 4.4
	local body = G.stairs(bottom, top, width, { RGB(120, 124, 132), M.DiamondPlate }, { StepLook = { RGB(150, 154, 162), M.DiamondPlate }, NosingLook = { RGB(240, 200, 40), M.SmoothPlastic } })
	local flat = V(top.X - bottom.X, 0, top.Z - bottom.Z)
	local face = CFrame.lookAt(bottom, bottom + flat)
	local right = face.RightVector * (width / 2 + 0.3)
	for _, s in { -1, 1 } do
		local a, b = bottom + right * s, top + right * s
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, b)
		local side = G.deco("EscalatorSide", V(0.25, 3, (b - a).Magnitude), cf * CFrame.new(0, 1.2, 0), { RGB(170, 220, 236), M.Glass })
		side.Transparency = 0.55
		G.deco("EscalatorRail", V(0.4, 0.4, (b - a).Magnitude + 1), cf * CFrame.new(0, 3, 0), { RGB(24, 24, 28), M.Rubber })
		G.deco("EscalatorSkirt", V(0.35, 1.2, (b - a).Magnitude), cf * CFrame.new(0, -0.3, 0), { RGB(200, 204, 210), M.Metal })
		local stop = Kit.block("RailCollider", V(0.5, 3.6, (b - a).Magnitude), cf * CFrame.new(0, 1.8, 0), Color3.new(1, 1, 1), nil, Kit.shootThroughFolder())
		stop.Transparency = 1
	end
	-- Cuerpo inferior (la "caja" de la escalera)
	local run = flat.Magnitude
	local rise = top.Y - bottom.Y
	-- (macizo: tapa la vista por debajo y no se pasa por debajo de la escalera)
	for i = 2, 4 do
		local h = rise * (i - 1) / 4 - 0.6 -- (por debajo de la rampa en todo el tramo)
		G.box("EscalatorTruss", V(width + 0.6, h, run / 4), face * CFrame.new(0, h / 2, -(run * (i - 0.5) / 4)), { RGB(200, 204, 210), M.Metal })
	end
	return body
end

-- Escaparate: cristal en el hueco de una fachada de tienda (cara -Z), rótulo encima y un fondo de
-- color dentro (la tienda no se entra). cf = centro de la base del hueco; w = ancho
function Mall.storefront(cf, w, h, name, color, opts)
	opts = opts or {}
	h = h or 8
	local glass = G.deco("ShopGlass", V(w, h - 1, 0.2), cf * CFrame.new(0, (h - 1) / 2 + 0.2, 0), { RGB(180, 220, 236), M.Glass })
	glass.Transparency = 0.5
	glass.CastShadow = false
	local stop = Kit.block("GlassCollider", V(w, h, 0.4), cf * CFrame.new(0, h / 2, 0), Color3.new(1, 1, 1), nil, Kit.shootThroughFolder())
	stop.Transparency = 1
	stop.CastShadow = false
	-- Interior (fondo de color y estantes) para que el cristal tenga algo detrás
	G.deco("ShopBack", V(w, h, 0.4), cf * CFrame.new(0, h / 2, (opts.Depth or 6)), { color:Lerp(Color3.new(1, 1, 1), 0.35), M.SmoothPlastic })
	if not opts.Shallow then
		for i = -1, 1 do
			G.deco("ShopShelf", V(w * 0.22, 4, 1.4), cf * CFrame.new(i * w * 0.3, 2, (opts.Depth or 6) - 1.2), { color, M.SmoothPlastic })
		end
	else
		-- (escaparate sobre un bloque macizo: maniquíes y género pegados al fondo)
		for i = -1, 1, 2 do
			G.deco("Mannequin", V(1.2, 5, 0.4), cf * CFrame.new(i * w * 0.25, 2.7, 0.35), { RGB(236, 236, 240), M.SmoothPlastic })
		end
	end
	-- Rótulo de la tienda (franja de color con letras blancas)
	local board = G.deco("ShopSign", V(w, 1.8, 0.4), cf * CFrame.new(0, h + 1.1, -0.2), { color, M.SmoothPlastic })
	local gui = Kit.sign(board, Enum.NormalId.Front, name, RGB(255, 255, 255), color:Lerp(Color3.new(0, 0, 0), 0.3))
	gui.LightInfluence = 0.3
	gui.PixelsPerStud = 16
	local strip = G.deco("ShopLight", V(w, 0.2, 0.3), cf * CFrame.new(0, h + 2.1, -0.4), { RGB(255, 246, 230), M.Neon })
	strip.CastShadow = false
	return board
end

-- Quiosco (isla en medio del pasillo): mostrador redondo de color con techo (cobertura media)
function Mall.kiosk(cf, color, name)
	local body = Kit.cylinder("Kiosk", 3.6, 6, cf * CFrame.new(0, 1.8, 0), color, M.SmoothPlastic)
	Kit.cylinder("KioskTop", 0.4, 6.4, cf * CFrame.new(0, 3.8, 0), RGB(240, 240, 244), M.SmoothPlastic, nil, true)
	G.deco("KioskPole", V(0.4, 4, 0.4), cf * CFrame.new(0, 6, 0), { RGB(200, 204, 210), M.Metal })
	local roof = Kit.cylinder("KioskRoof", 0.5, 7, cf * CFrame.new(0, 8.2, 0), color, M.SmoothPlastic, nil, true)
	roof.CastShadow = true
	if name then
		local board = G.deco("KioskSign", V(5, 1.2, 0.2), cf * CFrame.new(0, 9.2, 0), { color, M.SmoothPlastic })
		Kit.sign(board, Enum.NormalId.Front, name, RGB(255, 255, 255)).LightInfluence = 0.3
		Kit.sign(board, Enum.NormalId.Back, name, RGB(255, 255, 255)).LightInfluence = 0.3
	end
	return body
end

-- Puesto de la zona de comida: mostrador, trasera alta con el nombre y menú (cobertura alta)
function Mall.foodStall(cf, name, color, w)
	w = w or 12
	local counter = G.box("FoodCounter", V(w, 3.4, 2.6), cf * CFrame.new(0, 1.7, 0), { RGB(240, 240, 244), M.SmoothPlastic })
	G.deco("CounterFront", V(w + 0.1, 1, 2.7), cf * CFrame.new(0, 2.2, 0), { color, M.SmoothPlastic })
	local back = G.box("FoodBack", V(w, 9, 1), cf * CFrame.new(0, 4.5, 5), { color:Lerp(Color3.new(1, 1, 1), 0.15), M.SmoothPlastic })
	Mall.capHook(back)
	local board = G.deco("FoodSign", V(w * 0.7, 2.4, 0.4), cf * CFrame.new(0, 10.4, 4.6), { color, M.SmoothPlastic })
	Kit.sign(board, Enum.NormalId.Front, name, RGB(255, 255, 255), color:Lerp(Color3.new(0, 0, 0), 0.35)).LightInfluence = 0.2
	for i = -1, 1 do
		G.deco("Menu", V(w * 0.22, 1.6, 0.1), cf * CFrame.new(i * w * 0.28, 7.2, 4.45), { RGB(30, 30, 36), M.SmoothPlastic })
	end
	G.deco("FoodCanopy", V(w + 1, 0.4, 3), cf * CFrame.new(0, 8.6, 3.2) * CFrame.Angles(rad(-15), 0, 0), { color, M.Fabric })
	return counter
end

-- Mesa con cuatro sillas (cobertura muy baja)
function Mall.tableSet(cf, color)
	G.box("Table", V(3.4, 2.6, 3.4), cf * CFrame.new(0, 1.3, 0), { RGB(236, 236, 240), M.SmoothPlastic })
	for i = 0, 3 do
		local seat = cf * CFrame.Angles(0, rad(i * 90), 0) * CFrame.new(0, 0, -2.8)
		G.deco("Chair", V(1.4, 1.6, 1.4), seat * CFrame.new(0, 0.8, 0), { color or RGB(240, 120, 40), M.SmoothPlastic })
		G.deco("ChairBack", V(1.4, 1.6, 0.25), seat * CFrame.new(0, 2.4, -0.6), { color or RGB(240, 120, 40), M.SmoothPlastic })
	end
end

-- Palmera en jardinera cuadrada (cobertura baja)
function Mall.palmPlanter(cf, h)
	local box = G.box("PalmPlanter", V(5, 2.4, 5), cf * CFrame.new(0, 1.2, 0), { RGB(70, 74, 82), M.Concrete })
	G.deco("PlanterSoil", V(4.4, 0.2, 4.4), cf * CFrame.new(0, 2.42, 0), { RGB(70, 52, 38), M.Ground })
	Kit.palm(cf * CFrame.new(0, 2.4, 0), h or 12)
	for _, p in { V(-1.4, 2.8, -1.4), V(1.4, 2.8, 1.2) } do
		Kit.ball("PlanterShrub", 1.6, cf * CFrame.new(p), RGB(60, 140, 70), M.Grass, true)
	end
	return box
end

-- Banderola colgante (cara -Z; la cuelga de cf, que es el centro de arriba)
function Mall.hangingBanner(cf, w, h, color, text)
	G.deco("BannerRod", V(w + 0.6, 0.3, 0.3), cf, { RGB(200, 204, 210), M.Metal })
	local cloth = G.deco("HangBanner", V(w, h, 0.15), cf * CFrame.new(0, -h / 2 - 0.2, 0), { color, M.Fabric })
	cloth.CastShadow = false
	if text then
		local gui = Kit.sign(cloth, Enum.NormalId.Front, text, RGB(255, 255, 255), color:Lerp(Color3.new(0, 0, 0), 0.3))
		gui.LightInfluence = 0.5
		local back = Kit.sign(cloth, Enum.NormalId.Back, text, RGB(255, 255, 255), color:Lerp(Color3.new(0, 0, 0), 0.3))
		back.LightInfluence = 0.5
	end
	G.deco("BannerCable", V(0.08, 8, 0.08), cf * CFrame.new(0, 4, 0), { RGB(40, 40, 44), M.Metal })
end

-- Cúpula de cristal (pirámide de paneles con nervios) sobre un hueco cuadrado de lado w
function Mall.glassDome(cf, w, h)
	h = h or w * 0.35
	local slope = math.sqrt((w / 2) ^ 2 + h * h)
	local angle = math.atan2(h, w / 2)
	for i = 0, 3 do
		local face = cf * CFrame.Angles(0, rad(i * 90), 0)
		local pane = G.deco("DomeGlass", V(w * 0.72, 0.3, slope), face * CFrame.new(0, h / 2, -w / 4) * CFrame.Angles(angle, 0, 0), { RGB(170, 220, 240), M.Glass })
		pane.Transparency = 0.45
		pane.CastShadow = false
		G.deco("DomeRib", V(0.4, 0.4, slope * 1.42), face * CFrame.Angles(0, rad(45), 0) * CFrame.new(0, h / 2, -w * 0.35) * CFrame.Angles(math.atan2(h, w * 0.707), 0, 0), { RGB(230, 234, 240), M.Metal })
	end
	G.deco("DomeFrame", V(w + 1, 0.8, w + 1), cf * CFrame.new(0, -0.2, 0), { RGB(230, 234, 240), M.Metal })
end

return Mall
