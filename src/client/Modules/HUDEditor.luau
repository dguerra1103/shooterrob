-- Editor de los controles táctiles (Fase 12): Ajustes → Controles táctiles → PERSONALIZAR HUD.
-- Se ven todos los controles (también los que el ajuste tiene apagados) sobre el juego oscurecido; se
-- toca uno para elegirlo y se arrastra para moverlo; TAMAÑO y OPACIDAD con dos barras. GUARDAR lo
-- guarda en los ajustes del jugador (Settings.HudLayout: los guarda el servidor con el resto del
-- perfil, después de validarlos con shared/MobileHUD), CANCELAR lo deja como estaba y RESTABLECER
-- vuelve a la disposición por defecto (la de la Fase 15, la de la versión MobileHUD.LayoutVersion).
-- Mientras está abierto no se juega (ClientState.HUDEditorOpen).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobileHUD = require(Shared.MobileHUD)

local ClientState = require(script.Parent.ClientState)
local Settings = require(script.Parent.Settings)
local TouchLayout = require(script.Parent.TouchLayout)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local HUDEditor = {}

local YELLOW = Color3.fromRGB(255, 205, 60)
local PANEL = Color3.fromRGB(14, 16, 22)

local gui, dim
local working: { [string]: any } = {}
local selected = "Fire"
local connections: { RBXScriptConnection } = {}
local onClosed: (() -> ())? = nil
local previousRelayout = nil
local overlay: { [string]: { Label: TextLabel, Ring: Frame } } = {}
local refreshPanel: () -> () = function() end

local function copy(layout)
	local out = {}
	for id, item in MobileHUD.Validate(layout) do
		out[id] = table.clone(item)
	end
	return out
end

local function apply()
	TouchLayout.SetEditing(true, working)
end

-- Nombre y marco de cada control encima de él (se recolocan con cada cambio)
local function drawOverlay(layout)
	if not gui then
		return
	end
	local s = Settings.Get()
	for id, info in layout do
		if TouchLayout.Entries()[id] then
			local item = overlay[id]
			if not item then
				local ring = UI.new("Frame", {
					Name = "Sel_" .. id,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Parent = gui,
				}, { UI.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
				local stroke = UI.new("UIStroke", { Color = YELLOW, Thickness = 3, Parent = ring })
				local _ = stroke
				-- (solo en el editor: el texto se encoge para que los nombres no se pisen)
				local label = UI.label({
					Name = "Name_" .. id,
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.fromOffset(60, 14),
					TextSize = 12,
					TextScaled = true,
					TextStrokeTransparency = 0.2,
					Parent = gui,
				}, { UI.new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 8 }) })
				item = { Label = label, Ring = ring }
				overlay[id] = item
			end
			local control = MobileHUD.ById[id]
			local off = (id == "LeftFire" and (s.LeftFire or 0) ~= 1) or (id == "Sprint" and (s.AutoSprint or 1) == 1)
			item.Label.Text = (control and control.Name or id) .. (off and " (apagado)" or "")
			item.Label.TextColor3 = id == selected and YELLOW or Color3.new(1, 1, 1)
			item.Label.Position = UDim2.fromOffset(math.floor(info.Center.X), math.floor(info.Center.Y + info.Size.Y / 2 + 2))
			item.Label.Size = UDim2.fromOffset(math.floor(math.max(info.Size.X + 8, 52)), 14)
			item.Ring.Position = UDim2.fromOffset(math.floor(info.Center.X), math.floor(info.Center.Y))
			item.Ring.Size = UDim2.fromOffset(math.floor(info.Size.X + 8), math.floor(info.Size.Y + 8))
			item.Ring.Visible = id == selected
			local corner = item.Ring:FindFirstChildOfClass("UICorner")
			if corner then
				corner.CornerRadius = (control and control.Shape ~= "Round") and UDim.new(0, 12) or UDim.new(0.5, 0)
			end
		end
	end
end

