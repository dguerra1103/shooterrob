-- Versiones de luz y clima que cualquier mapa exterior puede usar (Map.LightingVariants): en cada
-- partida, a veces, el mapa sale al atardecer, con tormenta y lluvia, con niebla de primera hora o con
-- ventisca. Solo cambian la luz y el tiempo; los colores del terreno, el agua y el cielo del mapa se
-- quedan. Kit.pickLighting elige una (o ninguna) y el cliente pone la lluvia, el viento y los truenos.
local RGB = Color3.fromRGB

local Variants = {}

-- Atardecer: sol bajo y anaranjado, sombras largas y cielo cálido
function Variants.Sunset(chance)
	return {
		Name = "Atardecer",
		Chance = chance or 0.25,
		ClockTime = 17.65,
		Brightness = 2.1,
		Exposure = 0.05,
		Ambient = RGB(84, 70, 64),
		OutdoorAmbient = RGB(158, 126, 108),
		Atmosphere = { Density = 0.34, Offset = 0.12, Color = RGB(236, 196, 160), Decay = RGB(150, 104, 86), Glare = 0.45, Haze = 1.8 },
		Color = { Saturation = 0.02, Contrast = 0.14, Brightness = 0, Tint = RGB(255, 236, 216) },
		Clouds = 0.45,
		CloudColor = RGB(255, 214, 186),
		SunRays = 0.09,
	}
end

-- Tormenta: cielo cubierto, luz gris, lluvia, viento y truenos
function Variants.Storm(chance)
	return {
		Name = "Tormenta",
		Chance = chance or 0.25,
		Weather = "Rain",
		ClockTime = 15.5,
		Brightness = 1.2,
		Exposure = -0.05,
		Ambient = RGB(62, 66, 72),
		OutdoorAmbient = RGB(104, 110, 118),
		Atmosphere = { Density = 0.42, Offset = 0.08, Color = RGB(152, 158, 166), Decay = RGB(92, 98, 108), Glare = 0, Haze = 2.6 },
		Color = { Saturation = -0.2, Contrast = 0.12, Brightness = 0, Tint = RGB(226, 232, 240) },
		Bloom = { Intensity = 0.3, Size = 20, Threshold = 2.4 },
		Clouds = 1,
		CloudColor = RGB(122, 126, 132),
		SunRays = 0,
		Wind = Vector3.new(14, 0, -6),
	}
end

-- Niebla de primera hora: luz blanca y suave, se ve menos de lejos
function Variants.Fog(chance)
	return {
		Name = "Niebla",
		Chance = chance or 0.2,
		ClockTime = 7.6,
		Brightness = 1.9,
		Ambient = RGB(82, 88, 94),
		OutdoorAmbient = RGB(142, 150, 158),
		Atmosphere = { Density = 0.5, Offset = 0.05, Color = RGB(206, 213, 220), Decay = RGB(150, 160, 170), Glare = 0, Haze = 3 },
		Color = { Saturation = -0.15, Contrast = 0.1, Brightness = 0.02, Tint = RGB(236, 242, 250) },
		Clouds = 0.85,
		SunRays = 0.02,
	}
end

-- Ventisca (mapas de nieve): viento fuerte, nieve que cae de lado y poca visibilidad
function Variants.Blizzard(chance)
	return {
		Name = "Ventisca",
		Chance = chance or 0.3,
		Weather = "Snowstorm",
		ClockTime = 14,
		Brightness = 1.6,
		Ambient = RGB(86, 92, 104),
		OutdoorAmbient = RGB(150, 158, 172),
		Atmosphere = { Density = 0.5, Offset = 0.06, Color = RGB(214, 222, 232), Decay = RGB(160, 172, 190), Glare = 0, Haze = 3.2 },
		Color = { Saturation = -0.15, Contrast = 0.1, Brightness = 0.02, Tint = RGB(236, 242, 255) },
		Clouds = 1,
		CloudColor = RGB(214, 220, 228),
		SunRays = 0,
		Wind = Vector3.new(22, 0, 8),
	}
end

return Variants
