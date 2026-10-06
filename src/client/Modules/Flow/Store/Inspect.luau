-- PREVISUALIZAR: el objeto en grande antes de comprarlo. Armas: el modelo de verdad con la skin,
-- se gira arrastrando, zoom con la rueda, pellizcando o con + / −, y se puede ver en cualquiera de
-- tus armas. Trajes y poses: tu personaje completo. Intros de MVP: se repiten en bucle. Efectos de
-- baja: botón PROBAR que lo lanza delante de ti. Tarjetas, grafitis y títulos: en grande.
-- Siempre se dice que es solo estética.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local WeaponModels = require(Shared.WeaponModels)
local Outfits = require(Shared.Outfits)
local Titles = require(Shared.Titles)
local Catalog = require(Shared.Economy.CosmeticCatalog)

local Flow = script.Parent.Parent
local Modules = Flow.Parent
local ClientState = require(Modules.ClientState)
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Preview = require(Flow.Preview)
local PoseRig = require(Flow.Results.PoseRig)
local ItemArt = require(script.Parent.ItemArt)
local ItemCard = require(script.Parent.ItemCard)
local StoreData = require(script.Parent.StoreData)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)
local player = Players.LocalPlayer

local Inspect = {}

local overlay, current, connections = nil, nil, {}
local orbit -- { Camera, Center, Yaw, Pitch, Dist, Min, Max }

local function disconnectAll()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function updateCamera()
	if not orbit then
		return
	end
	local offset = CFrame.Angles(0, orbit.Yaw, 0) * CFrame.Angles(orbit.Pitch, 0, 0) * Vector3.new(0, 0, -orbit.Dist)
	orbit.Camera.CFrame = CFrame.lookAt(orbit.Center + offset, orbit.Center)
end

function Inspect.Zoom(factor)
	if orbit then
		orbit.Dist = math.clamp(orbit.Dist * factor, orbit.Min, orbit.Max)
		updateCamera()
	end
end

function Inspect.Turn(dx, dy)
	if orbit then
		orbit.Yaw += dx
		orbit.Pitch = math.clamp(orbit.Pitch + (dy or 0), -0.9, 0.9)
		updateCamera()
	end
end

-- Cámara que gira alrededor del modelo
local function setupOrbit(camera, model, distanceScale)
	local ok, cf, size = pcall(model.GetBoundingBox, model)
	local center = ok and cf.Position or Vector3.new(0, 3, 0)
	local extent = ok and math.max(size.X, size.Y, size.Z) or 5
	local dist = extent * (distanceScale or 1.9)
	orbit = { Camera = camera, Center = center, Yaw = math.rad(-35), Pitch = math.rad(-8), Dist = dist, Min = dist * 0.45, Max = dist * 1.6 }
	camera.FieldOfView = 34
	updateCamera()
end

-- Tu personaje (o un maniquí si aún no hay personaje) con un traje
local function characterIn(preview, outfitId)
	local model = preview:SetCharacter("me", player)
	if not model then
		model = ItemArt.Mannequin(outfitId)
		model.Parent = preview.World
		return model, false
	end
	pcall(Outfits.Remove, model)
	if outfitId and outfitId ~= "Default" then
		pcall(Outfits.Apply, model, outfitId)
	end
	return model, true
end

local function primaryWeapon()
	local data = ClientState.Data
	return data and data.Primary or "ARX27"
end

---------------------------------------------------------------------------
-- Escena según el tipo
---------------------------------------------------------------------------

local weaponIndex = 1
local function ownedPrimaries()
	local list = {}
	local data = ClientState.Data
	for _, name in Weapons.Primaries do
		if Weapons.IsUnlocked(name, data) and not Weapons.Get(name).Hidden then
			table.insert(list, name)
		end
	end
	if #list == 0 then
		list = { "ARX27" }
	end
	return list
end