-- El control que hay bajo un punto (el más pequeño si se tocan: es el que se quería)
local function pick(point: Vector2): string?
	local layout = TouchLayout.GetLayout()
	local best, bestArea
	for id, info in layout do
		if TouchLayout.Entries()[id] then
			local d = point - info.Center
			local half = info.Hit / 2
			if math.abs(d.X) <= half.X and math.abs(d.Y) <= half.Y then
				local area = info.Size.X * info.Size.Y
				if not bestArea or area < bestArea then
					best, bestArea = id, area
				end
			end
		end
	end
	return best
end

local function areaOf(): (Vector2, Vector2)
	local size, origin = gui.AbsoluteSize, gui.AbsolutePosition
	if typeof(size) ~= "Vector2" or size.X < 50 then
		local camera = workspace.CurrentCamera
		size = camera and camera.ViewportSize or Vector2.new(844, 390)
		origin = Vector2.zero
	end
	if typeof(origin) ~= "Vector2" then
		origin = Vector2.zero
	end
	return size, origin
end

-- Mueve el control elegido a `center` (píxeles de la zona segura): se guarda como fracción de la
-- pantalla, así vale también si se gira o cambia de tamaño
function HUDEditor.MoveSelected(center: Vector2)
	local size = areaOf()
	local item = working[selected] or {}
	item.X = math.clamp(center.X / size.X, 0, 1)
	item.Y = math.clamp(center.Y / size.Y, 0, 1)
	working[selected] = item
	apply()
end

function HUDEditor.Select(id: string)
	if MobileHUD.ById[id] then
		selected = id
		refreshPanel()
		drawOverlay(TouchLayout.GetLayout())
	end
end

-- Tamaño u opacidad del elegido (S, O): se recortan a MobileHUD.Limits
function HUDEditor.SetValue(key: string, value: number)
	local limits = MobileHUD.Limits[key]
	if not limits then
		return
	end
	local item = working[selected] or {}
	item[key] = math.clamp(value, limits[1], limits[2])
	working[selected] = item
	apply()
	refreshPanel()
end

function HUDEditor.Reset()
	working = {}
	apply()
	refreshPanel()
end

function HUDEditor.Working()
	return working
end

local function slider(parent, position: UDim2, width: number, title: string, key: string)
	local holder = UI.new("Frame", {
		Position = position,
		Size = UDim2.fromOffset(width, 34),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local text = UI.label({
		Size = UDim2.new(1, 0, 0, 14),
		Text = title,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	local track = UI.new("TextButton", {
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = holder,
	})
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Color3.fromRGB(70, 74, 88),
		BorderSizePixel = 0,
		Parent = track,
	}, { UI.corner(2) })
	local knob = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = YELLOW,
		BorderSizePixel = 0,
		Parent = track,
	}, { UI.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	local limits = MobileHUD.Limits[key]
	local function show()
		local value = (working[selected] and working[selected][key]) or 1
		local f = (value - limits[1]) / (limits[2] - limits[1])
		knob.Position = UDim2.fromScale(math.clamp(f, 0, 1), 0.5)
		text.Text = string.format("%s  %d%%", title, math.floor(value * 100 + 0.5))
	end
	local dragging
	local function at(x: number)
		local left, w = track.AbsolutePosition.X, track.AbsoluteSize.X
		if typeof(left) ~= "number" or typeof(w) ~= "number" or w <= 0 then
			return
		end
		local f = math.clamp((x - left) / w, 0, 1)
		local value = limits[1] + f * (limits[2] - limits[1])
		HUDEditor.SetValue(key, math.floor(value * 20 + 0.5) / 20)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = input
			at(input.Position.X)
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragging or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			at(input.Position.X)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input == dragging then
			dragging = nil
		end
	end))
	return show
end

local function close(save: boolean, silent: boolean?)
	if not gui then
		return
	end
	if save then
		Settings.Set("HudLayout", working)
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	TouchLayout.OnRelayout = previousRelayout
	previousRelayout = nil
	gui:Destroy()
	gui = nil
	if dim then
		dim:Destroy()
		dim = nil
	end
	table.clear(overlay)
	ClientState.HUDEditorOpen = false
	TouchLayout.SetEditing(false)
	ClientState.UpdateMouse()
	local callback = onClosed
	onClosed = nil
	if callback and not silent then
		task.defer(callback)
	end
end

