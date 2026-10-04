-- Pantalla de inicio: título del juego, cámara girando alrededor del mapa y botones.
-- Mientras está abierta el personaje no se mueve y es invulnerable (escudo del servidor).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local SocialService = game:GetService("SocialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)
local Ranks = require(Shared.Ranks)
local Weapons = require(Shared.Weapons)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)
local Menu = require(script.Parent.Menu)
local WeaponIcon = require(script.Parent.WeaponIcon)
local Wheel = require(script.Parent.Wheel)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MainMenu = {}

local gui, root, infoLabel, showcase, dailyButton, starterButton, wheelButton
local rankCard -- { Title, Fill, Next }: progreso hacia el siguiente rango
local blur
local titleScale
local orbitAngle = 0
local controls

local ORBIT_CENTER = Vector3.new(0, 8, 0)
local ORBIT_RADIUS = 150
local ORBIT_HEIGHT = 65

local function getControls()
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		return playerModule:GetControls()
	end)
	if ok then
		controls = result
	end
	return controls
end

local function orbit(dt)
	orbitAngle += dt * 0.06
	local position = ORBIT_CENTER + Vector3.new(math.cos(orbitAngle) * ORBIT_RADIUS, ORBIT_HEIGHT, math.sin(orbitAngle) * ORBIT_RADIUS)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(position, ORBIT_CENTER)
	camera.FieldOfView = 60
end