local function buildScene(area, item, refs, opts)
	local kind = item.Kind
	local data = ClientState.Data
	if kind == "Skin" or kind == "Charm" then
		local vp, camera = ItemArt.Viewport(area, { Name = "InspectViewport" })
		local list = ownedPrimaries()
		local function show(name)
			for _, child in vp:GetChildren() do
				if child:IsA("Model") then
					child:Destroy()
				end
			end
			local skin = kind == "Skin" and item.Id or (data and data.EquippedSkin) or nil
			local charm = kind == "Charm" and item.Id or (data and data.EquippedCharm ~= "Default" and data.EquippedCharm) or nil
			local ok, model = pcall(WeaponModels.Build, name, skin, false, charm, 1)
			if ok and model then
				model.Parent = vp
				setupOrbit(camera, model, kind == "Charm" and 1.1 or 1.55)
				if kind == "Charm" then
					orbit.Yaw = math.rad(-70)
					updateCamera()
				end
			end
			refs.WeaponName.Text = C.upper(Weapons.Get(name).DisplayName or name)
		end
		-- (se empieza en el arma pedida, p. ej. la de la oferta de después de la partida)
		local wanted = opts and opts.Weapon
		if wanted and Weapons.List[wanted] and not table.find(list, wanted) then
			table.insert(list, 1, wanted)
		end
		weaponIndex = math.max(1, table.find(list, wanted or primaryWeapon()) or 1)
		refs.ShowWeapon = function(step)
			weaponIndex = (weaponIndex - 1 + step) % #list + 1
			show(list[weaponIndex])
			Transition.Pop(vp, 0.94, 0.18)
		end
		refs.WeaponRow.Visible = #list > 1
		show(list[weaponIndex])
		-- Vuelta de inspección al abrir (la animación de inspección de la skin)
		task.spawn(function()
			local start = os.clock()
			local from = orbit and orbit.Yaw or 0
			while orbit and overlay and overlay.Visible and os.clock() - start < 0.8 do
				local a = (os.clock() - start) / 0.8
				orbit.Yaw = from + (1 - (1 - a) ^ 3) * math.pi * 2
				updateCamera()
				task.wait()
			end
		end)
		return vp
	elseif kind == "Outfit" or kind == "Pose" or kind == "MVPIntro" then
		local preview = Preview.new(area, { Name = "InspectViewport", Camera = "Hero" })
		refs.Preview = preview
		local outfit = kind == "Outfit" and item.Id or (data and data.EquippedOutfit) or "Default"
		local model, real = characterIn(preview, outfit)
		if real and data then
			preview:SetWeapon("me", data.Primary, data.EquippedSkin)
		end
		if kind == "Pose" then
			PoseRig.Apply(model, item.Id)
		end
		setupOrbit(preview.Camera, model, 1.25)
		orbit.Yaw = 0
		updateCamera()
		if kind == "MVPIntro" then
			task.spawn(function()
				while overlay and overlay.Visible and current == item and model.Parent do
					PoseRig.PlayIntro(preview.World, model, item.Id)
					task.wait(2.4)
				end
			end)
		end
		return preview.Viewport
	elseif kind == "Card" then
		return ItemArt.Card(area, item.Id, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 130) }, player.DisplayName, "NV. " .. tostring(data and data.Level or 1) .. "  ·  " .. C.upper(Titles.Get(data and data.EquippedTitle or "Novato").Name))
	elseif kind == "Spray" then
		return ItemArt.Spray(area, item.Id, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 300) })
	end
	return ItemArt.Thumb(area, item, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 260) })
end

-- Efecto de baja delante de la cámara (la tienda se aparta 2 s para verlo)
local previewing = false
local function tryKillEffect(effectId)
	if previewing then
		return
	end
	previewing = true
	local camera = workspace.CurrentCamera
	local position = camera.CFrame.Position + camera.CFrame.LookVector * 16
	local gui = overlay and overlay:FindFirstAncestorWhichIsA("ScreenGui")
	local blur = Lighting:FindFirstChild("FlowBlur")
	local blurSize = blur and blur.Size
	if gui then
		gui.Enabled = false
	end
	if blur then
		blur.Size = 0
	end
	pcall(function()
		require(Modules.Effects).KillEffect(effectId, position, Colors.Yellow)
	end)
	task.delay(2.2, function()
		previewing = false
		if gui and ClientState.InMainMenu then
			gui.Enabled = true
		end
		if blur and blur.Parent and ClientState.InMainMenu then
			blur.Size = blurSize
		end
	end)
end

---------------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------------

