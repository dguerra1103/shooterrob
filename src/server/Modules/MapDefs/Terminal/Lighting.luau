-- TERMINAL · luz. Por defecto, atardecer naranja con el sol bajo sobre la pista, como la
-- referencia (cristales azulados encendidos, focos de plataforma). Variantes: día y noche.
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 17.7,
	Latitude = 30,
	Brightness = 2.5,
	Exposure = 0.05,
	Ambient = RGB(100, 84, 84),
	OutdoorAmbient = RGB(156, 130, 120),
	ShadowSoftness = 0.1,
	Atmosphere = { Density = 0.3, Offset = 0.08, Color = RGB(250, 184, 140), Decay = RGB(150, 96, 110), Glare = 0.6, Haze = 1.3 },
	Color = { Saturation = 0.12, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 236, 218) },
	Bloom = { Intensity = 0.42, Size = 22, Threshold = 1.9 },
	Clouds = 0.3,
	CloudColor = RGB(255, 186, 150),
	SunRays = 0.12,
	Wind = V(6, 0, 2),
	TerrainColors = { Grass = RGB(104, 128, 70), LeafyGrass = RGB(98, 132, 66), Ground = RGB(120, 106, 84), Asphalt = RGB(80, 82, 86) },
}

Lighting.Variants = {
	{
		Name = "Mediodía",
		Chance = 0.3,
		ClockTime = 13,
		Brightness = 3,
		Exposure = -0.05,
		Ambient = RGB(92, 94, 100),
		OutdoorAmbient = RGB(150, 152, 160),
		Atmosphere = { Density = 0.26, Offset = 0.1, Color = RGB(206, 216, 230), Decay = RGB(124, 140, 160), Glare = 0.2, Haze = 1 },
		Color = { Saturation = 0.1, Contrast = 0.12, Brightness = 0, Tint = RGB(255, 250, 246) },
		CloudColor = RGB(255, 255, 255),
		Clouds = 0.4,
		SunRays = 0.05,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.3,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(66, 72, 98),
		OutdoorAmbient = RGB(82, 92, 126),
		Atmosphere = { Density = 0.28, Offset = 0.06, Color = RGB(62, 70, 108), Decay = RGB(26, 30, 56), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.05, Contrast = 0.14, Brightness = 0.03, Tint = RGB(214, 222, 255) },
		Bloom = { Intensity = 0.65, Size = 24, Threshold = 1.5 },
		Clouds = 0.25,
		CloudColor = RGB(70, 76, 104),
		SunRays = 0,
	},
}

return Lighting
