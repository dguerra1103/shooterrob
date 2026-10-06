-- COSTA · luz. Por defecto, tarde soleada de verano como la referencia (cielo azul, mar intenso,
-- sombras cálidas y cortas). Variantes: atardecer dorado y noche con faroles y el faro encendido.
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 15.6,
	Latitude = 36,
	Brightness = 3.1,
	Exposure = -0.05,
	Ambient = RGB(98, 92, 88),
	OutdoorAmbient = RGB(150, 146, 140),
	ShadowSoftness = 0.12,
	Atmosphere = { Density = 0.26, Offset = 0.1, Color = RGB(200, 222, 240), Decay = RGB(120, 150, 186), Glare = 0.25, Haze = 1 },
	Color = { Saturation = 0.14, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 248, 236) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2.1 },
	Clouds = 0.32,
	CloudColor = RGB(255, 255, 255),
	SunRays = 0.06,
	Wind = V(8, 0, 4),
	Water = { Color = RGB(20, 96, 150), Reflectance = 0.6, Transparency = 0.45, WaveSize = 0.18, WaveSpeed = 12 },
	TerrainColors = { Rock = RGB(150, 138, 120), Sand = RGB(214, 194, 150), Grass = RGB(110, 140, 70), Ground = RGB(150, 130, 100) },
}

Lighting.Variants = {
	{
		Name = "Atardecer",
		Chance = 0.3,
		ClockTime = 18.1,
		Brightness = 2.4,
		Exposure = 0.05,
		Ambient = RGB(110, 86, 82),
		OutdoorAmbient = RGB(160, 126, 112),
		Atmosphere = { Density = 0.3, Offset = 0.08, Color = RGB(250, 190, 150), Decay = RGB(170, 110, 110), Glare = 0.6, Haze = 1.3 },
		Color = { Saturation = 0.12, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 232, 210) },
		CloudColor = RGB(255, 190, 160),
		SunRays = 0.12,
		Water = { Color = RGB(40, 80, 120), Reflectance = 0.8, Transparency = 0.4, WaveSize = 0.15, WaveSpeed = 10 },
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.4,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(66, 70, 98),
		OutdoorAmbient = RGB(80, 90, 126),
		Atmosphere = { Density = 0.28, Offset = 0.06, Color = RGB(60, 70, 110), Decay = RGB(26, 30, 56), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.06, Contrast = 0.14, Brightness = 0.03, Tint = RGB(214, 222, 255) },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.5 },
		Clouds = 0.25,
		CloudColor = RGB(70, 76, 104),
		SunRays = 0,
		Water = { Color = RGB(14, 30, 60), Reflectance = 1, Transparency = 0.3, WaveSize = 0.15, WaveSpeed = 8 },
	},
}

return Lighting