-- Revisión de la disposición que se está editando (Fase 16, MobileHUD.CheckLayout): solo bloquea
-- dos controles de combate uno encima del otro; avisa si se tocan o si algo entra en el centro
function HUDEditor.Check()
	local size = areaOf()
	local s = Settings.Get()
	local ids = {}
	for _, control in MobileHUD.Controls do
		local off = (control.Id == "LeftFire" and (s.LeftFire or 0) ~= 1) or (control.Id == "Sprint" and (s.AutoSprint or 1) == 1)
		if not off and TouchLayout.Entries()[control.Id] then
			table.insert(ids, control.Id)
		end
	end
	return MobileHUD.CheckLayout(size, TouchLayout.GetLayout(), ids)
end

local function describe(pair): string
	local a, b = MobileHUD.ById[pair[1]], MobileHUD.ById[pair[2]]
	if pair[2] == "Center" then
		return (a and a.Name or pair[1]) .. " está en el centro (tapa la mira)"
	end
	return (a and a.Name or pair[1]) .. " y " .. (b and b.Name or pair[2])
end

-- Texto del estado (debajo de los botones del panel)
local status: TextLabel? = nil
local saveButton: TextButton? = nil
local function showStatus()
	if not status then
		return
	end
	local check = HUDEditor.Check()
	local label = status :: TextLabel
	if #check.Blocking > 0 then
		label.Text = "No se puede guardar: " .. describe(check.Blocking[1]) .. " están uno encima del otro"
		label.TextColor3 = Color3.fromRGB(255, 110, 100)
	elseif #check.Warnings > 0 then
		local pair = check.Warnings[1]
		label.Text = "Aviso: " .. describe(pair) .. (pair[2] == "Center" and "" or " se tocan")
		label.TextColor3 = YELLOW
	else
		label.Text = "Sin choques"
		label.TextColor3 = Color3.fromRGB(150, 220, 160)
	end
	if saveButton then
		saveButton.AutoButtonColor = #check.Blocking == 0
		saveButton.BackgroundTransparency = #check.Blocking > 0 and 0.6 or 0
	end
	return check
end

function HUDEditor.Save(): boolean
	-- (dos controles de combate uno encima del otro: no se guarda, se dice por qué)
	local check = HUDEditor.Check()
	if #check.Blocking > 0 then
		showStatus()
		return false
	end
	close(true)
	return true
end

function HUDEditor.Cancel()
	close(false)
end

function HUDEditor.IsOpen(): boolean
	return gui ~= nil
end