local function bigButton(text, color, order, parent)
	local button = UI.button({
		LayoutOrder = order,
		Size = UDim2.fromOffset(300, 58),
		Text = text,
		TextSize = 28,
		BackgroundColor3 = color,
		Parent = parent,
	}, { UI.stroke(Color3.new(0, 0, 0), 3, 0), UI.gloss() })
	button.TextStrokeTransparency = 0.5
	-- Textos largos ("RECOMPENSA DIARIA") se encogen para caber en el botón
	button.TextScaled = true
	UI.new("UITextSizeConstraint", { MaxTextSize = text and #text > 18 and 24 or 28, Parent = button })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = button })
	local scale = UI.new("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			return -- en móvil MouseLeave casi nunca llega y el botón se quedaría grande
		end
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	return button
end

local shownWeapon = nil

-- Armas que se pueden usar (sin las ocultas, como las garras de zombi)
local function weaponCount()
	local count = 0
	for _, def in Weapons.List do
		if not def.Hidden and (def.Type == "Gun" or def.Type == "Melee") then
			count += 1
		end
	end
	return count
end

local function refreshInfo()
	local data = ClientState.Data
	if dailyButton then
		dailyButton.Visible = data ~= nil and data.DailyAvailable == true
	end
	if wheelButton then
		wheelButton.Text = (data and data.WheelFree) and "🎡  RULETA ¡GRATIS!" or "🎡  RULETA"
	end
	if starterButton then
		starterButton.Visible = data ~= nil and data.StarterPackAvailable == true
	end
	if infoLabel then
		infoLabel.Text = data and string.format("Nivel %d   ·   🪙 %d   ·   %d bajas", data.Level, data.Coins, data.TotalKills or 0)
			or "Cargando..."
	end
	if rankCard and data then
		local points = data.RankPoints or 0
		local tier = Ranks.Get(points)
		local fraction, nextTier = Ranks.Progress(points)
		rankCard.Title.Text = string.format('%s <font color="%s"><b>%s</b></font>  ·  %d RP', tier.Icon, UI.hex(tier.Color), string.upper(tier.Name), points)
		rankCard.Fill.Size = UDim2.fromScale(fraction, 1)
		rankCard.Fill.BackgroundColor3 = tier.Color
		if nextTier then
			local reward = nextTier.Reward or {}
			local prize = (reward.Coins and ("+" .. reward.Coins .. " 🪙") or "") .. (reward.Crates and ("  +" .. reward.Crates .. " 📦") or "")
			rankCard.Next.Text = string.format("Faltan %d RP para %s %s   %s", nextTier.Min - points, nextTier.Icon, nextTier.Name, prize)
		else
			rankCard.Next.Text = "¡Rango máximo!"
		end
	end
	-- Arma principal con la skin equipada, a la derecha (solo se rehace si cambia)
	if showcase and data and ClientState.InMainMenu then
		local primary = data.Primary or "ARX27"
		local key = primary .. "/" .. tostring(Menu.SkinFor(data, primary))
		if key ~= shownWeapon then
			shownWeapon = key
			showcase:ClearAllChildren()
			WeaponIcon.Create(primary, Menu.SkinFor(data, primary), { Size = UDim2.fromScale(1, 1), Parent = showcase }, "angled", 1.6)
		end
	end
end

-- Clasificación global (la publica el servidor en atributos como JSON)
-- Escala un bloque de la pantalla de inicio según el tamaño de la pantalla (móviles)
local function fitToScreen(frame)
	local uiScale = UI.new("UIScale", { Parent = frame })
	local function rescale()
		local viewport = camera.ViewportSize
		uiScale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.45, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
end

local function buildLeaderboard(parent)
	local panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.fromOffset(330, 282),
		BackgroundColor3 = Color3.fromRGB(16, 18, 32),
		BackgroundTransparency = 0.2,
		Parent = parent,
	}, { UI.corner(14), UI.stroke(Color3.fromRGB(255, 200, 60), 2, 0.2) })
	-- Invitar amigos, justo debajo de la clasificación (cada amigo en el servidor da +10% de XP y
	-- monedas, ver Friends en el servidor)
	local invite = bigButton("👥  INVITAR AMIGOS  +10%", Color3.fromRGB(40, 170, 200), 0, panel)
	invite.Position = UDim2.new(0, 0, 1, 10)
	invite.Size = UDim2.new(1, 0, 0, 44)
	invite.TextSize = 22
	invite.Activated:Connect(function()
		Sounds.Play("Click")
		local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if ok and canInvite then
			pcall(SocialService.PromptGameInvite, SocialService, player)
		else
			invite.Text = "No puedes invitar desde aquí"
			task.delay(2, function()
				invite.Text = "👥  INVITAR AMIGOS  +10%"
			end)
		end
	end)
	fitToScreen(panel)
	UI.label({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 0, 30),
		Text = "🏆 TOP",
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 210, 60),
		Parent = panel,
	})
	local list = UI.new("Frame", {
		Position = UDim2.fromOffset(12, 44),
		Size = UDim2.new(1, -24, 1, -52),
		BackgroundTransparency = 1,
		Parent = panel,
	}, { UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local board = "Kills"
	local tabButtons = {}
	local function render()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for id, button in tabButtons do
			button.BackgroundColor3 = id == board and Color3.fromRGB(50, 130, 255) or Color3.fromRGB(45, 48, 70)
		end
		local raw = ReplicatedStorage:GetAttribute("Leaderboard_" .. board)
		local ok, rows = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if type(raw) ~= "string" or not ok or type(rows) ~= "table" or #rows == 0 then
			UI.label({ Size = UDim2.new(1, 0, 0, 60), Text = "Aún no hay datos.\n¡Sé el primero!", TextSize = 18, TextWrapped = true, Parent = list })
			return
		end
		local medals = { "🥇", "🥈", "🥉" }
		for i, row in rows do
			local me = row.UserId == player.UserId
			local line = UI.new("Frame", {
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 21),
				BackgroundColor3 = me and Color3.fromRGB(120, 90, 20) or Color3.fromRGB(30, 32, 50),
				BackgroundTransparency = me and 0.1 or 0.5,
				Parent = list,
			}, { UI.corner(6) })
			UI.label({
				Position = UDim2.fromOffset(6, 0),
				Size = UDim2.fromOffset(34, 21),
				Text = medals[i] or ("#" .. tostring(row.Rank or i)),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = line,
			})
			UI.label({
				Position = UDim2.fromOffset(42, 0),
				Size = UDim2.new(1, -120, 1, 0),
				Text = tostring(row.Name or "?"),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = me and Color3.fromRGB(255, 230, 120) or Color3.new(1, 1, 1),
				Parent = line,
			})
			UI.label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 0),
				Size = UDim2.fromOffset(80, 21),
				Text = board == "Rank" and (Ranks.Get(tonumber(row.Value) or 0).Icon .. " " .. tostring(row.Value or 0))
					or tostring(row.Value or 0),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Color3.fromRGB(255, 210, 60),
				Parent = line,
			})
		end
	end
	for i, info in { { "Kills", "Bajas" }, { "Wins", "Victorias" }, { "Rank", "Rango" } } do
		local button = UI.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12 - (3 - i) * 74, 0, 9),
			Size = UDim2.fromOffset(70, 26),
			Text = info[2],
			TextSize = 14,
			Parent = panel,
		})
		button.Activated:Connect(function()
			Sounds.Play("Click")
			board = info[1]
			render()
		end)
		tabButtons[info[1]] = button
	end
	render()
	ReplicatedStorage.AttributeChanged:Connect(function(name)
		if name == "Leaderboard_" .. board then
			render()
		end
	end)
