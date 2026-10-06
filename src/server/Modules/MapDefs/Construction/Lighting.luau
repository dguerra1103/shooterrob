-- CONSTRUCCIÓN · luz. Por defecto, atardecer como la referencia (sol bajo naranja, cielo malva y
-- neblina cálida que difumina el horizonte de la ciudad). Variantes: mediodía y noche (ventanas de
-- la ciudad encendidas, focos de obra). Bloom muy moderado: los enemigos tienen que destacar.
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 17.55,
	Latitude = 22,
	Brightness = 2.6,
	Exposure = 0.05,
	Ambient = RGB(96, 82, 92),
	OutdoorAmbient = RGB(150, 128, 140),
	ShadowSoftness = 0.1,
	Atmosphere = { Density = 0.3, Offset = 0.08, Color = RGB(236, 176, 160), Decay = RGB(128, 96, 140), Glare = 0.5, Haze = 1.3 },
	Color = { Saturation = 0.1, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 238, 226) },
	Bloom = { Intensity = 0.4, Size = 22, Threshold = 2 },
	Clouds = 0.28,
	CloudColor = RGB(255, 196, 176),
	SunRays = 0.1,
	Wind = V(5, 0, 2),
	TerrainColors = { Ground = RGB(128, 112, 92), Rock = RGB(112, 100, 108), Pavement = RGB(150, 146, 140), Concrete = RGB(160, 156, 150) },
}

Lighting.Variants = {
	{
		Name = "Mediodía",
		Chance = 0.3,
		ClockTime = 13.2,
		Brightness = 3,
		Exposure = -0.05,
		Ambient = RGB(92, 92, 100),
		OutdoorAmbient = RGB(146, 146, 156),
		Atmosphere = { Density = 0.28, Offset = 0.1, Color = RGB(206, 214, 226), Decay = RGB(120, 132, 150), Glare = 0.2, Haze = 1.1 },
		Color = { Saturation = 0.1, Contrast = 0.12, Brightness = 0, Tint = RGB(255, 250, 244) },
		CloudColor = RGB(255, 255, 255),
		Clouds = 0.4,
		SunRays = 0.05,
	},
	{
		-- Noche: luz de luna fría y focos de obra cálidos (las ventanas de la ciudad, encendidas)
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.2,
		Brightness = 1.2,
		Exposure = 0.35,
		Ambient = RGB(66, 70, 96),
		OutdoorAmbient = RGB(84, 92, 128),
		Atmosphere = { Density = 0.3, Offset = 0.06, Color = RGB(64, 72, 110), Decay = RGB(30, 30, 58), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.04, Contrast = 0.14, Brightness = 0.03, Tint = RGB(214, 222, 255) },
		Bloom = { Intensity = 0.65, Size = 24, Threshold = 1.5 },
		Clouds = 0.3,
		CloudColor = RGB(70, 74, 100),
		SunRays = 0,
	},
}

return Lighting