local function build()
	local playerGui = player:WaitForChild("PlayerGui")
	-- Fondo oscuro por debajo de los botones (los botones se ven encima) y el editor por encima
	dim = UI.new("ScreenGui", { Name = "HUDEditorDim", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 2, Parent = playerGui })
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = dim })
	-- (la misma zona segura que los botones, CoreUISafeInsets: así lo que se arrastra cae justo donde
	-- queda el botón)
	gui = UI.new("ScreenGui", { Name = "HUDEditor", IgnoreGuiInset = false, ResetOnSpawn = false, DisplayOrder = 20, Parent = playerGui })
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	-- (toda la pantalla recoge los toques: ni la cámara ni los controles reciben nada)
	local catcher = UI.new("TextButton", {
		Name = "Catcher",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = gui,
	})
	local dragInput, dragOffset
	catcher.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local _, origin = areaOf()
		local point = Vector2.new(input.Position.X, input.Position.Y) - origin
		local id = pick(point)
		if id then
			HUDEditor.Select(id)
			local info = TouchLayout.GetLayout()[id]
			dragInput, dragOffset = input, info.Center - point
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragInput then
			return
		end
		if input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			local _, origin = areaOf()
			HUDEditor.MoveSelected(Vector2.new(input.Position.X, input.Position.Y) - origin + dragOffset)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input == dragInput then
			dragInput = nil
		end
	end))

	-- Panel arriba en el centro (ahí no hay controles), sin tapar los de arriba a la derecha
	local size = areaOf()
	local utilityLeft = size.X
	for id, info in TouchLayout.GetLayout() do
		local control = MobileHUD.ById[id]
		if control and control.Anchor == "TopRight" and not (working[id] and working[id].X) then
			utilityLeft = math.min(utilityLeft, info.Center.X - info.Size.X / 2)
		end
	end
	local width = math.clamp(2 * (utilityLeft - 8 - size.X / 2), 260, 440)
	local panel = UI.new("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(width, 130),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.08,
		Active = true,
		Parent = gui,
	}, { UI.corner(12), UI.stroke(Color3.fromRGB(90, 96, 112), 1, 0.2) })
	-- (el panel se puede pasar abajo para llegar a lo que tapa)
	local flip = UI.button({
		Name = "Flip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 5),
		Size = UDim2.fromOffset(64, 22),
		Text = "ABAJO",
		TextSize = 12,
		BackgroundColor3 = Color3.fromRGB(52, 56, 68),
		Parent = panel,
	})
	local atTop = true
	flip.Activated:Connect(function()
		atTop = not atTop
		panel.AnchorPoint = Vector2.new(0.5, atTop and 0 or 1)
		panel.Position = atTop and UDim2.new(0.5, 0, 0, 6) or UDim2.new(0.5, 0, 1, -6)
		flip.Text = atTop and "ABAJO" or "ARRIBA"
	end)
	local title = UI.label({
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -96, 0, 18),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = panel,
	})
	local half = (width - 36) / 2
	local showSize = slider(panel, UDim2.fromOffset(12, 30), half, "TAMAÑO", "S")
	local showOpacity = slider(panel, UDim2.fromOffset(24 + half, 30), half, "OPACIDAD", "O")
	local function action(order, text, color, textColor, callback)
		local w = (width - 24 - 16) / 3
		local button = UI.button({
			Name = text,
			Position = UDim2.fromOffset(12 + (order - 1) * (w + 8), 72),
			Size = UDim2.fromOffset(w, 32),
			Text = text,
			TextSize = 14,
			TextScaled = true,
			TextColor3 = textColor,
			BackgroundColor3 = color,
			Parent = panel,
		}, { UI.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 10 }), UI.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }) })
		button.Activated:Connect(callback)
		return button
	end
	action(1, "RESTABLECER", Color3.fromRGB(52, 56, 68), Color3.new(1, 1, 1), HUDEditor.Reset)
	action(2, "CANCELAR", Color3.fromRGB(52, 56, 68), Color3.new(1, 1, 1), HUDEditor.Cancel)
	saveButton = action(3, "GUARDAR", YELLOW, Color3.fromRGB(20, 20, 24), HUDEditor.Save)
	status = UI.label({
		Name = "Status",
		Position = UDim2.fromOffset(12, 108),
		Size = UDim2.new(1, -24, 0, 16),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Parent = panel,
	})
	refreshPanel = function()
		local control = MobileHUD.ById[selected]
		title.Text = (control and control.Name or selected) .. "  ·  arrastra para mover"
		showSize()
		showOpacity()
		showStatus()
	end
	refreshPanel()
end

-- Abre el editor. `closed`: se llama al cerrarlo (por ejemplo, para volver a Ajustes).
function HUDEditor.Open(closed: (() -> ())?): boolean
	if gui or not UserInputService.TouchEnabled then
		return false
	end
	onClosed = closed
	working = copy(Settings.Get().HudLayout)
	selected = "Fire"
	ClientState.HUDEditorOpen = true
	ClientState.UpdateMouse()
	previousRelayout = TouchLayout.OnRelayout
	TouchLayout.OnRelayout = function(layout, size)
		if previousRelayout then
			previousRelayout(layout, size)
		end
		drawOverlay(layout)
		showStatus()
	end
	build()
	apply()
	-- Si cambia el contexto (vuelta al lobby, fin de partida, muerte) se cancela solo: el editor no
	-- puede quedarse abierto debajo de otra pantalla dejando el juego bloqueado
	local openedInMenu = ClientState.InMainMenu
	local openedDead = ClientState.Dead
	local openedResults = ClientState.ResultsActive
	local acc = 0
	table.insert(connections, game:GetService("RunService").Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		if ClientState.InMainMenu ~= openedInMenu or (ClientState.ResultsActive and not openedResults) or (ClientState.Dead and not openedDead) then
			close(false, true)
		end
	end))
	return true
end

return HUDEditor
