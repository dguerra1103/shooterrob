-- Interfaz en partida: marcador, mira, munición, vida, racha, killfeed, avisos y pantallas de ronda.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)
local WeaponController = require(script.Parent.WeaponController)

local player = Players.LocalPlayer

local HUD = {}

local gui
local refs = {}
local thumbnails = {}

local function tween(inst, time, props, style)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad), props)
	t:Play()
	return t
end

local function disableCoreGui()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end

---------------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------------

local function buildTopBar()
	local top = UI.new("Frame", {
		Name = "TopBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(330, 44),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local function scoreBox(x, name)
		local box = UI.new("Frame", {
			Name = name,
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(90, 44),
			BackgroundColor3 = Color3.fromRGB(80, 80, 80),
			Parent = top,
		}, { UI.corner(8), UI.stroke(Color3.new(0, 0, 0), 2, 0.3) })
		return UI.label({
			Size = UDim2.fromScale(1, 1),
			Text = "0",
			TextSize = 30,
			Parent = box,
		})
	end
	refs.ScoreA = scoreBox(0, "TeamA")
	refs.ScoreB = scoreBox(240, "TeamB")
	refs.ScoreABox = refs.ScoreA.Parent
	refs.ScoreBBox = refs.ScoreB.Parent

	local timerBox = UI.new("Frame", {
		Position = UDim2.fromOffset(95, 0),
		Size = UDim2.fromOffset(140, 44),
		BackgroundColor3 = Color3.fromRGB(25, 30, 60),
		Parent = top,
	}, { UI.corner(8), UI.stroke(Color3.new(0, 0, 0), 2, 0.3) })
	refs.Timer = UI.label({ Size = UDim2.fromScale(1, 1), Text = "00:00", TextSize = 30, Parent = timerBox })

	refs.Mode = UI.label({
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		TextSize = 16,
		Parent = top,
	})

	refs.PlayerRow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(500, 54),
		BackgroundTransparency = 1,
		Parent = top,
	}, {
		UI.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function buildCrosshair()
	local holder = UI.new("Frame", {
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.Crosshair = holder
	refs.CrossLines = {}
	for i, dir in { Vector2.new(0, -1), Vector2.new(0, 1), Vector2.new(-1, 0), Vector2.new(1, 0) } do
		local vertical = dir.X == 0
		refs.CrossLines[i] = {
			Dir = dir,
			Frame = UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = vertical and UDim2.fromOffset(2, 9) or UDim2.fromOffset(9, 2),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = holder,
			}, { UI.stroke(Color3.new(0, 0, 0), 1, 0.4) }),
		}
	end
	refs.CrossDot = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = holder,
	}, { UI.corner(2) })

	-- Hitmarker (4 líneas diagonales)
	refs.Hitmarker = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(34, 34),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	refs.HitLines = {}
	for i, pos in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) } do
		refs.HitLines[i] = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, pos.X * 10, 0.5, pos.Y * 10),
			Size = UDim2.fromOffset(10, 3),
			Rotation = pos.X * pos.Y * 45,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = refs.Hitmarker,
		})
	end

	-- Mira telescópica (círculo con borde negro enorme)
	refs.Scope = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 0,
		Parent = gui,
	}, {
		UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }),
		UI.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		UI.new("UIStroke", { Thickness = 3000, Color = Color3.new(0, 0, 0) }),
		-- Bandas negras a los lados (por si el borde no cubre toda la pantalla)
		UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(0, 4000, 3, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		}),
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0, 4000, 3, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		}),
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		}),
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		}),
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(5, 5),
			BackgroundColor3 = Color3.fromRGB(255, 40, 40),
			BorderSizePixel = 0,
		}, { UI.corner(3) }),
	})
end

