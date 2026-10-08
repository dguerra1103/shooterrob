-- Acabados de los mapas (Fase 14, pulido visual): piezas grandes y baratas que hacen que un mapa
-- parezca diseñado y no un bloque gris: zonas de suelo con material propio, remates y pilastras de
-- fachada (ritmo y profundidad en muros largos), encofrados de obra, lonas con texto, toldos,
-- macetas y siluetas de fondo (gasómetros, esqueletos de edificio). Todo es DECORADO: no choca ni
-- para balas (G.deco), así que no cambia rutas, coberturas ni líneas de tiro.
--
-- Nombres de pieza: los detalles finos usan nombres de Settings.HIDE_BELOW (se ocultan en calidad
-- Baja); lo que da forma al mapa (zonas de suelo, remates, fondo) se ve siempre.
local Kit = require(script.Parent.Parent.MapKit)
local Materials = require(script.Parent.Materials)
local G = require(script.Parent.Geometry)

local F = {}

local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material
local get = Materials.get

---------------------------------------------------------------------------
-- Suelo
---------------------------------------------------------------------------

-- Zona de suelo (pavimento, grava, asfalto...) sobre el suelo del mapa: lámina de 0,02 que queda por
-- DEBAJO de juntas (0,03), líneas pintadas (0,04) y marcas de los sitios (0,05+), así todo eso se
-- sigue viendo encima. cf = centro a ras de suelo; gira con cf.
function F.groundZone(cf, sx, sz, look, name)
	local part = G.deco(name or "GroundZone", V(sx, 0.02, sz), cf * CF(0, 0.01, 0), look)
	part.CastShadow = false
	return part
end

-- Bordillo pintado de una zona (cuatro tiras finas en el perímetro): marca el cambio de suelo
function F.zoneEdge(cf, sx, sz, look, width)
	width = width or 0.35
	for _, spec in { { V(sx, 0.035, width), V(0, 0, -sz / 2) }, { V(sx, 0.035, width), V(0, 0, sz / 2) }, { V(width, 0.035, sz), V(-sx / 2, 0, 0) }, { V(width, 0.035, sz), V(sx / 2, 0, 0) } } do
		G.deco("ZoneEdge", spec[1], cf * CF(spec[2] + V(0, 0.0175, 0)), look).CastShadow = false
	end
end

---------------------------------------------------------------------------
-- Fachadas
---------------------------------------------------------------------------

-- Remate horizontal a lo largo de una fachada (cornisa, zócalo, franja de color): de a a b (puntos a
-- ras de la cara del muro, a la altura de su base), sobresale `depth` hacia `outward`.
function F.band(a, b, y, h, depth, look, outward, name)
	local length = (b - a).Magnitude
	local mid = (a + b) / 2 + outward * (depth / 2) + V(0, y + h / 2, 0)
	local part = G.deco(name or "FacadeBand", V(depth, h, length), CFrame.lookAt(mid, mid + (b - a)) , look)
	part.CastShadow = false
	return part
end

-- Pilastras (franjas verticales) cada `spacing` a lo largo de una fachada, sin tapar los huecos.
-- skip = { { d0, d1 } } tramos (distancia desde a) donde no se ponen (puertas, ventanas)
function F.pilasters(a, b, spacing, y0, h, width, depth, look, outward, skip, name)
	local length = (b - a).Magnitude
	local dir = (b - a).Unit
	local count = 0
	for d = 0, length + 0.01, spacing do
		local blocked = false
		for _, s in skip or {} do
			if d > s[1] - width and d < s[2] + width then
				blocked = true
			end
		end
		if not blocked then
			local p = a + dir * d + outward * (depth / 2) + V(0, y0 + h / 2, 0)
			local part = G.deco(name or "Pilaster", V(width, h, depth), CFrame.lookAt(p, p + outward), look)
			part.CastShadow = false
			count += 1
		end
	end
	return count
end

