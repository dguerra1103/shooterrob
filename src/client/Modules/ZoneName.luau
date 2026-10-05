-- Dónde estás (como en los shooters por equipos): debajo del minimapa, el nombre de la zona del mapa
-- («HOTEL CENTRAL», «AVENIDA», «BASE AZUL»). Las zonas con nombre las pone cada mapa (Kit.callout, y
-- los edificios con cartel); en el resto del mapa se dice la parte: «NORTE · LADO AZUL», «CENTRO».
-- Así un jugador puede decir «estoy en las obras» y todos saben dónde es. Solo en este cliente.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local ZoneName = {}

ZoneName.Interval = 0.25

local player = Players.LocalPlayer
local gui, label, scale
local clock = 0
local shown = nil
local mapInfo = nil -- { Map, Boxes = { { CFrame, Half, Volume, Name } }, Length, Width, Bases = { { Name, X } } }

-- Lo que se sabe del mapa (se calcula una vez por mapa)
local function readMap(map)
	local info = { Map = map, Boxes = {}, Bases = {}, ReadAt = os.clock() }
	local folder = map:FindFirstChild("Callouts")
	if folder then
		for _, box in folder:GetChildren() do
			local name = box:GetAttribute("Callout")
			if box:IsA("BasePart") and type(name) == "string" then
				table.insert(info.Boxes, {
					CFrame = box.CFrame,
					Half = box.Size / 2,
					Volume = box.Size.X * box.Size.Y * box.Size.Z,
					Name = name,
					Site = box:GetAttribute("Site") == true,
				})
			end
		end
	end
	-- Tamaño del mapa: por los muros invisibles del borde
	local boundary = map:FindFirstChild("Boundary")
	if boundary then
		local maxX, maxZ = 0, 0
		for _, wall in boundary:GetChildren() do
			if wall:IsA("BasePart") and wall.Size.Y > 4 then
				maxX = math.max(maxX, math.abs(wall.Position.X) - wall.Size.X / 2)
				maxZ = math.max(maxZ, math.abs(wall.Position.Z) - wall.Size.Z / 2)
			end
		end
		info.Length, info.Width = maxX * 2, maxZ * 2
		-- (mapas con solo techo invisible, como Downtown: su tamaño es el del techo)
		if maxX <= 0 or maxZ <= 0 then
			for _, roof in boundary:GetChildren() do
				if roof:IsA("BasePart") and roof.Size.X * roof.Size.Z > (info.Length or 0) * (info.Width or 0) then
					info.Length, info.Width = roof.Size.X, roof.Size.Z
				end
			end
		end
	end
	-- Lado de cada equipo: por dónde está su zona de salida
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, -10) == "SpawnFloor" then
			table.insert(info.Bases, { Name = string.upper(string.sub(d.Name, 1, -11)), X = d.Position.X })
		end
	end
	return info
end

-- Nombre de la zona en este punto del mapa (nil si no se sabe)
function ZoneName.At(position, info)
	local best = nil
	-- (los sitios de bomba solo cuentan en Buscar y destruir)
	local snd = game:GetService("ReplicatedStorage"):GetAttribute("Mode") == "SND"
	for _, box in info.Boxes do
		if box.Site and not snd then
			continue
		end
		local p = box.CFrame:PointToObjectSpace(position)
		if math.abs(p.X) <= box.Half.X and math.abs(p.Y) <= box.Half.Y and math.abs(p.Z) <= box.Half.Z then
			if not best or box.Volume < best.Volume then
				best = box
			end
		end
	end
	if best then
		return best.Name
	end
	-- Sin zona con nombre: la parte del mapa (norte/centro/sur y de qué lado)
	local length, width = info.Length, info.Width
	if not length or not width or length < 40 or width < 40 then
		return nil
	end
	local band = position.Z > width / 6 and "NORTE" or (position.Z < -width / 6 and "SUR" or "CENTRO")
	if math.abs(position.X) < length / 6 or #info.Bases < 2 then
		return band
	end
	local closest, gap = nil, math.huge
	for _, base in info.Bases do
		local d = math.abs(base.X - position.X)
		if d < gap then
			closest, gap = base, d
		end
	end
	return closest and (band .. " · LADO " .. closest.Name) or band
end

local function setText(name)
	if name == shown then
		return
	end
	shown = name
	label.Text = name and ("📍 " .. name) or ""
	if name then
		-- (al cambiar de zona, el nombre entra con un pequeño salto)
		scale.Scale = 1.15
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

function ZoneName.Update(dt)
	clock += dt or 0
	if clock < ZoneName.Interval then
		return
	end
	clock = 0
	local map = workspace:FindFirstChild("Map")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local visible = map ~= nil and root ~= nil and not ClientState.InMainMenu and not ClientState.Dead
		and not ClientState.KillcamActive
	gui.Enabled = visible
	if not visible or not map or not root then
		return
	end
	-- (el mapa llega al cliente en varios fotogramas: mientras se carga no se lee, y una lectura que
	-- salió incompleta, o la primera, se repite al rato)
	if game:GetService("ReplicatedStorage"):GetAttribute("LoadingMap") then
		mapInfo = nil
		setText(nil)
		return
	end
	-- (como mucho dos relecturas por mapa: muchos mapas no tienen zonas con nombre y no hay que
	-- recorrer el mapa entero cada poco)
	local stale = mapInfo ~= nil and mapInfo.Map == map and (mapInfo.Rereads or 0) < 2 and os.clock() - mapInfo.ReadAt > 3
		and (#mapInfo.Boxes == 0 or not mapInfo.Length or #mapInfo.Bases < 2 or (mapInfo.Rereads or 0) == 0)
	if not mapInfo or mapInfo.Map ~= map or stale then
		local rereads = (stale and mapInfo) and (mapInfo.Rereads or 0) + 1 or 0
		mapInfo = readMap(map)
		mapInfo.Rereads = rereads
	end
	setText(ZoneName.At(root.Position, mapInfo))
	-- Debajo del minimapa (y del botón de la tienda cuando se ve)
	local top = ClientState.MinimapBottom or 200
	local phone = UI.IsPhone()
	-- (en el móvil el botón de la tienda va siempre bajo el minimapa; en PC solo se ve fuera de combate
	-- y entonces va arriba, no debajo)
	local UserInputService = game:GetService("UserInputService")
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local below = phone and 40 or (touchOnly and 50 or 6)
	label.Position = UDim2.fromOffset(phone and 14 or 16, top + below)
end

function ZoneName.Init()
	gui = UI.new("ScreenGui", {
		Name = "ZoneName",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	label = UI.label({
		Position = UDim2.fromOffset(16, 200),
		Size = UDim2.fromOffset(230, 22),
		Text = "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(235, 240, 250),
		TextStrokeTransparency = 0.35,
		Parent = gui,
	})
	scale = UI.new("UIScale", { Parent = label })
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(ZoneName.Update, dt)
		if not ok then
			warn("[ZoneName]", err)
		end
	end)
end

return ZoneName