local function buildWeaponPanel()
	-- Munición (abajo a la derecha)
	local panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -20),
		Size = UDim2.fromOffset(260, 90),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.WeaponName = UI.label({
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	refs.Ammo = UI.label({
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 50),
		Text = "",
		TextSize = 46,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	refs.ReloadHint = UI.label({
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 210, 80),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})

	-- Ranuras de armas (derecha)
	local slots = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.62, 0),
		Size = UDim2.fromOffset(200, 150),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	refs.Slots = {}
	for slot = 1, 3 do
		local row = UI.new("Frame", {
			LayoutOrder = slot,
			Size = UDim2.fromOffset(200, 40),
			BackgroundTransparency = 1,
			Parent = slots,
		})
		local name = UI.label({
			Size = UDim2.new(1, -40, 1, 0),
			Text = "",
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		local key = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = Color3.fromRGB(20, 20, 25),
			Parent = row,
		}, { UI.corner(6) })
		UI.label({ Size = UDim2.fromScale(1, 1), Text = tostring(slot), TextSize = 18, Parent = key })
		refs.Slots[slot] = { Name = name, Key = key, Row = row }
	end

	-- Controles (estilo de la captura)
	if not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled then
		local hints = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20, 0.22, 0),
			Size = UDim2.fromOffset(220, 150),
			BackgroundTransparency = 1,
			Parent = gui,
		}, {
			UI.new("UIListLayout", {
				Padding = UDim.new(0, 4),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		for i, pair in {
			{ "Pase de batalla", "B" },
			{ "Deslizar", "C" },
			{ "Cuchillo rápido", "F" },
			{ "Recargar", "R" },
			{ "Correr", "Shift" },
		} do
			local row = UI.new("Frame", {
				LayoutOrder = i,
				Size = UDim2.fromOffset(220, 24),
				BackgroundTransparency = 1,
				Parent = hints,
			})
			UI.label({
				Size = UDim2.new(1, -56, 1, 0),
				Text = pair[1],
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
			local key = UI.new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(50, 22),
				BackgroundColor3 = Color3.fromRGB(20, 20, 25),
				Parent = row,
			}, { UI.corner(5) })
			UI.label({ Size = UDim2.fromScale(1, 1), Text = pair[2], TextSize = 14, Parent = key })
		end
	end
end

local function buildPlayerPanel()
	-- Vida (abajo a la izquierda)
	local health = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -24),
		Size = UDim2.fromOffset(240, 22),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		Parent = gui,
	}, { UI.corner(11), UI.stroke(Color3.new(0, 0, 0), 2, 0.2) })
	refs.HealthFill = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(70, 220, 90),
		Parent = health,
	}, { UI.corner(11) })
	refs.HealthText = UI.label({ Size = UDim2.fromScale(1, 1), Text = "100", TextSize = 16, Parent = health })

	-- Racha (barra vertical a la izquierda, como en la captura)
	local streakBar = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 40, 0.55, 0),
		Size = UDim2.fromOffset(10, 240),
		BackgroundColor3 = Color3.fromRGB(30, 30, 35),
		Parent = gui,
	}, { UI.corner(5), UI.stroke(Color3.new(0, 0, 0), 2, 0.3) })
	refs.StreakFill = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 180, 30),
		Parent = streakBar,
	}, { UI.corner(5) })
	refs.StreakText = UI.label({
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 14, 0.55, 126),
		Size = UDim2.fromOffset(120, 22),
		Text = "Racha x0",
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 210, 80),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = gui,
	})

	-- Nivel / XP (abajo al centro)
	local level = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(320, 10),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		Parent = gui,
	}, { UI.corner(5) })
	refs.XPFill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(80, 170, 255),
		Parent = level,
	}, { UI.corner(5) })
	refs.LevelText = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -2),
		Size = UDim2.fromOffset(320, 18),
		Text = "Nivel 1",
		TextSize = 15,
		Parent = level,
	})
end

