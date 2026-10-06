-- DESERT BASE · luz. Sol alto y seco (sombras marcadas, cielo pálido con calima); variantes de
-- atardecer anaranjado y de noche (focos del patio encendidos).
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 13.4,
	Latitude = 28,
	Brightness = 3.2,
	Exposure = -0.05,
	Ambient = RGB(120, 108, 92),
	OutdoorAmbient = RGB(170, 156, 136),
	ShadowSoftness = 0.12,
	Atmosphere = { Density = 0.34, Offset = 0.15, Color = RGB(232, 214, 184), Decay = RGB(176, 150, 112), Glare = 0.3, Haze = 1.8 },
	Color = { Saturation = 0.06, Contrast = 0.14, Brightness = 0.01, Tint = RGB(255, 246, 232) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.1,
	CloudColor = RGB(255, 248, 236),
	SunRays = 0.08,
	Wind = V(14, 0, 4),
	TerrainColors = { Sand = RGB(214, 188, 140), Sandstone = RGB(176, 128, 92) },
}

Lighting.Variants = {
	{
		Name = "Atardecer",
		Chance = 0.3,
		ClockTime = 17.9,
		Brightness = 2.4,
		Ambient = RGB(124, 92, 80),
		OutdoorAmbient = RGB(180, 128, 106),
		Atmosphere = { Density = 0.36, Offset = 0.1, Color = RGB(250, 172, 120), Decay = RGB(170, 96, 80), Glare = 0.7, Haze = 1.8 },
		Color = { Saturation = 0.14, Contrast = 0.14, Brightness = 0.01, Tint = RGB(255, 226, 200) },
		CloudColor = RGB(255, 180, 130),
		SunRays = 0.14,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 22,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(72, 74, 96),
		OutdoorAmbient = RGB(88, 92, 120),
		Atmosphere = { Density = 0.3, Offset = 0.06, Color = RGB(64, 70, 100), Decay = RGB(30, 30, 50), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.06, Contrast = 0.14, Brightness = 0.03, Tint = RGB(220, 226, 255) },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.5 },
		Clouds = 0.1,
		CloudColor = RGB(70, 76, 100),
		SunRays = 0,
	},
}

return Lighting