end

-- Abre la pantalla de inicio: desenfoque, cámara girando, título que respira y controles bloqueados
local function openMenu()
	blur = blur or Instance.new("BlurEffect")
	blur.Name = "MainMenuBlur"
	blur.Size = 10
	blur.Parent = Lighting

	ClientState.InMainMenu = true
	UserInputService.MouseIconEnabled = true
	ClientState.UpdateMouse() -- oculta los botones táctiles del juego mientras está la pantalla de inicio
	RunService:BindToRenderStep("MainMenuOrbit", Enum.RenderPriority.Camera.Value + 2, orbit)

	-- El título "respira"
	task.spawn(function()
		while ClientState.InMainMenu do
			TweenService:Create(titleScale, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Scale = 1.04 }):Play()
			task.wait(1.2)
			TweenService:Create(titleScale, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
			task.wait(1.2)
		end
	end)

	-- Bloquea el movimiento del personaje mientras tanto
	task.spawn(function()
		local ctrl = getControls()
		if ctrl and ClientState.InMainMenu then
			ctrl:Disable()
		end
	end)
end

local function play()
	if not ClientState.InMainMenu then
		return
	end
	Sounds.Play("Click")
	Remotes.LeaveMenu:FireServer()
	TweenService:Create(root, TweenInfo.new(0.35), { GroupTransparency = 1 }):Play()
	showcase.Visible = false
	if blur then
		TweenService:Create(blur, TweenInfo.new(0.35), { Size = 0 }):Play()
	end
	task.delay(0.35, function()
		RunService:UnbindFromRenderStep("MainMenuOrbit")
		ClientState.InMainMenu = false
		gui.Enabled = false
		if blur then
			blur:Destroy()
			blur = nil
		end
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		-- (si ya estás en la pantalla de muerte, la cámara es suya: observando a un compañero)
		if humanoid and not ClientState.Dead then
			camera.CameraSubject = humanoid
		end
		local ctrl = getControls()
		if ctrl then
			ctrl:Enable()
		end
		ClientState.UpdateMouse()
	end)
end

-- "Volver al menú" (por ejemplo desde la pantalla de muerte)
function MainMenu.Show()
	if ClientState.InMainMenu or not gui then
		return
	end
	Remotes.EnterMenu:FireServer()
	gui.Enabled = true
	root.GroupTransparency = 0
	showcase.Visible = true
	openMenu()
	refreshInfo()
	ClientState.UpdateMouse()
end