local function buildFeedsAndOverlays()
	refs.KillFeed = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 60),
		Size = UDim2.fromOffset(380, 220),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 4),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	refs.Popups = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.58, 0),
		Size = UDim2.fromOffset(400, 140),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 2),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	refs.BigText = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(800, 70),
		Text = "",
		TextSize = 54,
		TextStrokeTransparency = 0,
		Visible = false,
		Parent = gui,
	})

	refs.Banner = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 135),
		Size = UDim2.fromOffset(600, 30),
		Text = "",
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 200, 60),
		Visible = false,
		Parent = gui,
	})

	refs.Toast = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -50),
		Size = UDim2.fromOffset(600, 30),
		Text = "",
		TextSize = 22,
		Visible = false,
		Parent = gui,
	})

	-- Viñeta roja de daño
	refs.Damage = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -120, 1, -120),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Parent = gui,
	}, { UI.new("UICorner", { CornerRadius = UDim.new(0, 60) }) })
	refs.DamageStroke = UI.new("UIStroke", {
		Thickness = 90,
		Color = Color3.fromRGB(200, 0, 0),
		Transparency = 1,
		Parent = refs.Damage,
	})

	-- Pantalla de muerte
	refs.DeathScreen = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		Visible = false,
		Parent = gui,
	})
	refs.DeathText = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(800, 60),
		Text = "",
		TextSize = 40,
		TextColor3 = Color3.fromRGB(255, 80, 80),
		RichText = true,
		Parent = refs.DeathScreen,
	})
	UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(600, 30),
		Text = "Reapareciendo...",
		TextSize = 22,
		Parent = refs.DeathScreen,
	})

	-- Fin de ronda
	refs.RoundEnd = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(560, 220),
		BackgroundColor3 = Color3.fromRGB(20, 22, 35),
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = gui,
	}, { UI.corner(16), UI.stroke(Color3.new(1, 1, 1), 3, 0.6) })
	refs.RoundTitle = UI.label({
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 56),
		Text = "",
		TextSize = 44,
		Parent = refs.RoundEnd,
	})
	refs.RoundScore = UI.label({
		Position = UDim2.fromOffset(0, 86),
		Size = UDim2.new(1, 0, 0, 50),
		Text = "",
		TextSize = 40,
		RichText = true,
		Parent = refs.RoundEnd,
	})
	refs.RoundMVP = UI.label({
		Position = UDim2.fromOffset(0, 150),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 210, 80),
		Parent = refs.RoundEnd,
	})
end

---------------------------------------------------------------------------
-- Mensajes
---------------------------------------------------------------------------

local function popup(text, color)
	local label = UI.label({
		Size = UDim2.fromOffset(400, 26),
		Text = text,
		TextSize = 22,
		TextColor3 = color or Color3.fromRGB(255, 230, 120),
		LayoutOrder = math.floor(os.clock() * 100) % 100000,
		Parent = refs.Popups,
	})
	task.delay(1.4, function()
		tween(label, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 })
	end)
	Debris:AddItem(label, 2)
end

