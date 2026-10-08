-- PROGRESO DE NIVEL: "NIVEL 42 · 350 / 1000 XP" y la barra que avanza con lo ganado. Si subes de
-- nivel: la barra se llena, destello dorado, "NIVEL 43" con su sonido (~1 s, sin bloquear nada) y
-- sigue con lo que sobra.
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Anim = require(script.Parent.Parent.Anim)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local XPProgress = {}

function XPProgress.new(parent)
	local root = C.panel({ Name = "XPProgress", Size = UDim2.fromOffset(380, 96), Parent = parent }, { Alpha = 0.16 })
	-- Insignia con el número de nivel (rombo amarillo)
	local badge = C.new("Frame", { Name = "Badge", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(68, 68), Parent = root })
	C.new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 26, 12), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(46, 46), Rotation = 45, Parent = badge }, {
		C.corner(6),
		C.new("UIStroke", { Color = Colors.Yellow, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	local levelNumber = C.text({ Name = "LevelNumber", Text = "1", Role = "TitleItalic", TextSize = 26, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = badge })
	local title = C.text({ Name = "Level", Text = "NIVEL 1", Role = "TitleItalic", TextSize = 22, Position = UDim2.fromOffset(92, 12), Size = UDim2.fromOffset(160, 26), Parent = root })
	local gained = C.text({ Name = "Gained", Text = "", Role = "TitleItalic", TextSize = 18, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(120, 22), Parent = root })
	local bar = C.progress({ Name = "Bar", Position = UDim2.fromOffset(92, 46), Size = UDim2.new(1, -106, 0, 10), Parent = root })
	bar.Fill.BackgroundColor3 = Colors.Yellow
	local amount = C.text({ Name = "Amount", Text = "", Role = "Number", TextSize = 15, Color = Colors.TextDim, Position = UDim2.fromOffset(92, 62), Size = UDim2.new(1, -106, 0, 20), Parent = root })
	-- Aviso de subida de nivel (encima del panel)
	local levelUp = C.text({ Name = "LevelUp", Text = "", Role = "TitleItalic", TextSize = 30, Color = Colors.Yellow, AlignX = Enum.TextXAlignment.Center, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -4), Size = UDim2.fromOffset(300, 36), Stroke = 2, Visible = false, Parent = root })

	local info
	local api = { Frame = root }
	function api.Set(levelInfo)
		info = levelInfo
		root.Visible = info ~= nil
		-- (si saliste antes de que se desvaneciera, no aparece de entrada en la siguiente partida)
		levelUp.Visible = false
		levelUp.TextTransparency = 1
		if not info then
			return
		end
		levelNumber.Text = tostring(info.StartLevel)
		title.Text = "NIVEL " .. info.StartLevel
		gained.Text = info.Gained > 0 and ("+" .. info.Gained .. " XP") or ""
		bar:Set(info.Steps[1] and info.Steps[1].From or 0, false)
		amount.Text = string.format("%d / %d XP", info.StartXP, info.PerLevel)
	end

	function api.Play(token)
		if not info then
			return
		end
		task.spawn(function()
			for i, step in info.Steps do
				if not Anim.Alive(token) then
					return
				end
				local fromXP = math.floor(step.From * info.PerLevel)
				local toXP = math.floor(step.To * info.PerLevel)
				local time = math.clamp((step.To - step.From) * 1.1, 0.25, 0.9)
				bar:Set(step.From, false)
				Transition.Tween(bar.Fill, time, { Size = UDim2.fromScale(step.To, 1) })
				Anim.Count(amount, fromXP, toXP, time, "%d / " .. info.PerLevel .. " XP", token, nil)
				UISound.Play("Tick", 1.1)
				task.wait(time + 0.05)
				if step.LevelUp and Anim.Alive(token) then
					-- ¡Nivel nuevo! (breve)
					local newLevel = step.Level + 1
					UISound.Play("LevelUp")
					Anim.Glow(root, Colors.Yellow, 0.55, 0.6)
					levelNumber.Text = tostring(newLevel)
					title.Text = "NIVEL " .. newLevel
					Transition.Pulse(badge, 1.35, 0.35)
					levelUp.Text = "¡NIVEL " .. newLevel .. "!"
					levelUp.Visible = true
					levelUp.TextTransparency = 0
					Transition.Pop(levelUp, 1.6, 0.25)
					task.delay(1.1, function()
						if Anim.Alive(token) then
							Transition.Tween(levelUp, 0.3, { TextTransparency = 1 })
						end
					end)
					task.wait(0.45)
				end
				local _ = i
			end
		end)
	end
	function api.Final()
		if info then
			levelNumber.Text = tostring(info.EndLevel)
			title.Text = "NIVEL " .. info.EndLevel
			bar:Set(info.Steps[#info.Steps].To, false)
			amount.Text = string.format("%d / %d XP", info.EndXP, info.PerLevel)
		end
	end
	function api.Layout(phone)
		root.Size = UDim2.fromOffset(phone and 300 or 380, phone and 78 or 96)
		badge.Size = UDim2.fromOffset(phone and 54 or 68, phone and 54 or 68)
		badge.Position = UDim2.fromOffset(phone and 8 or 12, phone and 12 or 14)
	end
	local _ = DARK
	return api
end

return XPProgress
