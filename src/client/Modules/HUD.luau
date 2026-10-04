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
local GameConfig = require(Shared.GameConfig)
local Skins = require(Shared.Skins)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)
local Ranks = require(Shared.Ranks)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)
local WeaponController = require(script.Parent.WeaponController)
local WeaponIcon = require(script.Parent.WeaponIcon)
local Settings = require(script.Parent.Settings)

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
		}, { UI.corner(10), UI.stroke(Color3.new(0, 0, 0), 3, 0), UI.gloss() })
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

	-- Estado de las banderas (solo en Captura la bandera), a los lados del marcador
	refs.FlagA = UI.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(-8, 0),
		Size = UDim2.fromOffset(150, 44),
		Text = "",
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = top,
	})
	refs.FlagB = UI.label({
		Position = UDim2.fromOffset(338, 0),
		Size = UDim2.fromOffset(150, 44),
		Text = "",
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})

	local timerBox = UI.new("Frame", {
		Position = UDim2.fromOffset(95, 0),
		Size = UDim2.fromOffset(140, 44),
		BackgroundColor3 = Color3.fromRGB(35, 45, 95),
		Parent = top,
	}, { UI.corner(10), UI.stroke(Color3.new(0, 0, 0), 3, 0), UI.gloss(Color3.fromRGB(120, 120, 150)) })
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
		Size = UDim2.fromOffset(260, 104),
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
	-- Barra del cargador
	local ammoBar = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 76),
		Size = UDim2.fromOffset(170, 6),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.3,
		Parent = panel,
	}, { UI.corner(3) })
	refs.AmmoFill = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 210, 80),
		Parent = ammoBar,
	}, { UI.corner(3) })
	refs.AmmoBar = ammoBar
	refs.ReloadHint = UI.label({
		Position = UDim2.fromOffset(0, 85),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 210, 80),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})

	-- Ranuras de armas (derecha) con icono 3D del arma
	local slots = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.6, 0),
		Size = UDim2.fromOffset(230, 196),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.new("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	refs.Slots = {}
	for slot = 1, 3 do
		local row = UI.new("Frame", {
			LayoutOrder = slot,
			Size = UDim2.fromOffset(230, 60),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			Parent = slots,
		}, { UI.corner(10) })
		local stroke = UI.stroke(Color3.fromRGB(255, 200, 60), 2, 1)
		stroke.Parent = row
		local icon = UI.new("Frame", {
			Position = UDim2.fromOffset(6, 2),
			Size = UDim2.fromOffset(170, 44),
			BackgroundTransparency = 1,
			Parent = row,
		})
		local name = UI.label({
			Position = UDim2.fromOffset(10, 42),
			Size = UDim2.fromOffset(170, 16),
			Text = "",
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local key = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = Color3.fromRGB(20, 20, 25),
			Parent = row,
		}, { UI.corner(6), UI.stroke(Color3.new(0, 0, 0), 2, 0) })
		UI.label({ Size = UDim2.fromScale(1, 1), Text = tostring(slot), TextSize = 18, Parent = key })
		refs.Slots[slot] = { Name = name, Key = key, Row = row, Stroke = stroke, Icon = icon, IconKey = nil }
	end

	-- Controles (estilo de la captura)
	if not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled then
		-- (compacta para no pisar las ranuras de armas; solo para jugadores nuevos, ver updateData)
		local hints = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20, 0.14, 0),
			Size = UDim2.fromOffset(220, 228),
			BackgroundTransparency = 1,
			Parent = gui,
		}, {
			UI.new("UIListLayout", {
				Padding = UDim.new(0, 1),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		for i, pair in {
			{ "Menú y tienda", "B" },
			{ "Granada", "G" },
			{ "Ataque aéreo (racha 5)", "T" },
			{ "Deslizar", "C" },
			{ "Cuchillo rápido", "F" },
			{ "Recargar", "R" },
			{ "Inspeccionar", "V" },
			{ "Habilidades", "E Z X" },
			{ "Emotes", "N" },
			{ "Grafiti", "J" },
			{ "Marcador", "Tab" },
			{ "Regalo", "H" },
		} do
			local row = UI.new("Frame", {
				LayoutOrder = i,
				Size = UDim2.fromOffset(220, 18),
				BackgroundTransparency = 1,
				Parent = hints,
			})
			UI.label({
				Size = UDim2.new(1, -56, 1, 0),
				Text = pair[1],
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
			local key = UI.new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(46, 17),
				BackgroundColor3 = Color3.fromRGB(20, 20, 25),
				Parent = row,
			}, { UI.corner(5) })
			UI.label({ Size = UDim2.fromScale(1, 1), Text = pair[2], TextSize = 14, Parent = key })
		end
		refs.KeyHints = hints
	end
end

local function buildPlayerPanel()
	-- Vida (abajo a la izquierda)
	local health = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 56, 1, -24),
		Size = UDim2.fromOffset(250, 26),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		Parent = gui,
	}, { UI.corner(13), UI.stroke(Color3.new(0, 0, 0), 3, 0) })
	refs.HealthChip = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.25,
		Parent = health,
	}, { UI.corner(13) })
	refs.HealthFill = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(70, 220, 90),
		Parent = health,
	}, { UI.corner(13), UI.gloss() })
	refs.HealthText = UI.label({ Size = UDim2.fromScale(1, 1), Text = "100", TextSize = 18, Parent = health })
	UI.label({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, -6, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		Text = "✚",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(90, 230, 110),
		TextStrokeTransparency = 0,
		Parent = health,
	})

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

	refs.CarrierBanner = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -158),
		Size = UDim2.fromOffset(700, 34),
		Text = "🚩 ¡TIENES LA BANDERA! Llévala a tu base",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(255, 220, 70),
		TextStrokeTransparency = 0,
		Visible = false,
		Parent = gui,
	})

	refs.Toast = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -122),
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

	-- Quién te eliminó (arriba); los botones y la cámara de espectador están en DeathScreen
	refs.DeathScreen = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	refs.DeathText = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.17),
		Size = UDim2.fromOffset(800, 60),
		Text = "",
		TextSize = 40,
		TextColor3 = Color3.fromRGB(255, 80, 80),
		RichText = true,
		Parent = refs.DeathScreen,
	})
	refs.RespawnText = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(600, 30),
		Text = "",
		Visible = false,
		TextSize = 22,
		Parent = refs.DeathScreen,
	})
	refs.DeathIcon = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.27),
		Size = UDim2.fromOffset(220, 86),
		BackgroundTransparency = 1,
		Parent = refs.DeathScreen,
	})

	-- Aviso de baja propia ("ELIMINADO", doble baja...)
	refs.KillBanner = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromOffset(440, 64),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	refs.KillScale = UI.new("UIScale", { Parent = refs.KillBanner })
	refs.KillIcon = UI.label({
		Size = UDim2.fromOffset(64, 64),
		Text = "💀",
		TextSize = 46,
		Parent = refs.KillBanner,
	})
	refs.KillTitle = UI.label({
		Position = UDim2.fromOffset(70, 2),
		Size = UDim2.fromOffset(370, 34),
		Text = "",
		TextSize = 32,
		TextStrokeTransparency = 0,
		TextColor3 = Color3.fromRGB(255, 70, 70),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.KillBanner,
	})
	refs.KillSub = UI.label({
		Position = UDim2.fromOffset(70, 36),
		Size = UDim2.fromOffset(370, 24),
		Text = "",
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 225, 100),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.KillBanner,
	})

	-- Fin de ronda
	refs.RoundEnd = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
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

	-- En pantallas bajas (móvil en horizontal) el panel se encoge para caber entero
	local roundScale = UI.new("UIScale", { Parent = refs.RoundEnd })
	local function fitRoundEnd()
		local viewport = workspace.CurrentCamera.ViewportSize
		roundScale.Scale = math.clamp(math.min((viewport.Y - 40) / refs.RoundEnd.Size.Y.Offset, (viewport.X - 20) / 560), 0.45, 1)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitRoundEnd)
	refs.RoundEnd:GetPropertyChangedSignal("Size"):Connect(fitRoundEnd)
	fitRoundEnd()

	-- Resumen de tu partida (llega con MatchSummary): estadísticas, barra de nivel y monedas
	refs.Summary = UI.new("Frame", {
		Position = UDim2.fromOffset(20, 200),
		Size = UDim2.new(1, -40, 0, 170),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = refs.RoundEnd,
	})
	refs.SummaryStats = UI.label({
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		TextSize = 22,
		RichText = true,
		Parent = refs.Summary,
	})
	refs.SummaryLevel = UI.label({
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(0.5, 0, 0, 28),
		Text = "",
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.Summary,
	})
	refs.SummaryXP = UI.label({
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.new(0.5, 0, 0, 28),
		Text = "",
		TextSize = 24,
		TextColor3 = Color3.fromRGB(120, 220, 255),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = refs.Summary,
	})
	local bar = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 78),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = Color3.fromRGB(40, 44, 70),
		Parent = refs.Summary,
	}, { UI.corner(10), UI.stroke(Color3.new(1, 1, 1), 2, 0.5) })
	refs.SummaryFill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(80, 200, 255),
		Parent = bar,
	}, { UI.corner(10) })
	refs.SummaryLevelUp = UI.label({
		Position = UDim2.fromOffset(0, 102),
		Size = UDim2.new(1, 0, 0, 30),
		Text = "⬆ ¡SUBES DE NIVEL!",
		TextSize = 26,
		TextColor3 = Color3.fromRGB(255, 220, 70),
		Visible = false,
		Parent = refs.Summary,
	})
	refs.SummaryCoins = UI.label({
		Position = UDim2.fromOffset(0, 134),
		Size = UDim2.new(0.45, 0, 0, 32),
		Text = "",
		TextSize = 28,
		TextColor3 = Color3.fromRGB(255, 210, 60),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.Summary,
	})
	-- Rango competitivo: icono, nombre y puntos ganados o perdidos
	refs.SummaryRank = UI.label({
		Position = UDim2.new(0.45, 0, 0, 134),
		Size = UDim2.new(0.55, 0, 0, 32),
		Text = "",
		TextSize = 24,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = refs.Summary,
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
	elseif kind == "Challenge" then
		bigMessage("✅ " .. text, Color3.fromRGB(90, 255, 140))
		Sounds.Play("Kill")
	elseif kind == "Mastery" then
		bigMessage("🏆 " .. text, Color3.fromRGB(255, 200, 50))
		Sounds.Play("Kill")
	elseif kind == "LevelUp" then
		bigMessage("⬆ ¡NIVEL " .. tostring(text) .. "!", Color3.fromRGB(255, 210, 60))
		Sounds.Play("Kill")
		-- Qué da este nivel del pase (y qué daría el premium, si no lo tiene)
		local tier = type(text) == "number" and GameConfig.BattlePass[text]
		if tier then
			local function describe(reward)
				if not reward then
					return nil
				elseif reward.Type == "Coins" then
					return "🪙 +" .. tostring(reward.Amount)
				elseif reward.Type == "Skin" then
					return "🎨 Skin " .. Skins.Get(reward.Id).Name
				elseif reward.Type == "Crate" then
					return "🎁 Caja"
				elseif reward.Type == "Outfit" then
					return "👕 Traje nuevo"
				elseif reward.Type == "KillEffect" then
					return "💥 Efecto de eliminación"
				end
				return reward.Type
			end
			local data = ClientState.Data
			local free, premium = describe(tier.Free), describe(tier.Premium)
			local line = free and ("Recompensa: " .. free) or ""
			if premium and (GameConfig.PremiumPassId ~= 0 or (data and data.Premium)) then
				if data and data.Premium then
					line ..= (line ~= "" and "   ·   " or "") .. "👑 " .. premium
				else
					line ..= (line ~= "" and "   ·   " or "") .. "👑 Con el pase premium: " .. premium
				end
			end
			if line ~= "" then
				-- En el aviso inferior (el banner superior lo usan las rachas y banderas)
				task.delay(0.6, function()
					timedLabel(refs.Toast, line, 4)
				end)
			end
		end
	elseif kind == "Flag" then
		timedLabel(refs.Banner, "🚩 " .. text, 3)
		Sounds.Play("Flag")
	elseif kind == "Streak" then
		timedLabel(refs.Banner, "🔥 " .. text, 3)
	elseif kind == "Bounty" then
		timedLabel(refs.Banner, "💰 " .. text, 3.5)
	elseif kind == "Wanted" then
		-- Te has convertido en el buscado: todos ven tu cartel
		bigMessage("💰 ¡TE BUSCAN! " .. tostring(text) .. " 🪙 por tu cabeza", Color3.fromRGB(255, 120, 80))
		Sounds.Play("Flag")
	elseif kind == "BountyClaimed" then
		bigMessage("💰 ¡RECOMPENSA COBRADA! +" .. tostring(text) .. " 🪙", Color3.fromRGB(255, 210, 60))
		Sounds.Play("Kill")
	else
		timedLabel(refs.Toast, text, 3)
		Sounds.Play("Click")
	end
end

local multiCount, lastKillTime, killToken = 0, 0, nil
local MULTI_NAMES = { [2] = "¡DOBLE BAJA!", [3] = "¡TRIPLE BAJA!", [4] = "¡CUÁDRUPLE!" }

local function showKillBanner(victim, headshot)
	local now = os.clock()
	multiCount = (now - lastKillTime < 4) and multiCount + 1 or 1
	lastKillTime = now
	local multi = MULTI_NAMES[multiCount] or (multiCount >= 5 and "¡IMPARABLE!" or nil)
	refs.KillTitle.Text = multi or "ELIMINADO"
	refs.KillTitle.TextColor3 = multi and Color3.fromRGB(255, 180, 30) or Color3.fromRGB(255, 70, 70)
	refs.KillSub.Text = tostring(victim) .. (headshot and "  ·  DISPARO A LA CABEZA" or "")
	refs.KillIcon.Text = headshot and "🎯" or "💀"
	refs.KillBanner.Visible = true
	refs.KillScale.Scale = 1.5
	tween(refs.KillScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	local token = {}
	killToken = token
	task.delay(2.2, function()
		if killToken == token then
			refs.KillBanner.Visible = false
		end
	end)
end

local function onKillFeed(info)
	if type(info) ~= "table" then
		return
	end
	if info.Killer == player.Name and info.Victim ~= player.Name then
		showKillBanner(info.Victim, info.Headshot)
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
local function onHitConfirm(damage, headshot, killed, serverPosition)
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

	-- Número de daño en el mundo, encima de donde le diste (si lo sabemos), con un rebote
	-- El servidor dice dónde fue el daño; si no, el último impacto del propio cliente
	local hitPosition = typeof(serverPosition) == "Vector3" and serverPosition
		or (os.clock() - ClientState.LastHitTime < 0.6 and ClientState.LastHitPosition)
	if type(damage) == "number" and hitPosition then
		local anchor = Instance.new("Attachment")
		anchor.WorldPosition = hitPosition + Vector3.new(math.random(-10, 10) / 10, 1.2, math.random(-10, 10) / 10)
		anchor.Parent = workspace.Terrain
		local board = Instance.new("BillboardGui")
		board.Size = UDim2.fromOffset(120, 50)
		board.AlwaysOnTop = true
		board.LightInfluence = 0
		board.Adornee = anchor
		board.Parent = gui.Parent -- (un BillboardGui dentro de un ScreenGui no se dibuja)
		local label = UI.label({
			Size = UDim2.fromScale(1, 1),
			Text = (killed and "💀 " or "") .. tostring(damage) .. (headshot and "!" or ""),
			TextSize = killed and 34 or (headshot and 32 or 26),
			TextColor3 = color,
			Parent = board,
		})
		local scale = UI.new("UIScale", { Scale = 1.6, Parent = label })
		tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(0.35, function()
			tween(label, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
			tween(board, 0.5, { StudsOffsetWorldSpace = Vector3.new(0, 2, 0) })
		end)
		Debris:AddItem(board, 1)
		Debris:AddItem(anchor, 1)
	elseif type(damage) == "number" then
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

local summaryToken = 0

-- Anima el resumen: estadísticas, la barra de nivel se llena (y se vacía al subir de nivel) y las
-- monedas cuentan hacia arriba
local function onMatchSummary(summary)
	if type(summary) ~= "table" or type(summary.XP) ~= "number" then
		return
	end
	summaryToken += 1
	local token = summaryToken
	refs.RoundEnd.Size = UDim2.fromOffset(560, 390)
	refs.Summary.Visible = true
	refs.SummaryLevelUp.Visible = false
	local stats = string.format("🎯 %d bajas   💀 %d muertes   🔥 racha %d", summary.Kills or 0, summary.Deaths or 0, summary.BestStreak or 0)
	if (summary.Captures or 0) > 0 then
		stats ..= "   🚩 " .. summary.Captures
	end
	if (summary.WinStreak or 0) >= 2 then
		stats ..= "   🏆 x" .. summary.WinStreak
	end
	refs.SummaryStats.Text = stats
	local perLevel = math.max(1, summary.XPPerLevel or 1)
	local level = summary.StartLevel or summary.Level or 1
	refs.SummaryLevel.Text = "NIVEL " .. level
	refs.SummaryFill.Size = UDim2.fromScale(math.clamp((summary.StartXP or 0) / perLevel, 0, 1), 1)
	refs.SummaryXP.Text = "+0 XP"
	refs.SummaryCoins.Text = "+0 🪙"
	local levelsUp = math.max(0, (summary.Level or level) - level)
	local startRank = summary.StartRank or summary.RankPoints or 0
	local endRank = summary.RankPoints or startRank
	local rankDelta = endRank - startRank
	local function rankText(points, delta)
		local tier = Ranks.Get(points)
		local deltaText = ""
		if delta > 0 then
			deltaText = '  <font color="#6EE06E">+' .. delta .. " RP</font>"
		elseif delta < 0 then
			deltaText = '  <font color="#FF6E6E">' .. delta .. " RP</font>"
		end
		return string.format('%s <font color="%s"><b>%s</b></font>%s', tier.Icon, UI.hex(tier.Color), string.upper(tier.Name), deltaText)
	end
	refs.SummaryRank.Text = rankText(startRank, 0)
	task.spawn(function()
		task.wait(0.4)
		-- Barra de XP: un tramo por cada nivel subido
		local levels = math.max(0, (summary.Level or level) - level)
		for i = 0, levels do
			if token ~= summaryToken then
				return
			end
			local target = i < levels and 1 or math.clamp((summary.LevelXP or 0) / perLevel, 0, 1)
			tween(refs.SummaryFill, 0.7, { Size = UDim2.fromScale(target, 1) })
			task.wait(0.75)
			if i < levels then
				level += 1
				refs.SummaryLevel.Text = "NIVEL " .. level
				refs.SummaryLevelUp.Text = "⬆ ¡SUBES DE NIVEL!"
				refs.SummaryLevelUp.TextColor3 = Color3.fromRGB(255, 220, 70)
				refs.SummaryLevelUp.Visible = true
				Sounds.Play("Flag")
				refs.SummaryFill.Size = UDim2.fromScale(0, 1)
			end
		end
	end)
	task.spawn(function()
		-- Contadores de XP y monedas
		local steps = 24
		for i = 1, steps do
			if token ~= summaryToken then
				return
			end
			local t = i / steps
			refs.SummaryXP.Text = "+" .. math.floor(summary.XP * t) .. " XP"
			refs.SummaryCoins.Text = "+" .. math.floor((summary.Coins or 0) * t) .. " 🪙"
			task.wait(0.05)
		end
		Sounds.Play("Kill")
		if rankDelta ~= 0 and token == summaryToken then
			refs.SummaryRank.Text = rankText(endRank, rankDelta)
			-- ¡Subes de rango!
			if Ranks.Index(endRank) > Ranks.Index(startRank) then
				-- (después de la animación de subir de nivel, que usa el mismo cartel)
				task.wait(math.max(0.3, 0.4 + 0.75 * (levelsUp + 1) - 1.2))
				if token ~= summaryToken then
					return
				end
				local tier = Ranks.Get(endRank)
				refs.SummaryLevelUp.Text = tier.Icon .. " ¡ASCIENDES A " .. string.upper(tier.Name) .. "!"
				refs.SummaryLevelUp.TextColor3 = tier.Color
				refs.SummaryLevelUp.Visible = true
				Sounds.Play("Flag")
			end
		end
	end)
end

local function onRoundEnd(info)
	if type(info) ~= "table" then
		return
	end
	summaryToken += 1
	refs.RoundEnd.Size = UDim2.fromOffset(560, 220)
	refs.Summary.Visible = false
	local teamA = ReplicatedStorage:GetAttribute("TeamA") or "Rojo"
	local teamB = ReplicatedStorage:GetAttribute("TeamB") or "Azul"
	if info.TeamMode == false then
		local won = info.Winner == player.Name
		refs.RoundTitle.Text = won and "¡VICTORIA!" or (info.Winner and (info.Winner .. " GANA") or "FIN")
		refs.RoundTitle.TextColor3 = won and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(255, 120, 80)
		refs.RoundScore.Text = "👑 " .. tostring(info.Winner or "-") .. " · " .. tostring(info.LeaderScore or 0)
		refs.RoundMVP.Text = info.MVP and ("⭐ MVP: " .. info.MVP .. " (" .. info.MVPKills .. " bajas)") or ""
		refs.RoundEnd.Visible = true
		task.delay(7, function()
			refs.RoundEnd.Visible = false
		end)
		return
	elseif info.Winner then
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
	local mvpText = ""
	if info.MVP then
		local captures = info.MVPCaptures or 0
		mvpText = "⭐ MVP: " .. info.MVP .. " (" .. info.MVPKills .. " bajas"
		if captures > 0 then
			mvpText ..= ", " .. captures .. (captures == 1 and " captura" or " capturas")
		end
		mvpText ..= ")"
	end
	refs.RoundMVP.Text = mvpText
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

local lastRowSignature = ""

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
	-- Solo se reconstruye si algo ha cambiado (orden, bajas, equipos o fotos ya cargadas)
	local parts = {}
	for rank = 1, math.min(10, #list) do
		local p = list[rank]
		table.insert(parts, p.UserId .. ":" .. kills(p) .. ":" .. tostring(p.Team) .. ":" .. tostring(getThumbnail(p.UserId) ~= ""))
	end
	local signature = table.concat(parts, "|")
	if signature == lastRowSignature then
		return
	end
	lastRowSignature = signature
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

-- Últimos valores escritos en el HUD (para no reescribir textos iguales cada fotograma)
local hudCache: { [string]: any } = {}

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
	local modeName = ReplicatedStorage:GetAttribute("ModeName") or "Duelo por equipos"
	local mapName = ReplicatedStorage:GetAttribute("MapName") or ""
	local teamMode = ReplicatedStorage:GetAttribute("TeamMode") ~= false
	refs.Timer.Text = UI.formatTime(timeLeft)
	if state == "Intermission" then
		refs.Mode.Text = "Calentamiento · " .. mapName .. " · vota el siguiente mapa (" .. timeLeft .. ")"
	elseif state == "Ended" then
		refs.Mode.Text = "Fin de la ronda"
	else
		refs.Mode.Text = mapName .. " · " .. modeName .. " · Primero a " .. tostring(ReplicatedStorage:GetAttribute("ScoreToWin") or "?")
		-- Eliminación: cuántos quedan en pie de cada equipo
		local aliveA, aliveB = ReplicatedStorage:GetAttribute("AliveA"), ReplicatedStorage:GetAttribute("AliveB")
		if aliveA and aliveB and teamA and teamB then
			refs.Mode.Text = modeName .. " · En pie: " .. teamA .. " " .. aliveA .. " – " .. aliveB .. " " .. teamB
		end
	end

	-- Modos sin equipos: tu puntuación contra la del líder
	if not teamMode then
		refs.ScoreA.Text = tostring(player:GetAttribute("Score") or 0)
		refs.ScoreB.Text = tostring(ReplicatedStorage:GetAttribute("LeaderScore") or 0)
		refs.ScoreABox.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
		refs.ScoreBBox.BackgroundColor3 = Color3.fromRGB(230, 160, 30)
		refs.FlagA.Text, refs.FlagA.TextColor3 = "TÚ", Color3.fromRGB(150, 255, 150)
		local leader = ReplicatedStorage:GetAttribute("LeaderName") or ""
		refs.FlagB.Text = leader ~= "" and ("👑 " .. leader) or "LÍDER"
		refs.FlagB.TextColor3 = Color3.fromRGB(255, 210, 80)
		return
	end

	-- Banderas
	local function flagStatus(teamName)
		local flagState = teamName and ReplicatedStorage:GetAttribute("FlagState_" .. teamName)
		if flagState == "Home" then
			return "🚩 En base", Color3.fromRGB(150, 255, 150)
		elseif flagState == "Carried" then
			local carrier = ReplicatedStorage:GetAttribute("FlagCarrier_" .. teamName) or ""
			return "⚠ " .. carrier, Color3.fromRGB(255, 90, 90)
		elseif flagState == "Dropped" then
			return "⬇ Caída", Color3.fromRGB(255, 210, 80)
		end
		return "", Color3.new(1, 1, 1)
	end
	refs.FlagA.Text, refs.FlagA.TextColor3 = flagStatus(teamA)
	refs.FlagB.Text, refs.FlagB.TextColor3 = flagStatus(teamB)

	-- Zona de control
	local zoneOwner = ReplicatedStorage:GetAttribute("ZoneOwner")
	if zoneOwner ~= nil then
		if zoneOwner == "" then
			refs.FlagA.Text, refs.FlagA.TextColor3 = "◆ Zona libre", Color3.new(1, 1, 1)
		elseif zoneOwner == "Contested" then
			refs.FlagA.Text, refs.FlagA.TextColor3 = "◆ ¡DISPUTADA!", Color3.fromRGB(255, 200, 40)
		else
			local team = game:GetService("Teams"):FindFirstChild(zoneOwner)
			refs.FlagA.Text = "◆ Zona: " .. zoneOwner
			refs.FlagA.TextColor3 = team and team.TeamColor.Color or Color3.new(1, 1, 1)
		end
		refs.FlagB.Text = "Se mueve en " .. tostring(ReplicatedStorage:GetAttribute("ZoneMoveIn") or 0) .. "s"
		refs.FlagB.TextColor3 = Color3.fromRGB(200, 210, 230)
	end

	-- Infección: supervivientes contra zombis (en vez de los puntos)
	local infection = ReplicatedStorage:GetAttribute("Infection")
	if infection and state == "Playing" then
		local survivors = ReplicatedStorage:GetAttribute("AliveA") or 0
		local zombies = ReplicatedStorage:GetAttribute("AliveB") or 0
		refs.ScoreA.Text = tostring(survivors)
		refs.ScoreB.Text = tostring(zombies)
		refs.ScoreBBox.BackgroundColor3 = Color3.fromRGB(90, 160, 60)
		refs.FlagA.Text, refs.FlagA.TextColor3 = "🧑 Supervivientes", Color3.fromRGB(200, 230, 255)
		refs.FlagB.Text, refs.FlagB.TextColor3 = "🧟 Zombis", Color3.fromRGB(150, 255, 120)
		local zombie = player.Team and player.Team.Name == teamB and infection == "On"
		if infection == "Prep" then
			refs.Mode.Text = modeName .. " · ¡Escóndete! La infección va a empezar"
		elseif zombie then
			refs.Mode.Text = modeName .. " · 🧟 Eres un zombi: ¡atrapa a los supervivientes!"
		else
			refs.Mode.Text = modeName .. " · ¡Sobrevive hasta que acabe el tiempo!"
		end
	end

	-- La bandera que llevamos a la espalda no nos tapa la vista
	-- (solo se repasa cuando cambia qué banderas llevamos: este aviso llega con cada atributo)
	local flagsFolder = workspace:FindFirstChild("Flags")
	local carrying = ""
	if flagsFolder then
		for _, model in flagsFolder:GetChildren() do
			local teamName = string.gsub(model.Name, "^Flag_", "")
			if ReplicatedStorage:GetAttribute("FlagCarrier_" .. teamName) == player.Name then
				carrying ..= teamName
			end
		end
		carrying ..= "#" .. #flagsFolder:GetChildren()
	end
	if flagsFolder and carrying ~= hudCache.Carrying then
		hudCache.Carrying = carrying
		for _, model in flagsFolder:GetChildren() do
			local teamName = string.gsub(model.Name, "^Flag_", "")
			local mine = ReplicatedStorage:GetAttribute("FlagCarrier_" .. teamName) == player.Name
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = mine and 1 or 0
				elseif part:IsA("BillboardGui") then
					part.Enabled = not mine
				end
			end
		end
	end
end

local function updateData(data)
	if not data then
		return
	end
	local per = data.XPPerLevel or 1000
	refs.LevelText.Text = "Nivel " .. data.Level .. "  ·  " .. data.XP .. "/" .. per .. " XP"
	tween(refs.XPFill, 0.3, { Size = UDim2.fromScale(math.clamp(data.XP / per, 0, 1), 1) })
	-- La chuleta de teclas solo para los que empiezan (luego estorba al killfeed y a las armas)
	if refs.KeyHints then
		refs.KeyHints.Visible = (data.Level or 1) < 5
	end
end

local lastHealth = 100
local lastDamageTime = 0
local lowHealthCC: ColorCorrectionEffect? = nil
local chipRatio = 1
local renderCrosshair

local function render(dt)
	gui.Enabled = not ClientState.InMainMenu
	if ClientState.InMainMenu then
		return -- en la pantalla de inicio no se dibuja el HUD
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- Vida
	if humanoid then
		local health = math.max(0, humanoid.Health)
		local ratio = health / math.max(humanoid.MaxHealth, 1)
		local shown = math.ceil(health)
		local healthChanged = ratio ~= hudCache.HealthRatio or shown ~= hudCache.HealthShown or not (lowHealthCC and lowHealthCC.Parent)
		hudCache.HealthRatio, hudCache.HealthShown = ratio, shown
		if healthChanged then
			refs.HealthFill.Size = UDim2.fromScale(ratio, 1)
			refs.HealthFill.BackgroundColor3 = Color3.fromRGB(230, 60, 60):Lerp(Color3.fromRGB(70, 220, 90), ratio)
			refs.HealthText.Text = tostring(shown)
		end
		-- La parte blanca baja despacio y deja ver el daño recibido
		local newChip = ratio > chipRatio and ratio or math.max(ratio, chipRatio - dt * 0.5)
		if newChip ~= chipRatio or healthChanged then
			chipRatio = newChip
			refs.HealthChip.Size = UDim2.fromScale(chipRatio, 1)
		end
		if health < lastHealth - 0.5 then
			lastDamageTime = os.clock()
			refs.DamageStroke.Transparency = 0.35
			tween(refs.DamageStroke, 0.6, { Transparency = 1 })
		elseif ratio < 0.35 and ratio > 0 and os.clock() - lastDamageTime > 0.6 then
			-- Vida baja: la viñeta roja late
			refs.DamageStroke.Transparency = 0.7 + 0.15 * math.sin(os.clock() * 5)
		end
		lastHealth = health
		-- Vida baja: el mundo pierde color poco a poco (corrección de color solo en este cliente)
		local lowCC = lowHealthCC
		if healthChanged then
			if not lowCC or not lowCC.Parent then
				lowCC = Instance.new("ColorCorrectionEffect")
				lowCC.Name = "LowHealthCC"
				lowCC.Parent = game:GetService("Lighting")
				lowHealthCC = lowCC
			end
			local danger = (health > 0 and ratio < 0.4) and (1 - ratio / 0.4) or 0
			lowCC.Saturation = -0.7 * danger
			lowCC.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 200, 200), danger)
			lowCC.Contrast = 0.1 * danger
		end
	end

	-- Racha (los textos solo se reescriben cuando cambia el valor: cada escritura recoloca la interfaz)
	local streak = player:GetAttribute("Streak") or 0
	if streak ~= hudCache.Streak then
		hudCache.Streak = streak
		refs.StreakText.Text = "Racha x" .. streak
		refs.StreakFill.Size = UDim2.fromScale(1, math.clamp(streak / 10, 0, 1))
	end

	-- Arma
	local def = ClientState.CurrentDef
	local tool = ClientState.CurrentTool
	if def and tool then
		refs.WeaponName.Text = def.DisplayName
		if def.Type == "Gun" then
			local reserve = tool:GetAttribute("Reserve") or 0
			local low = ClientState.Ammo <= math.ceil(def.MagSize * 0.25)
			if ClientState.Ammo ~= hudCache.Ammo or reserve ~= hudCache.Reserve or low ~= hudCache.Low then
				hudCache.Ammo, hudCache.Reserve, hudCache.Low = ClientState.Ammo, reserve, low
				refs.Ammo.Text = string.format(
					'<font color="%s">%d</font><font size="28" color="#C8C8C8"> | %d</font>',
					low and "#FF5050" or "#FFFFFF",
					ClientState.Ammo,
					reserve
				)
			end
			refs.AmmoBar.Visible = true
			local fill = ClientState.Reloading and ClientState.ReloadProgress or ClientState.Ammo / def.MagSize
			refs.AmmoFill.Size = UDim2.fromScale(math.clamp(fill, 0, 1), 1)
			refs.AmmoFill.BackgroundColor3 = ClientState.Reloading and Color3.fromRGB(120, 200, 255)
				or (ClientState.Ammo <= math.ceil(def.MagSize * 0.25) and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 210, 80))
			local percent = ClientState.Reloading and math.floor(ClientState.ReloadProgress * 100) or -1
			if ClientState.Reloading then
				if percent ~= hudCache.ReloadPercent then
					refs.ReloadHint.Text = "RECARGANDO " .. percent .. "%"
				end
			elseif ClientState.Ammo == 0 and reserve == 0 then
				refs.ReloadHint.Text = "SIN MUNICIÓN"
			elseif ClientState.Ammo <= math.ceil(def.MagSize * 0.25) then
				refs.ReloadHint.Text = "[R] Recargar"
			else
				refs.ReloadHint.Text = ""
			end
			hudCache.ReloadPercent = percent
		else
			hudCache.Ammo = nil
			refs.Ammo.Text = "∞"
			refs.ReloadHint.Text = ""
			refs.AmmoBar.Visible = false
		end
	else
		hudCache.Ammo = nil
		refs.WeaponName.Text = ""
		refs.Ammo.Text = ""
		refs.ReloadHint.Text = ""
		refs.AmmoBar.Visible = false
	end

	-- Ranuras: se revisan al cambiar de arma y, si no, unas 4 veces por segundo
	local now = os.clock()
	if tool == hudCache.SlotTool and now - (hudCache.SlotsAt or 0) < 0.25 then
		renderCrosshair(def)
		return
	end
	hudCache.SlotTool, hudCache.SlotsAt = tool, now
	local tools = WeaponController.GetTools()
	for slot, row in refs.Slots do
		local slotTool = tools[slot]
		local weaponName = slotTool and slotTool:GetAttribute("Weapon")
		local slotDef = weaponName and Weapons.Get(weaponName)
		row.Row.Visible = slotDef ~= nil
		row.Name.Text = slotDef and slotDef.DisplayName or ""
		local active = slotTool ~= nil and slotTool == tool
		row.Name.TextColor3 = active and Color3.fromRGB(255, 210, 60) or Color3.fromRGB(220, 220, 220)
		row.Key.BackgroundColor3 = active and Color3.fromRGB(255, 170, 30) or Color3.fromRGB(20, 20, 25)
		row.Stroke.Transparency = active and 0 or 1
		row.Row.BackgroundTransparency = active and 0.45 or 0.7
		-- Icono 3D (solo se reconstruye si cambia el arma o la skin)
		local skinId = slotTool and slotTool:GetAttribute("Skin")
		local iconKey = slotDef and (weaponName .. "|" .. tostring(skinId)) or nil
		if iconKey ~= row.IconKey then
			row.IconKey = iconKey
			row.Icon:ClearAllChildren()
			if iconKey then
				WeaponIcon.Create(weaponName, skinId, { Size = UDim2.fromScale(1, 1), Parent = row.Icon }, "side", 170 / 44)
			end
		end
	end

	renderCrosshair(def)
end

-- Mira (color y tamaño elegidos en Ajustes)
function renderCrosshair(def)
	local settings = Settings.Get()
	local colorIndex = math.clamp(math.floor(settings.CrossColor or 1), 1, #GameConfig.CrosshairColors)
	local size = settings.CrossSize or 1
	if colorIndex ~= hudCache.CrossColor or size ~= hudCache.CrossSize then
		hudCache.CrossColor, hudCache.CrossSize = colorIndex, size
		local color = GameConfig.CrosshairColors[colorIndex]
		for _, line in refs.CrossLines do
			local vertical = line.Dir.X == 0
			line.Frame.BackgroundColor3 = color
			line.Frame.Size = vertical and UDim2.fromOffset(2, math.floor(9 * size + 0.5)) or UDim2.fromOffset(math.floor(9 * size + 0.5), 2)
		end
		refs.CrossDot.BackgroundColor3 = color
	end
	local aim = ClientState.AimAlpha
	local isGun = def and def.Type == "Gun"
	local gap = (6 + ClientState.Spread * 6) * size
	for _, line in refs.CrossLines do
		line.Frame.Position = UDim2.fromOffset(line.Dir.X * (gap + 4 * size), line.Dir.Y * (gap + 4 * size))
		line.Frame.Visible = isGun and aim < 0.5
	end
	refs.CrossDot.Visible = aim < 0.5
	refs.Crosshair.Visible = not ClientState.IsBlocked()
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
	Remotes.MatchSummary.OnClientEvent:Connect(onMatchSummary)
	Remotes.Died.OnClientEvent:Connect(function(killerName, weaponName, killerHealth)
		local weapon = weaponName and Weapons.Get(weaponName)
		if killerName then
			refs.DeathText.Text = "ELIMINADO POR <b>"
				.. killerName
				.. "</b>"
				.. (weapon and (" · " .. weapon.DisplayName) or "")
				.. (type(killerHealth) == "number" and killerHealth > 0 and killerName ~= player.Name and string.format('  <font color="#7CFF8A">❤ %d</font>', killerHealth) or "")
		else
			refs.DeathText.Text = "HAS MUERTO"
		end
		refs.DeathIcon:ClearAllChildren()
		if weapon and weapon.Parts then
			WeaponIcon.Create(weaponName, "Default", { Size = UDim2.fromScale(1, 1), Parent = refs.DeathIcon }, "angled", 280 / 110)
		elseif weapon then
			-- Armas sin modelo (granada): un emoji grande
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.fromScale(1, 1)
			icon.BackgroundTransparency = 1
			icon.Text = "💣"
			icon.TextScaled = true
			icon.Parent = refs.DeathIcon
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
	player:GetAttributeChangedSignal("Score"):Connect(updateScoreboard)
	updateScoreboard()

	local function updateCarrier()
		refs.CarrierBanner.Visible = player:GetAttribute("CarryingFlag") == true
	end
	player:GetAttributeChangedSignal("CarryingFlag"):Connect(updateCarrier)
	updateCarrier()

	task.spawn(function()
		while true do
			if not ClientState.InMainMenu then
				updatePlayerRow()
			end
			task.wait(1)
		end
	end)

	RunService.RenderStepped:Connect(render)
end

return HUD
