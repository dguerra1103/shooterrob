-- MALL RUSH · luz. Día luminoso por dentro (ambiente alto: el centro comercial está iluminado) y
-- variantes de tarde y de noche (las tiendas encendidas; fuera, la ciudad con ventanas).
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 14.2,
	Latitude = 30,
	Brightness = 2.8,
	Exposure = 0.05,
	Ambient = RGB(150, 150, 160),
	OutdoorAmbient = RGB(160, 160, 170),
	ShadowSoftness = 0.2,
	Atmosphere = { Density = 0.22, Offset = 0.1, Color = RGB(206, 220, 236), Decay = RGB(130, 150, 176), Glare = 0.15, Haze = 0.8 },
	Color = { Saturation = 0.16, Contrast = 0.1, Brightness = 0.02, Tint = RGB(255, 250, 248) },
	Bloom = { Intensity = 0.4, Size = 22, Threshold = 1.9 },
	Clouds = 0.35,
	CloudColor = RGB(255, 255, 255),
	SunRays = 0.06,
	Wind = V(4, 0, 2),
	TerrainColors = { Grass = RGB(96, 146, 72) },
}

Lighting.Variants = {
	{
		Name = "Atardecer",
		Chance = 0.3,
		ClockTime = 17.9,
		Brightness = 2.2,
		Ambient = RGB(150, 130, 136),
		OutdoorAmbient = RGB(170, 140, 130),
		Atmosphere = { Density = 0.26, Offset = 0.08, Color = RGB(250, 190, 160), Decay = RGB(160, 110, 130), Glare = 0.5, Haze = 1.2 },
		Color = { Saturation = 0.16, Contrast = 0.1, Brightness = 0.02, Tint = RGB(255, 238, 226) },
		CloudColor = RGB(255, 196, 170),
		SunRays = 0.1,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.5,
		Brightness = 1.2,
		Exposure = 0.3,
		Ambient = RGB(120, 120, 150),
		OutdoorAmbient = RGB(80, 88, 124),
		Atmosphere = { Density = 0.26, Offset = 0.06, Color = RGB(62, 70, 108), Decay = RGB(26, 30, 56), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.12, Contrast = 0.12, Brightness = 0.03, Tint = RGB(230, 232, 255) },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.5 },
		Clouds = 0.25,
		CloudColor = RGB(70, 76, 104),
		SunRays = 0,
	},
}

return Lighting
