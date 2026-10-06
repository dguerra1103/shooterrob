-- Identidad visual del flujo de entrada (lobby → partida): negro grafito, amarillo intenso (jugar,
-- acciones importantes, premios, selección), rojo (combate, eventos, alertas), blanco y un poco de
-- azul. Dos familias de letra: Oswald en negrita (títulos, botones y números) y Gotham (textos).
local Theme = {}

local RGB = Color3.fromRGB

Theme.Colors = {
	Bg = RGB(10, 11, 14),
	Panel = RGB(18, 20, 25),
	PanelLight = RGB(30, 33, 40),
	PanelHover = RGB(40, 44, 54),
	Line = RGB(255, 255, 255),
	Yellow = RGB(255, 198, 26),
	YellowDark = RGB(214, 150, 0),
	YellowText = RGB(255, 214, 72),
	Red = RGB(226, 38, 44),
	RedDark = RGB(140, 18, 24),
	Blue = RGB(54, 140, 255),
	Green = RGB(70, 214, 120),
	White = RGB(255, 255, 255),
	Text = RGB(238, 240, 244),
	TextDim = RGB(160, 166, 178),
	TextFaint = RGB(110, 116, 128),
	Black = RGB(0, 0, 0),
}

-- Transparencias de los paneles (oscuros y semitransparentes, con borde fino)
Theme.PanelAlpha = 0.18
Theme.LineAlpha = 0.86

-- Letras
local function font(path, weight, style)
	local ok, f = pcall(function()
		return Font.new(path, weight, style or Enum.FontStyle.Normal)
	end)
	return ok and f or nil
end
Theme.Fonts = {
	Title = font("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold),
	TitleItalic = font("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
	Number = font("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.SemiBold),
	Body = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	BodyBold = font("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
}
-- (respaldo si Font.new no existe: enumeraciones de siempre)
Theme.FontEnums = {
	Title = Enum.Font.Oswald,
	TitleItalic = Enum.Font.Oswald,
	Number = Enum.Font.Oswald,
	Body = Enum.Font.Gotham,
	BodyBold = Enum.Font.GothamBold,
}

-- Tamaños (en píxeles virtuales: la raíz se escala según la pantalla, ver Components.root)
Theme.Size = {
	Hero = 72,
	Title = 40,
	Subtitle = 24,
	Body = 16,
	Small = 13,
	Stat = 20,
}

-- Duraciones de las animaciones (rápidas: nada debe sentirse lento)
Theme.Time = {
	Hover = 0.1,
	Press = 0.08,
	Release = 0.16,
	Fast = 0.18,
	Normal = 0.3,
	Screen = 0.45,
	Stat = 0.25,
}

return Theme
