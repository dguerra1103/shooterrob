-- INDUSTRIAL YARD · luz. Atardecer por defecto (sol bajo naranja que alarga las sombras de los
-- depósitos y la chimenea, cielo cálido con algo de humo); variantes de día y de noche.
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 17.7,
	Latitude = 36,
	Brightness = 2.5,
	Exposure = 0,
	Ambient = RGB(118, 98, 92),
	OutdoorAmbient = RGB(176, 140, 120),
	ShadowSoftness = 0.2,
	Atmosphere = { Density = 0.36, Offset = 0.1, Color = RGB(244, 178, 132), Decay = RGB(160, 100, 96), Glare = 0.6, Haze = 1.8 },
	Color = { Saturation = 0.14, Contrast = 0.14, Brightness = 0.01, Tint = RGB(255, 230, 208) },
	Bloom = { Intensity = 0.4, Size = 22, Threshold = 1.9 },
	Clouds = 0.45,
	CloudColor = RGB(255, 190, 150),
	SunRays = 0.14,
	Wind = V(8, 0, 4),
	TerrainColors = { Ground = RGB(120, 116, 110) },
}

Lighting.Variants = {
	{
		Name = "Día",
		Chance = 0.3,
		ClockTime = 13,
		Brightness = 3,
		Ambient = RGB(106, 108, 116),
		OutdoorAmbient = RGB(154, 156, 166),
		Atmosphere = { Density = 0.32, Offset = 0.12, Color = RGB(206, 210, 218), Decay = RGB(130, 136, 150), Glare = 0.2, Haze = 1.5 },
		Color = { Saturation = 0.08, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 250, 244) },
		CloudColor = RGB(244, 246, 250),
		SunRays = 0.06,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.6,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(72, 72, 94),
		OutdoorAmbient = RGB(88, 90, 118),
		Atmosphere = { Density = 0.32, Offset = 0.06, Color = RGB(70, 68, 96), Decay = RGB(30, 28, 48), Glare = 0, Haze = 1.2 },
		Color = { Saturation = 0.08, Contrast = 0.14, Brightness = 0.03, Tint = RGB(222, 222, 255) },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.5 },
		Clouds = 0.35,
		CloudColor = RGB(74, 74, 100),
		SunRays = 0,
	},
}

return Lighting
