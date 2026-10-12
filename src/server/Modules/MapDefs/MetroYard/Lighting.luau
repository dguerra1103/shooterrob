-- METRO YARD · luz. Tarde urbana templada (sol bajo que entra por la playa de vías, cielo algo
-- velado); variantes de atardecer naranja y de noche (marquesinas, túnel y ciudad encendidos).
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 15.2,
	Latitude = 38,
	Brightness = 2.5,
	Exposure = -0.1,
	Ambient = RGB(104, 106, 116),
	OutdoorAmbient = RGB(150, 152, 164),
	ShadowSoftness = 0.2,
	-- (menos bruma y más contraste: los muros claros y el suelo se fundían en un blanco azulado)
	Atmosphere = { Density = 0.25, Offset = 0.1, Color = RGB(206, 212, 224), Decay = RGB(130, 140, 162), Glare = 0.2, Haze = 1 },
	Color = { Saturation = 0.15, Contrast = 0.16, Brightness = 0, Tint = RGB(255, 250, 242) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.55,
	CloudColor = RGB(240, 242, 246),
	SunRays = 0.06,
	Wind = V(8, 0, 3),
	TerrainColors = { Asphalt = RGB(70, 72, 76) },
}

Lighting.Variants = {
	{
		Name = "Atardecer",
		Chance = 0.3,
		ClockTime = 17.9,
		Brightness = 2.2,
		Ambient = RGB(112, 92, 96),
		OutdoorAmbient = RGB(168, 132, 124),
		Atmosphere = { Density = 0.32, Offset = 0.08, Color = RGB(250, 184, 140), Decay = RGB(156, 104, 112), Glare = 0.6, Haze = 1.4 },
		Color = { Saturation = 0.14, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 232, 214) },
		CloudColor = RGB(255, 188, 150),
		SunRays = 0.12,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.5,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(70, 74, 98),
		OutdoorAmbient = RGB(84, 92, 124),
		Atmosphere = { Density = 0.3, Offset = 0.06, Color = RGB(62, 70, 104), Decay = RGB(28, 30, 52), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.08, Contrast = 0.14, Brightness = 0.03, Tint = RGB(216, 224, 255) },
		Bloom = { Intensity = 0.65, Size = 24, Threshold = 1.5 },
		Clouds = 0.3,
		CloudColor = RGB(72, 78, 104),
		SunRays = 0,
	},
}

return Lighting
