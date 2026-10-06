-- DOCKYARD · luz. Mañana despejada junto al mar (luz fría, algo de bruma sobre el agua);
-- variantes de atardecer y de noche (focos del puerto encendidos).
local RGB = Color3.fromRGB
local V = Vector3.new

local Lighting = {}

Lighting.Default = {
	ClockTime = 10.6,
	Latitude = 42,
	Brightness = 3,
	Exposure = -0.02,
	Ambient = RGB(104, 110, 122),
	OutdoorAmbient = RGB(150, 160, 176),
	ShadowSoftness = 0.15,
	Atmosphere = { Density = 0.33, Offset = 0.12, Color = RGB(200, 216, 232), Decay = RGB(120, 142, 172), Glare = 0.2, Haze = 1.6 },
	Color = { Saturation = 0.1, Contrast = 0.12, Brightness = 0.01, Tint = RGB(246, 250, 255) },
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 2 },
	Clouds = 0.4,
	CloudColor = RGB(250, 252, 255),
	SunRays = 0.06,
	Wind = V(12, 0, 6),
	TerrainColors = { Asphalt = RGB(76, 78, 82), Water = RGB(40, 82, 110) },
}

Lighting.Variants = {
	{
		Name = "Atardecer",
		Chance = 0.3,
		ClockTime = 18,
		Brightness = 2.3,
		Ambient = RGB(118, 94, 96),
		OutdoorAmbient = RGB(172, 132, 124),
		Atmosphere = { Density = 0.34, Offset = 0.08, Color = RGB(248, 180, 140), Decay = RGB(160, 100, 112), Glare = 0.6, Haze = 1.6 },
		Color = { Saturation = 0.14, Contrast = 0.12, Brightness = 0.01, Tint = RGB(255, 230, 212) },
		CloudColor = RGB(255, 186, 150),
		SunRays = 0.12,
	},
	{
		Name = "Noche",
		Chance = 0.25,
		ClockTime = 21.8,
		Brightness = 1.1,
		Exposure = 0.35,
		Ambient = RGB(70, 76, 100),
		OutdoorAmbient = RGB(84, 94, 126),
		Atmosphere = { Density = 0.3, Offset = 0.06, Color = RGB(62, 72, 106), Decay = RGB(26, 30, 54), Glare = 0, Haze = 1 },
		Color = { Saturation = 0.08, Contrast = 0.14, Brightness = 0.03, Tint = RGB(214, 224, 255) },
		Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.5 },
		Clouds = 0.3,
		CloudColor = RGB(70, 78, 106),
		SunRays = 0,
	},
}

return Lighting