function MainMenu.Init()
	gui = UI.new("ScreenGui", {
		Name = "MainMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 4,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	root = UI.new("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	-- Oscurecido a la izquierda para que se lea el texto
	UI.new("Frame", {
		Size = UDim2.fromScale(0.65, 1),
		BackgroundColor3 = Color3.fromRGB(10, 10, 25),
		BorderSizePixel = 0,
		Parent = root,
	}, {
		UI.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.6, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	-- Botón invisible "Modal": libera el ratón aunque la cámara sea en primera persona
	UI.new("TextButton", {
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Modal = true,
		Parent = root,
	})

	local left = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 40, 0.5, 0),
		Size = UDim2.fromOffset(560, 520),
		BackgroundTransparency = 1,
		Parent = root,
	})
	fitToScreen(left)

	-- Título con degradado y borde grueso
	local title = UI.label({
		Size = UDim2.new(1, 0, 0, 110),
		Text = GameConfig.GameTitle,
		TextSize = 96,
		TextScaled = true,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	}, {
		UI.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 170)),
			}),
			Rotation = 90,
		}),
		UI.new("UIStroke", { Thickness = 6, Color = Color3.fromRGB(30, 10, 40) }),
	})
	titleScale = UI.new("UIScale", { Parent = title })

	UI.label({
		Position = UDim2.fromOffset(4, 112),
		Size = UDim2.new(1, 0, 0, 30),
		Text = string.format("%d MAPAS  ·  %d MODOS  ·  %d ARMAS  ·  HABILIDADES", ReplicatedStorage:GetAttribute("MapCount") or 13, #GameConfig.Modes, weaponCount()),
		TextSize = 24,
		TextColor3 = Color3.fromRGB(200, 230, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	})
	-- Novedades (late para llamar la atención)
	local news = UI.label({
		Position = UDim2.fromOffset(4, 142),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "🎃 HALLOWEEN · 🧟 Modo Infección · 🚀 Base Lunar · 🎡 Ruleta · Guadaña",
		TextSize = 19,
		TextColor3 = Color3.fromRGB(255, 225, 90),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	})
	task.spawn(function()
		while news.Parent do
			TweenService:Create(news, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { TextTransparency = 0.35 }):Play()
			task.wait(0.9)
			TweenService:Create(news, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { TextTransparency = 0 }):Play()
			task.wait(0.9)
		end
	end)

	local buttons = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 182),
		Size = UDim2.fromOffset(300, 440),
		BackgroundTransparency = 1,
		Parent = left,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local playButton = bigButton("▶  JUGAR", Color3.fromRGB(60, 200, 90), 1, buttons)
	playButton.Size = UDim2.fromOffset(300, 70)
	playButton.TextSize = 36
	playButton.Activated:Connect(play)
	bigButton("⭐  PASE DE BATALLA", Color3.fromRGB(255, 130, 30), 2, buttons).Activated:Connect(function()
		Sounds.Play("Click")
		Menu.Open("Pase")
	end)
	bigButton("🔫  ARMAS Y TRAJES", Color3.fromRGB(50, 130, 255), 3, buttons).Activated:Connect(function()
		Sounds.Play("Click")
		Menu.Open("Armas")
	end)
	bigButton("🛒  TIENDA", Color3.fromRGB(190, 70, 255), 4, buttons).Activated:Connect(function()
		Sounds.Play("Click")
		Menu.Open("Tienda")
	end)

	-- Recompensa diaria (late mientras está disponible)
	dailyButton = bigButton("🎁  RECOMPENSA DIARIA", Color3.fromRGB(60, 200, 90), 5, buttons)
	dailyButton.Visible = false
	dailyButton.Activated:Connect(function()
		if Menu.ClaimDaily() then
			dailyButton.Visible = false
		end
	end)
	-- Pack de inicio para jugadores nuevos
	starterButton = bigButton("🔥  PACK DE INICIO", Color3.fromRGB(230, 70, 60), 6, buttons)
	starterButton.Visible = false
	starterButton.Activated:Connect(function()
		Sounds.Play("Click")
		Menu.Open("Tienda")
	end)
	-- Ruleta diaria (late mientras hay giro gratis)
	-- (debajo de la tarjeta de rango, para no alargar la columna de botones)
	wheelButton = bigButton("🎡  RULETA", Color3.fromRGB(255, 120, 40), 7, left)
	wheelButton.Position = UDim2.fromOffset(330, 298)
	wheelButton.Size = UDim2.fromOffset(230, 50)
	wheelButton.TextSize = 24
	wheelButton.Activated:Connect(function()
		Sounds.Play("Click")
		Wheel.Open()
	end)
		-- Los botones de regalo y oferta laten mientras están disponibles
	task.spawn(function()
		local scales = { dailyButton:FindFirstChildOfClass("UIScale"), starterButton:FindFirstChildOfClass("UIScale"), wheelButton:FindFirstChildOfClass("UIScale") }
		local buttonsList = { dailyButton, starterButton, wheelButton }
		-- (sigue vivo toda la sesión: al volver a la pantalla de inicio vuelven a latir)
		while gui.Parent do
			if not ClientState.InMainMenu then
				task.wait(0.5)
				continue
			end
			for i, button in buttonsList do
				-- (la ruleta solo late con giro gratis)
				local wheelReady = button ~= wheelButton or (ClientState.Data and ClientState.Data.WheelFree)
				if button.Visible and scales[i] and wheelReady then
					TweenService:Create(scales[i], TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Scale = 1.06 }):Play()
				end
			end
			task.wait(0.5)
			for i in buttonsList do
				if scales[i] then
					TweenService:Create(scales[i], TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
				end
			end
			task.wait(0.5)
		end
	end)

	infoLabel = UI.label({
		Position = UDim2.fromOffset(330, 175),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "Cargando...",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 220, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = left,
	})
	-- Rango competitivo: nombre, puntos y barra hasta el siguiente (con su premio)
	local card = UI.new("Frame", {
		Position = UDim2.fromOffset(330, 210),
		Size = UDim2.fromOffset(230, 78),
		BackgroundColor3 = Color3.fromRGB(16, 18, 32),
		BackgroundTransparency = 0.25,
		Parent = left,
	}, { UI.corner(12), UI.stroke(Color3.fromRGB(255, 255, 255), 1, 0.7) })
	local rankBar = UI.new("Frame", {
		Position = UDim2.fromOffset(10, 36),
		Size = UDim2.new(1, -20, 0, 10),
		BackgroundColor3 = Color3.fromRGB(40, 44, 70),
		Parent = card,
	}, { UI.corner(5) })
	rankCard = {
		Title = UI.label({
			Position = UDim2.fromOffset(10, 4),
			Size = UDim2.new(1, -20, 0, 28),
			Text = "",
			TextSize = 20,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		}),
		Fill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), Parent = rankBar }, { UI.corner(5) }),
		Next = UI.label({
			Position = UDim2.fromOffset(10, 50),
			Size = UDim2.new(1, -20, 0, 22),
			Text = "",
			TextSize = 14,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(200, 205, 225),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		}),
	}
	-- XP doble (GameConfig.XPBoost): aviso debajo de la ruleta mientras está activo
	local boostLabel = UI.label({
		Position = UDim2.fromOffset(330, 356),
		Size = UDim2.fromOffset(230, 26),
		Text = GameConfig.XPBoost and GameConfig.XPBoost.Text or "",
		TextSize = 16,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(120, 230, 255),
		Visible = false,
		Parent = left,
	})
	local function refreshBoost()
		boostLabel.Visible = (ReplicatedStorage:GetAttribute("XPBoost") or 1) > 1
	end
	ReplicatedStorage:GetAttributeChangedSignal("XPBoost"):Connect(refreshBoost)
	refreshBoost()

	-- Escaparate del arma a la derecha (fuera del CanvasGroup para que el 3D se dibuje siempre)
	showcase = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -30, 1, -20),
		Size = UDim2.fromOffset(440, 260),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	fitToScreen(showcase)

	buildLeaderboard(root)

	openMenu()

	ClientState.DataChanged.Event:Connect(refreshInfo)
	refreshInfo()

	-- También se puede empezar con Enter / botón A del mando
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not ClientState.InMainMenu or Menu.IsOpen() or ClientState.WheelOpen then
			return
		end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			play()
		end
	end)
end

return MainMenu
