-- Vuelca un árbol de interfaz del simulador a JSON (para dibujarlo en HTML con guirender.py)
local serde = require("@lune/serde")
local fs = require("@lune/fs")

local function udim2(v)
	if typeof(v) ~= "UDim2" then return nil end
	return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset }
end
local function color(v)
	if typeof(v) ~= "Color3" then return nil end
	return { math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255) }
end
local function vec2(v)
	if typeof(v) ~= "Vector2" then return nil end
	return { v.X, v.Y }
end
local function enum(v)
	if v == nil then return nil end
	return tostring(v):gsub("^Enum%.%w+%.", "")
end

local function bool(v)
	if type(v) == "boolean" then return v end
	return nil
end
local function num(v)
	return type(v) == "number" and v or nil
end
local function node(inst)
	local p = rawget(inst, "__props")
	local t = {
		Class = rawget(inst, "__className"),
		Name = p.Name,
		Position = udim2(p.Position),
		Size = udim2(p.Size),
		AnchorPoint = vec2(p.AnchorPoint),
		Visible = bool(p.Visible),
		Enabled = bool(p.Enabled),
		DisplayOrder = num(p.DisplayOrder),
		BackgroundColor3 = color(p.BackgroundColor3),
		BackgroundTransparency = num(p.BackgroundTransparency),
		Text = type(p.Text) == "string" and p.Text or nil,
		TextColor3 = color(p.TextColor3),
		TextSize = num(p.TextSize),
		TextScaled = bool(p.TextScaled),
		TextWrapped = bool(p.TextWrapped),
		TextTransparency = num(p.TextTransparency),
		RichText = bool(p.RichText),
		TextXAlignment = enum(p.TextXAlignment),
		Rotation = num(p.Rotation),
		LayoutOrder = num(p.LayoutOrder),
		ZIndex = num(p.ZIndex),
		Scale = num(p.Scale),
		FillDirection = enum(p.FillDirection),
		HorizontalAlignment = enum(p.HorizontalAlignment),
		Padding = p.Padding and typeof(p.Padding) == "UDim" and { p.Padding.Scale, p.Padding.Offset } or nil,
		CellSize = udim2(p.CellSize),
		CellPadding = udim2(p.CellPadding),
		CornerRadius = p.CornerRadius and typeof(p.CornerRadius) == "UDim" and { p.CornerRadius.Scale, p.CornerRadius.Offset } or nil,
		Color = color(p.Color),
		Thickness = num(p.Thickness),
		Transparency = num(p.Transparency),
		ClipsDescendants = bool(p.ClipsDescendants),
		PaddingTop = p.PaddingTop and typeof(p.PaddingTop) == "UDim" and { p.PaddingTop.Scale, p.PaddingTop.Offset } or nil,
		PaddingBottom = p.PaddingBottom and typeof(p.PaddingBottom) == "UDim" and { p.PaddingBottom.Scale, p.PaddingBottom.Offset } or nil,
		PaddingLeft = p.PaddingLeft and typeof(p.PaddingLeft) == "UDim" and { p.PaddingLeft.Scale, p.PaddingLeft.Offset } or nil,
		PaddingRight = p.PaddingRight and typeof(p.PaddingRight) == "UDim" and { p.PaddingRight.Scale, p.PaddingRight.Offset } or nil,
		AutomaticSize = enum(p.AutomaticSize),
		Font = enum(p.Font),
		TextYAlignment = enum(p.TextYAlignment),
		VerticalAlignment = enum(p.VerticalAlignment),
		Italic = (typeof(p.FontFace) == "Font" and string.find(tostring(p.FontFace.Style), "Italic") ~= nil) or nil,
		Children = {},
	}
	for _, child in rawget(inst, "__children") do
		table.insert(t.Children, node(child))
	end
	return t
end

return function(root, path)
	fs.writeFile(path, serde.encode("json", node(root)))
end
