-- DESAFÍOS COMPLETADOS en esta partida (diarios y semanales), con su ✓ animado uno tras otro.
-- Sin desafíos completados no ocupa sitio (el panel no sale).
local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local Anim = require(script.Parent.Parent.Anim)

local Colors = Theme.Colors

local ChallengeProgress = {}

function ChallengeProgress.new(parent)
	local root = C.panel({ Name = "ChallengeProgress", Size = UDim2.fromOffset(380, 96), Parent = parent }, { Alpha = 0.16 })
	C.text({ Name = "Head", Text = "DESAFÍOS COMPLETADOS", Role = "TitleItalic", TextSize = 16, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(300, 20), Parent = root })
	local list = C.new("Frame", { Name = "List", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 1, -34), Parent = root }, { C.list(2) })
	local rows = {}
	local api = { Frame = root }
	function api.Set(challenges)
		for _, row in rows do
			row.Frame:Destroy()
		end
		table.clear(rows)
		root.Visible = challenges ~= nil and #challenges > 0
		for i, challenge in challenges or {} do
			if i > 3 then
				break
			end
			local row = C.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = i, Parent = list })
			local box = C.new("Frame", { BackgroundColor3 = Colors.Green, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(16, 16), Parent = row }, { C.corner(3) })
			local check = C.text({ Text = "✓", Role = "Title", TextSize = 13, Color = Colors.White, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = box })
			C.text({ Text = (challenge.Weekly and "SEMANAL · " or "") .. tostring(challenge.Text or ""), Role = "BodyBold", TextSize = 13, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -90, 1, 0), Parent = row })
			C.text({ Text = string.format("%d/%d", challenge.Goal or 1, challenge.Goal or 1), Role = "Number", TextSize = 14, Color = Colors.Green, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(60, 20), Parent = row })
			check.TextTransparency = 1
			box.BackgroundTransparency = 1
			table.insert(rows, { Frame = row, Box = box, Check = check })
		end
	end
	function api.Play(token)
		for i, row in rows do
			task.delay((i - 1) * 0.25, function()
				if not Anim.Alive(token) then
					return
				end
				Transition.Tween(row.Box, 0.15, { BackgroundTransparency = 0 })
				Transition.Tween(row.Check, 0.15, { TextTransparency = 0 })
				Transition.Pop(row.Box, 1.6, 0.25)
				UISound.Play("Tick", 1.4 + i * 0.1)
			end)
		end
	end
	function api.Final()
		for _, row in rows do
			row.Box.BackgroundTransparency = 0
			row.Check.TextTransparency = 0
		end
	end
	return api
end

return ChallengeProgress