-- callbacks = { OnBuy(item), OnEquip(item) }; opts = { Weapon = arma con la que enseñar la skin }
function Inspect.Open(root, item, callbacks, opts)
	Inspect.Close()
	current = item
	StoreData.Track("item_preview", { item = item.Key })
	StoreData.MarkSeen({ item.Key })
	local phone = C.Breakpoint() == "PHONE"
	overlay = C.new("Frame", { Name = "Inspect", BackgroundColor3 = Colors.Bg, BackgroundTransparency = 0.08, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 20, Active = true, Parent = root })
	local refs: { [string]: any } = {}
	local area = C.new("Frame", { Name = "Stage", BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 64), Size = UDim2.new(phone and 0.56 or 0.6, -20, 1, -84), ZIndex = 21, Parent = overlay })
	-- Panel derecho
	local info = C.panel({ Name = "Info", Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 64), Size = UDim2.new(phone and 0.44 or 0.4, -30, 1, -84), Parent = overlay }, { Alpha = 0.1, StrokeColor = ItemArt.RarityColor(item.Rarity), StrokeAlpha = 0.5 })
	local inner = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = info }, { C.padding(phone and 10 or 16), C.list(phone and 4 or 8) })
	local rarityTag = C.new("Frame", { BackgroundColor3 = ItemArt.RarityColor(item.Rarity), BorderSizePixel = 0, Size = UDim2.fromOffset(140, 24), LayoutOrder = 1, Parent = inner }, { C.corner(3) })
	C.text({ Text = C.upper(item.Rarity), Role = "Title", TextSize = 14, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = rarityTag })
	C.text({ Name = "ItemName", Text = C.upper(item.Name), Role = "TitleItalic", TextSize = phone and 30 or 42, Scaled = true, Size = UDim2.new(1, 0, 0, phone and 34 or 48), Order = 2, Parent = inner })
	C.text({ Text = (item.Label or "") .. (item.Collection and ("  ·  COLECCIÓN " .. item.Collection) or ""), Role = "Title", TextSize = 14, Color = Colors.YellowText, Size = UDim2.new(1, 0, 0, 18), Order = 3, Parent = inner })
	if item.Description and not phone then
		C.text({ Text = item.Description, Role = "Body", TextSize = 14, Color = Colors.Text, Wrap = true, AlignY = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 40), Order = 4, Parent = inner })
	end
	C.text({ Text = "Solo estética: no cambia daño, retroceso, velocidad ni estadísticas.", Role = "Body", TextSize = phone and 11 or 13, Color = Colors.TextDim, Wrap = true, Size = UDim2.new(1, 0, 0, phone and 28 or 32), Order = 5, Parent = inner })
	-- Cambiar de arma (skins y colgantes)
	refs.WeaponRow = C.new("Frame", { Name = "WeaponRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Visible = false, LayoutOrder = 6, Parent = inner })
	C.button({ Name = "PrevWeapon", Text = "◀", Style = "Ghost", TextSize = 16, Size = UDim2.fromOffset(40, 36), Parent = refs.WeaponRow, OnClick = function()
		if refs.ShowWeapon then
			refs.ShowWeapon(-1)
		end
	end })
	refs.WeaponName = C.text({ Name = "WeaponName", Text = "", Role = "Title", TextSize = 16, AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -88, 1, 0), Parent = refs.WeaponRow })
	C.button({ Name = "NextWeapon", Text = "▶", Style = "Ghost", TextSize = 16, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(40, 36), Parent = refs.WeaponRow, OnClick = function()
		if refs.ShowWeapon then
			refs.ShowWeapon(1)
		end
	end })
	-- Probar efecto de baja
	if item.Kind == "KillEffect" then
		C.button({ Name = "TryEffect", Text = "PROBAR EFECTO", Icon = "💥", Style = "Ghost", TextSize = 16, Size = UDim2.new(1, 0, 0, 44), Order = 7, Parent = inner, OnClick = function()
			tryKillEffect(item.Id)
		end })
	end
	-- Precio y acción
	local price = C.text({ Name = "Price", Text = ItemCard.PriceText(item), Role = "Number", TextSize = 26, Color = item.Robux and Colors.Green or Colors.YellowText, Size = UDim2.new(1, 0, 0, 32), Order = 8, Parent = inner })
	local action = C.button({ Name = "Action", Text = "COMPRAR", Style = "Primary", TextSize = 22, Size = UDim2.new(1, 0, 0, phone and 46 or 54), Order = 9, Parent = inner, Sound = "Click", OnClick = function()
		local state = StoreData.State(item)
		if state == "Buy" then
			callbacks.OnBuy(item)
		elseif state == "Owned" then
			callbacks.OnEquip(item)
		end
	end })
	local actionLabel = action:FindFirstChild("Label", true)
	local function refresh()
		local state = StoreData.State(item)
		local yellow = state == "Buy" or (state == "Owned" and Catalog.Equippable(item.Kind, item.Id))
		local text = ({ Buy = "COMPRAR", Owned = "EQUIPAR", Equipped = "EQUIPADO ✓", Soon = "PRÓXIMAMENTE", Pass = "SE CONSIGUE EN EL PASE", Event = "SE CONSIGUE EN EL EVENTO", Locked = "NO DISPONIBLE" })[state]
		if StoreData.Pending and StoreData.Pending.Key == item.Key then
			text, yellow = "PROCESANDO…", false
		end
		actionLabel.Text = text
		action.BackgroundColor3 = yellow and Colors.Yellow or Colors.PanelLight
		actionLabel.TextColor3 = yellow and DARK or (state == "Equipped" and Colors.Green or Colors.TextDim)
		local gradient = action:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Enabled = yellow
		end
		price.Visible = state == "Buy" or state == "Soon"
	end
	refresh()
	table.insert(connections, ClientState.DataChanged.Event:Connect(refresh))
	table.insert(connections, StoreData.Changed.Event:Connect(refresh))
	-- Cabecera: título y cerrar
	C.text({ Text = "PREVISUALIZAR", Role = "TitleItalic", TextSize = phone and 26 or 34, Position = UDim2.fromOffset(20, 12), Size = UDim2.fromOffset(400, 40), Parent = overlay })
	C.button({ Name = "Close", Text = "CERRAR", Icon = "✕", Style = "Ghost", TextSize = 15, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 12), Size = UDim2.fromOffset(130, 40), Parent = overlay, Sound = "Back", OnClick = Inspect.Close })
	-- Escena
	local scene = buildScene(area, item, refs, opts)
	if scene and scene:IsA("ViewportFrame") and orbit then
		C.text({ Name = "Hint", Text = phone and "Arrastra para girar · pellizca para acercar" or "Arrastra para girar · rueda para acercar", Role = "Body", TextSize = 13, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, 0, 0, 18), Parent = area })
		local zoomIn = C.button({ Name = "ZoomIn", Text = "+", Style = "Ghost", TextSize = 22, Anchor = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -76), Size = UDim2.fromOffset(44, 44), Parent = area, OnClick = function()
			Inspect.Zoom(0.85)
		end })
		local zoomOut = C.button({ Name = "ZoomOut", Text = "−", Style = "Ghost", TextSize = 22, Anchor = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -26), Size = UDim2.fromOffset(44, 44), Parent = area, OnClick = function()
			Inspect.Zoom(1 / 0.85)
		end })
		local _ = zoomIn and zoomOut
		-- Girar arrastrando, zoom con rueda o pellizco
		local dragging, last = false, nil
		table.insert(connections, scene.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, last = true, input.Position
			end
		end))
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel and overlay then
				Inspect.Zoom(input.Position.Z > 0 and 0.9 or 1 / 0.9)
			elseif dragging and last and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - last
				last = input.Position
				Inspect.Turn(delta.X * 0.012, -delta.Y * 0.006)
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
		pcall(function()
			table.insert(connections, UserInputService.TouchPinch:Connect(function(_, scale, _, state)
				if overlay and state == Enum.UserInputState.Change and type(scale) == "number" and scale > 0 then
					Inspect.Zoom(math.clamp(1 / scale, 0.97, 1.03))
				end
			end))
		end)
	end
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
			UISound.Play("Back")
			Inspect.Close()
		end
	end))
	refs.Scene = scene
	Transition.Pop(area, 0.9, 0.25)
	Transition.SlideIn(info, Vector2.new(40, 0), 0.25)
	ClientState.StoreModal = true
	return overlay
end

function Inspect.IsOpen()
	return overlay ~= nil
end

function Inspect.Close()
	disconnectAll()
	orbit = nil
	current = nil
	if overlay then
		overlay:Destroy()
		overlay = nil
	end
	ClientState.StoreModal = false
end

return Inspect