local bigToken
local function bigMessage(text, color)
	local label = refs.BigText
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0
	label.Size = UDim2.fromOffset(800, 70)
	label.TextSize = 70
	label.Visible = true
	tween(label, 0.25, { TextSize = 54 }, Enum.EasingStyle.Back)
	local token = {}
	bigToken = token
	task.delay(2.5, function()
		if bigToken == token then
			tween(label, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
	end)
end

local function timedLabel(label, text, duration)
	label.Text = text
	label.Visible = true
	local token = {}
	label:SetAttribute("Token", tostring(token))
	task.delay(duration, function()
		if label:GetAttribute("Token") == tostring(token) then
			label.Visible = false
		end
	end)
end

local function onNotify(kind, text)
	if kind == "XP" then
		popup(text)
	elseif kind == "Big" then
		bigMessage(text)
	elseif kind == "Streak" then
		timedLabel(refs.Banner, "🔥 " .. text, 3)
	else
		timedLabel(refs.Toast, text, 3)
		Sounds.Play("Click")
	end
end

local function onKillFeed(info)
	if type(info) ~= "table" then
		return
	end
	local killer = info.Killer
	local text
	local weapon = info.Weapon ~= "" and (" [" .. info.Weapon .. "] ") or " ✖ "
	if info.Headshot then
		weapon ..= "🎯 "
	end
	local victim = string.format('<font color="%s">%s</font>', UI.hex(info.VictimColor), info.Victim or "?")
	if killer then
		text = string.format('<font color="%s">%s</font>%s%s', UI.hex(info.KillerColor), killer, weapon, victim)
	else
		text = victim .. " se eliminó"
	end
	local entry = UI.new("Frame", {
		Size = UDim2.fromOffset(380, 26),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		LayoutOrder = math.floor(os.clock() * 100) % 1000000,
		Parent = refs.KillFeed,
	}, { UI.corner(6) })
	if killer == player.Name or info.Victim == player.Name then
		UI.stroke(Color3.fromRGB(255, 210, 80), 2, 0.2).Parent = entry
	end
	UI.label({
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		Text = text,
		RichText = true,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = entry,
	})
	local entries = {}
	for _, child in refs.KillFeed:GetChildren() do
		if child:IsA("Frame") then
			table.insert(entries, child)
		end
	end
	if #entries > 6 then
		table.sort(entries, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		entries[1]:Destroy()
	end
	Debris:AddItem(entry, 7)
end

local hitToken
local function onHitConfirm(damage, headshot, killed)
	local color = Color3.new(1, 1, 1)
	if killed then
		color = Color3.fromRGB(255, 40, 40)
	elseif headshot then
		color = Color3.fromRGB(255, 210, 40)
	end
	for _, line in refs.HitLines do
		line.BackgroundColor3 = color
		line.Size = killed and UDim2.fromOffset(14, 4) or UDim2.fromOffset(10, 3)
	end
	refs.Hitmarker.Visible = true
	local token = {}
	hitToken = token
	task.delay(killed and 0.35 or 0.15, function()
		if hitToken == token then
			refs.Hitmarker.Visible = false
		end
	end)
	Sounds.Play(killed and "Kill" or (headshot and "Headshot" or "Hit"))

	-- Número de daño
	if type(damage) == "number" then
		local label = UI.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.random(30, 60), 0.5, math.random(-40, -20)),
			Size = UDim2.fromOffset(80, 30),
			Text = tostring(damage),
			TextSize = headshot and 28 or 22,
			TextColor3 = color,
			Parent = gui,
		})
		tween(label, 0.6, {
			Position = label.Position + UDim2.fromOffset(0, -30),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		Debris:AddItem(label, 0.7)
	end
end

local function onRoundEnd(info)
	if type(info) ~= "table" then
		return
	end
	local teamA = ReplicatedStorage:GetAttribute("TeamA") or "Rojo"
	local teamB = ReplicatedStorage:GetAttribute("TeamB") or "Azul"
	if info.Winner then
		local won = player.Team and player.Team.Name == info.Winner
		refs.RoundTitle.Text = won and "¡VICTORIA!" or "DERROTA"
		refs.RoundTitle.TextColor3 = won and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(255, 80, 80)
	else
		refs.RoundTitle.Text = "EMPATE"
		refs.RoundTitle.TextColor3 = Color3.new(1, 1, 1)
	end
	local colorA = refs.ScoreABox.BackgroundColor3
	local colorB = refs.ScoreBBox.BackgroundColor3
	refs.RoundScore.Text = string.format(
		'<font color="%s">%s %d</font>  -  <font color="%s">%d %s</font>',
		UI.hex(colorA),
		teamA,
		info.ScoreA or 0,
		UI.hex(colorB),
		info.ScoreB or 0,
		teamB
	)
	refs.RoundMVP.Text = info.MVP and ("⭐ MVP: " .. info.MVP .. " (" .. info.MVPKills .. " bajas)") or ""
	refs.RoundEnd.Visible = true
	task.delay(7, function()
		refs.RoundEnd.Visible = false
	end)
end

---------------------------------------------------------------------------
-- Actualización
---------------------------------------------------------------------------

local function getThumbnail(userId)
	if thumbnails[userId] ~= nil then
		return thumbnails[userId]
	end
	thumbnails[userId] = ""
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		thumbnails[userId] = ok and image or ""
	end)
	return ""
end

local function updatePlayerRow()
	local list = Players:GetPlayers()
	local function kills(p)
		local stats = p:FindFirstChild("leaderstats")
		local value = stats and stats:FindFirstChild("Bajas")
		return value and value.Value or 0
	end
	table.sort(list, function(a, b)
		return kills(a) > kills(b)
	end)
	for _, child in refs.PlayerRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for rank = 1, math.min(10, #list) do
		local p = list[rank]
		local teamColor = p.Team and p.TeamColor.Color or Color3.new(1, 1, 1)
		local card = UI.new("Frame", {
			LayoutOrder = rank,
			Size = UDim2.fromOffset(40, 54),
			BackgroundTransparency = 1,
			Parent = refs.PlayerRow,
		})
		UI.new("ImageLabel", {
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = Color3.fromRGB(40, 40, 45),
			Image = getThumbnail(p.UserId),
			Parent = card,
		}, { UI.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), UI.stroke(teamColor, 3, 0) })
		UI.label({
			Position = UDim2.fromOffset(-6, -6),
			Size = UDim2.fromOffset(24, 14),
			Text = "#" .. rank,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		UI.label({
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.fromOffset(40, 16),
			Text = tostring(kills(p)),
			TextSize = 15,
			TextColor3 = p == player and Color3.fromRGB(255, 210, 60) or Color3.new(1, 1, 1),
			Parent = card,
		})
	end
end

local function updateScoreboard()
	local teamA = ReplicatedStorage:GetAttribute("TeamA")
	local teamB = ReplicatedStorage:GetAttribute("TeamB")
	if teamA then
		refs.ScoreA.Text = tostring(ReplicatedStorage:GetAttribute("Score_" .. teamA) or 0)
		local team = game:GetService("Teams"):FindFirstChild(teamA)
		if team then
			refs.ScoreABox.BackgroundColor3 = team.TeamColor.Color
		end
	end
	if teamB then
		refs.ScoreB.Text = tostring(ReplicatedStorage:GetAttribute("Score_" .. teamB) or 0)
		local team = game:GetService("Teams"):FindFirstChild(teamB)
		if team then
			refs.ScoreBBox.BackgroundColor3 = team.TeamColor.Color
		end
	end
	local state = ReplicatedStorage:GetAttribute("State")
	local timeLeft = ReplicatedStorage:GetAttribute("TimeLeft") or 0
	refs.Timer.Text = UI.formatTime(timeLeft)
	if state == "Intermission" then
		refs.Mode.Text = "Calentamiento · la partida empieza en " .. timeLeft
	elseif state == "Ended" then
		refs.Mode.Text = "Fin de la ronda"
	else
		refs.Mode.Text = "Duelo por equipos · Primero a " .. tostring(ReplicatedStorage:GetAttribute("ScoreToWin") or "?")
	end
end

local function updateData(data)
	if not data then
		return
	end
	local per = data.XPPerLevel or 1000
	refs.LevelText.Text = "Nivel " .. data.Level .. "  ·  " .. data.XP .. "/" .. per .. " XP"
	tween(refs.XPFill, 0.3, { Size = UDim2.fromScale(math.clamp(data.XP / per, 0, 1), 1) })
end

local lastHealth = 100
local function render()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- Vida
	if humanoid then
		local health = math.max(0, humanoid.Health)
		local ratio = health / math.max(humanoid.MaxHealth, 1)
		refs.HealthFill.Size = UDim2.fromScale(ratio, 1)
		refs.HealthFill.BackgroundColor3 = Color3.fromRGB(230, 60, 60):Lerp(Color3.fromRGB(70, 220, 90), ratio)
		refs.HealthText.Text = tostring(math.ceil(health))
		if health < lastHealth - 0.5 then
			refs.DamageStroke.Transparency = 0.35
			tween(refs.DamageStroke, 0.6, { Transparency = ratio < 0.35 and 0.75 or 1 })
		end
		lastHealth = health
	end

	-- Racha
	local streak = player:GetAttribute("Streak") or 0
	refs.StreakText.Text = "Racha x" .. streak
	refs.StreakFill.Size = UDim2.fromScale(1, math.clamp(streak / 10, 0, 1))

	-- Arma
	local def = ClientState.CurrentDef
	local tool = ClientState.CurrentTool
	if def and tool then
		refs.WeaponName.Text = def.DisplayName
		if def.Type == "Gun" then
			local reserve = tool:GetAttribute("Reserve") or 0
			local ammoColor = ClientState.Ammo <= math.ceil(def.MagSize * 0.25) and "#FF5050" or "#FFFFFF"
			refs.Ammo.Text = string.format(
				'<font color="%s">%d</font><font size="28" color="#C8C8C8"> | %d</font>',
				ammoColor,
				ClientState.Ammo,
				reserve
			)
			if ClientState.Reloading then
				refs.ReloadHint.Text = "RECARGANDO " .. math.floor(ClientState.ReloadProgress * 100) .. "%"
			elseif ClientState.Ammo == 0 and reserve == 0 then
				refs.ReloadHint.Text = "SIN MUNICIÓN"
			elseif ClientState.Ammo <= math.ceil(def.MagSize * 0.25) then
				refs.ReloadHint.Text = "[R] Recargar"
			else
				refs.ReloadHint.Text = ""
			end
		else
			refs.Ammo.Text = "∞"
			refs.ReloadHint.Text = ""
		end
	else
		refs.WeaponName.Text = ""
		refs.Ammo.Text = ""
		refs.ReloadHint.Text = ""
	end

	-- Ranuras
	local tools = WeaponController.GetTools()
	for slot, row in refs.Slots do
		local slotTool = tools[slot]
		local slotDef = slotTool and Weapons.Get(slotTool:GetAttribute("Weapon"))
		row.Name.Text = slotDef and slotDef.DisplayName or ""
		local active = slotTool ~= nil and slotTool == tool
		row.Name.TextColor3 = active and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(220, 220, 220)
		row.Key.BackgroundColor3 = active and Color3.fromRGB(255, 170, 30) or Color3.fromRGB(20, 20, 25)
	end

	-- Mira
	local aim = ClientState.AimAlpha
	local isGun = def and def.Type == "Gun"
	local gap = 6 + ClientState.Spread * 6
	for _, line in refs.CrossLines do
		line.Frame.Position = UDim2.fromOffset(line.Dir.X * (gap + 4), line.Dir.Y * (gap + 4))
		line.Frame.Visible = isGun and aim < 0.5
	end
	refs.CrossDot.Visible = aim < 0.5
	refs.Crosshair.Visible = not ClientState.MenuOpen
	refs.Scope.Visible = def ~= nil and def.Scope == true and aim > 0.85
end

---------------------------------------------------------------------------

function HUD.Init()
	task.spawn(disableCoreGui)

	gui = UI.new("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	buildTopBar()
	buildCrosshair()
	buildWeaponPanel()
	buildPlayerPanel()
	buildFeedsAndOverlays()

	Remotes.Notify.OnClientEvent:Connect(onNotify)
	Remotes.KillFeed.OnClientEvent:Connect(onKillFeed)
	Remotes.HitConfirm.OnClientEvent:Connect(onHitConfirm)
	Remotes.RoundEnd.OnClientEvent:Connect(onRoundEnd)
	Remotes.Died.OnClientEvent:Connect(function(killerName, weaponName)
		local weapon = weaponName and Weapons.Get(weaponName)
		if killerName then
			refs.DeathText.Text = "ELIMINADO POR <b>"
				.. killerName
				.. "</b>"
				.. (weapon and (" · " .. weapon.DisplayName) or "")
		else
			refs.DeathText.Text = "HAS MUERTO"
		end
		refs.DeathScreen.Visible = true
	end)
	player.CharacterAdded:Connect(function()
		refs.DeathScreen.Visible = false
		lastHealth = 100
		refs.DamageStroke.Transparency = 1
	end)

	ClientState.DataChanged.Event:Connect(updateData)
	updateData(ClientState.Data)

	ReplicatedStorage.AttributeChanged:Connect(updateScoreboard)
	updateScoreboard()

	task.spawn(function()
		while true do
			updatePlayerRow()
			task.wait(1)
		end
	end)

	RunService.RenderStepped:Connect(render)
end

return HUD
