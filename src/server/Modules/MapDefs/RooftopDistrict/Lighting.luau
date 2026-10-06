-- ROOFTOP DISTRICT · luz. Día claro y frío como la referencia (cielo azul, ciudad con neblina azul
-- al fondo); variantes de atardecer y de noche (pantallas y ventanas encendidas).
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 11.5,
	Latitude = 40,
	Brightness = 3,
	Exposure = -0.02,
	Ambient = RGB(100, 106, 120),
	OutdoorAmbient = RGB(148, 156, 172),
	ShadowSoftness = 0.15,
	Atmosphere = { Density = 0.3, Offset = 0.12, Color = RGB(196, 214, 236), Decay = RGB(116, 140, 176), Glare = 0.15, Haze = 1.3 },
	Color = { Saturation = 0.1, Contrast = 0.12, Brightness = 0.01, Tint = RGB(244, 248, 255) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.45,
	CloudColor = RGB(255, 255, 255),
	SunRays = 0.05,
	Wind = V(10, 0, 4),
	TerrainColors = { Asphalt = RGB(66, 68, 72) },
}

Lighting.Variants = {
	{
		Name = "Atardecer",
		Chance = 0.3,
		ClockTime = 18,
		Brightness = 2.3,
		Ambient = RGB(110, 90, 100),
		OutdoorAmbient = RGB(160, 130, 130),
		Atmosphere = { Density = 0.3, Offset = 0.08, Color = RGB(246, 180, 150), Decay = RGB(150, 100, 120), Glare = 0.6, Haze = 1.3 },
		Color = { Saturation = 0.12, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 234, 220) },
		CloudColor = RGB(255, 190, 160),
		SunRays = 0.12,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.5,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(66, 72, 100),
		OutdoorAmbient = RGB(80, 90, 128),
		Atmosphere = { Density = 0.28, Offset = 0.06, Color = RGB(60, 70, 110), Decay = RGB(26, 30, 56), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.08, Contrast = 0.14, Brightness = 0.03, Tint = RGB(214, 222, 255) },
		Bloom = { Intensity = 0.65, Size = 24, Threshold = 1.5 },
		Clouds = 0.25,
		CloudColor = RGB(70, 76, 104),
		SunRays = 0,
	},
}

return Lighting
