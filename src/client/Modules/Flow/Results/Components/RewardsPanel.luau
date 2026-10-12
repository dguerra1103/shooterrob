-- RECOMPENSAS: lo que el servidor ha dado de verdad en esta partida (MatchSummary): XP, monedas (las
-- de jugar más retos, pase y maestría) y cajas; y el rango (+RP / −RP) porque todas las partidas
-- cuentan para el rango. Cada premio entra con un salto, su contador y su sonido. Sin premios: no sale.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ranks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ranks"))

local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local UISound = require(Flow.UISound)
local Anim = require(script.Parent.Parent.Anim)
local IconText = require(Flow.Parent.IconText)

local Colors = Theme.Colors
local DARK = Color3.fromRGB(16, 14, 8)

local RewardsPanel = {}

-- Icono hecho con piezas (sin imágenes): rombo amarillo "XP", moneda redonda, caja
local function icon(parent, kind)
	local holder = C.new("Frame", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 40), Parent = parent })
	if kind == "XP" then
		local diamond = C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), Rotation = 45, Parent = holder }, {
			C.corner(5),
			C.new("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(255, 236, 120), Colors.YellowDark) }),
			C.stroke(Color3.fromRGB(120, 80, 0), 1.5, 0.2),
		})
		local _ = diamond
		C.text({ Text = "XP", Role = "TitleItalic", TextSize = 15, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = holder })
	elseif kind == "Coins" then
		C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Parent = holder }, {
			C.corner(17),
			C.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 232, 110), Color3.fromRGB(214, 140, 0)) }),
			C.stroke(Color3.fromRGB(140, 90, 0), 2, 0.1),
		})
		C.text({ Text = "💰", TextSize = 18, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = holder })
	elseif kind == "Pass" then
		-- Medalla del pase: escudo dorado
		C.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 200, 60), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(30, 34), Parent = holder }, {
			C.corner(6),
			C.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(200, 120, 0)) }),
			C.stroke(Color3.fromRGB(120, 70, 0), 1.5, 0.2),
		})
		C.text({ Text = "★", Role = "Title", TextSize = 18, Color = DARK, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = holder })
	else
		C.new("Frame", { BackgroundColor3 = Color3.fromRGB(110, 70, 40), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(34, 26), Parent = holder }, {
			C.corner(3),
			C.stroke(Colors.Yellow, 1.5, 0.3),
			C.new("Frame", { BackgroundColor3 = Colors.Yellow, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 6, 1, 0) }),
		})
	end
	return holder
end

function RewardsPanel.new(parent)
	local root = C.panel({ Name = "RewardsPanel", Size = UDim2.fromOffset(460, 112), Parent = parent }, { Alpha = 0.16, StrokeColor = Colors.Yellow, StrokeAlpha = 0.45 })
	C.text({ Name = "Title", Text = "RECOMPENSAS", Role = "TitleItalic", TextSize = 17, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(200, 22), Parent = root })
	local rankLabel = C.text({ Name = "Rank", Text = "", Role = "Title", TextSize = 14, Rich = true, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.fromOffset(220, 20), Parent = root })
	IconText.BindRank(rankLabel) -- (el emoji del rango pasa a ser su emblema)
	local row = C.new("Frame", { Name = "Items", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -20, 0, 70), Parent = root }, {
		C.list(8, Enum.FillDirection.Horizontal),
	})
	local items = {}
	local api = { Frame = root }

	function api.Set(rewards, summary)
		for _, item in items do
			item.Frame:Destroy()
		end
		table.clear(items)
		for i, reward in rewards or {} do
			local cell = C.new("Frame", { Name = "Reward_" .. reward.Kind, BackgroundColor3 = Colors.PanelLight, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.new(1 / math.max(3, #(rewards or {})), -6, 1, 0), LayoutOrder = i, Visible = false, Parent = row }, { C.corner(4) })
			local ic = icon(cell, reward.Kind)
			ic.Position = UDim2.fromOffset(8, 15)
			local amount = C.text({ Name = "Amount", Text = "+0", Role = "TitleItalic", TextSize = 24, Color = Colors.White, Position = UDim2.fromOffset(52, 8), Size = UDim2.new(1, -56, 0, 30), Scaled = true, Parent = cell })
			C.text({ Name = "Label", Text = reward.Label, Role = "Title", TextSize = 11, Color = Colors.TextDim, Position = UDim2.fromOffset(52, 38), Size = UDim2.new(1, -56, 0, 16), Scaled = true, Parent = cell })
			table.insert(items, { Frame = cell, Amount = amount, Reward = reward })
		end
		local startRank = summary and tonumber(summary.StartRank)
		local endRank = summary and tonumber(summary.RankPoints)
		rankLabel.Text = ""
		-- (solo si la partida ha movido el rango: +RP al ganar, −RP al perder)
		if startRank and endRank and endRank ~= startRank then
			local tier = Ranks.Get(endRank)
			local delta = endRank - startRank
			local deltaText = delta > 0 and ('<font color="#6EE06E">+' .. delta .. " RP</font>") or (delta < 0 and ('<font color="#FF7A7A">' .. delta .. " RP</font>") or "")
			rankLabel.Text = string.format('%s <font color="#%s">%s</font>  %s', tier.Icon, tier.Color:ToHex(), C.upper(tier.Name), deltaText)
		end
		root.Visible = #items > 0 or rankLabel.Text ~= ""
	end

	-- Uno tras otro: salto, contador y sonido
	function api.Play(token)
		for i, item in items do
			task.delay((i - 1) * 0.22, function()
				if not Anim.Alive(token) then
					return
				end
				Anim.Pop(item.Frame, 0.6, 0.22)
				UISound.Play("RewardPop", 1 + i * 0.08)
				Anim.Glow(item.Frame, Colors.Yellow, 0.35, 0.4)
				local format = item.Reward.Kind == "Crate" and "+%d" or "+%d"
				Anim.Count(item.Amount, 0, item.Reward.Amount, 0.6, format, token, "Tick")
			end)
		end
	end
	function api.Final()
		for _, item in items do
			item.Frame.Visible = true
			item.Amount.Text = "+" .. tostring(item.Reward.Amount)
		end
	end
	function api.Layout(phone)
		root.Size = UDim2.fromOffset(phone and 360 or 460, phone and 92 or 112)
		row.Size = UDim2.new(1, -20, 0, phone and 52 or 70)
	end
	return api
end

return RewardsPanel