-- Toldo inclinado sobre una puerta o ventana (cara visible hacia `outward`)
function F.awning(cf, w, depth, look, stripe)
	local cloth = G.deco("Awning", V(w, 0.25, depth), cf * CF(0, 0, -depth / 2) * CFrame.Angles(math.rad(-16), 0, 0), { get(look)[1], M.Fabric })
	cloth.CastShadow = false
	if stripe then
		G.deco("AwningStripe", V(w, 0.6, 0.28), cf * CF(0, -depth * 0.28 - 0.3, -depth + 0.05), { get(stripe)[1], M.Fabric }).CastShadow = false
	end
	return cloth
end

---------------------------------------------------------------------------
-- Obra
---------------------------------------------------------------------------

-- Encofrado de madera alrededor de un pilar sin terminar (cf = centro de la base del encofrado)
function F.formwork(cf, w, h)
	local box = G.deco("Formwork", V(w, h, w), cf * CF(0, h / 2, 0), "Plywood")
	for _, y in { 0.2, h - 0.4 } do
		G.deco("FormworkClamp", V(w + 0.3, 0.25, w + 0.3), cf * CF(0, y + 0.12, 0), "SteelDark").CastShadow = false
	end
	return box
end

-- Lona grande con texto (malla de obra, publicidad de la promotora). La cara visible es -Z de cf.
function F.banner(cf, w, h, text, bg, fg, opts)
	opts = opts or {}
	local cloth = G.deco("MeshBanner", V(w, h, 0.2), cf, { bg, M.Fabric })
	cloth.CastShadow = false
	if text and text ~= "" then
		local gui = Kit.sign(cloth, Enum.NormalId.Front, text, fg, bg:Lerp(Color3.new(0, 0, 0), 0.5))
		gui.LightInfluence = 0.8
		gui.PixelsPerStud = opts.PPS or 10
		local label = gui:FindFirstChildOfClass("TextLabel")
		if label then
			label.Size = UDim2.fromScale(0.9, opts.TextScale or 0.6)
			label.Position = UDim2.fromScale(0.05, (1 - (opts.TextScale or 0.6)) / 2)
		end
	end
	if opts.Stripe then
		for _, s in { -1, 1 } do
			G.deco("BannerStripe", V(w, h * 0.08, 0.24), cf * CF(0, s * h * 0.42, 0), { opts.Stripe, M.Fabric }).CastShadow = false
		end
	end
	return cloth
end

---------------------------------------------------------------------------
-- Fondo (lejos, sin colisión ni sombra)
---------------------------------------------------------------------------

-- Gasómetro / depósito industrial: cilindro con aros y cúpula baja (silueta industrial del fondo)
function F.gasHolder(cf, d, h, look)
	look = get(look or "Steel")
	local body = Kit.cylinder("GasHolder", h, d, cf * CF(0, h / 2, 0), look[1], look[2], nil, true)
	body.CastShadow = false
	for _, y in { h * 0.33, h * 0.66 } do
		Kit.cylinder("GasHolderRing", 1, d + 0.8, cf * CF(0, y, 0), look[1]:Lerp(Color3.new(0, 0, 0), 0.3), M.Metal, nil, true).CastShadow = false
	end
	local dome = Kit.cylinder("GasHolderTop", 2, d * 0.85, cf * CF(0, h + 1, 0), look[1]:Lerp(Color3.new(1, 1, 1), 0.15), look[2], nil, true)
	dome.CastShadow = false
	return body
end

-- Esqueleto de edificio en obra (fondo): pilares y forjados sin muros, con una grúa encima si se pide
function F.skeleton(cf, w, d, floors, floorH, look)
	look = look or "Concrete"
	for f = 0, floors - 1 do
		local y = f * floorH
		G.deco("SkeletonSlab", V(w, 0.8, d), cf * CF(0, y + floorH, 0), look).CastShadow = false
		for _, p in { V(-w / 2 + 1, 0, -d / 2 + 1), V(w / 2 - 1, 0, -d / 2 + 1), V(-w / 2 + 1, 0, d / 2 - 1), V(w / 2 - 1, 0, d / 2 - 1) } do
			G.deco("SkeletonColumn", V(1.4, floorH, 1.4), cf * CF(p + V(0, y + floorH / 2, 0)), look).CastShadow = false
		end
	end
end

return F
