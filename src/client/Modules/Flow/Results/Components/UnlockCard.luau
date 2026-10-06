-- DESBLOQUEO: solo si en esta partida se ha conseguido algo (arma por nivel, camuflaje de maestría,
-- skin/traje/efecto del pase). El arma o el camuflaje se ven en 3D; lo demás, con su icono. Entra
-- con un brillo que cruza y su sonido.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script.Parent.Parent.Parent.Parent
local WeaponIcon = require(Modules.WeaponIcon)

local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local UISound = require(Flow.UISound)
local Anim = require(script.Parent.Parent.Anim)

local Colors = Theme.Colors

local UnlockCard = {}

local ICONS = { Skin = "🎨", Outfit = "🧥", KillEffect = "✨", Crate = "📦" }

function UnlockCard.new(parent)
	local root = C.panel({ Name = "UnlockCard", Size = UDim2.fromOffset(380, 96), Parent = parent }, { Alpha = 0.16, StrokeColor = Colors.Yellow, StrokeAlpha = 0.55 })
	local head = C.text({ Name = "Head", Text = "DESBLOQUEO", Role = "TitleItalic", TextSize = 16, Color = Colors.YellowText, Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(200, 20), Parent = root })
	local more = C.text({ Name = "More", Text = "", Role = "Title", TextSize = 12, Color = Colors.TextDim, AlignX = Enum.TextXAlignment.Right, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(120, 18), Parent = root })
	local art = C.new("Frame", { Name = "Art", BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 26), Size = UDim2.new(0.48, -8, 1, -30), Parent = root })
	local name = C.text({ Name = "UnlockName", Text = "", Role = "TitleItalic", TextSize = 24, Scaled = true, Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.new(0.5, -12, 0, 30), Parent = root })
	local sub = C.text({ Name = "Sub", Text = "", Role = "Title", TextSize = 12, Color = Colors.TextDim, Wrap = true, Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.new(0.5, -12, 0, 30), Parent = root })
	local api = { Frame = root }
	function api.Set(unlocks)
		local first = unlocks and unlocks[1]
		root.Visible = first ~= nil
		if not first then
			return
		end
		art:ClearAllChildren()
		name.Text = C.upper(tostring(first.Name or ""))
		sub.Text = tostring(first.Sub or "")
		more.Text = #unlocks > 1 and ("+" .. (#unlocks - 1) .. " MÁS") or ""
		head.Text = #unlocks > 1 and "DESBLOQUEOS" or "DESBLOQUEO"
		if (first.Kind == "Weapon" or first.Kind == "Camo") and first.Id then
			pcall(WeaponIcon.Create, first.Id, first.Skin, { Name = "Weapon3D", Size = UDim2.fromScale(1, 1), Parent = art }, "angled", 2.2)
		else
			C.text({ Text = ICONS[first.Kind] or "🔓", TextSize = 40, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = art })
		end
	end
	function api.Play(token)
		if not root.Visible then
			return
		end
		Anim.Pop(root, 0.85, 0.25)
		UISound.Play("Unlock")
		task.delay(0.1, function()
			if Anim.Alive(token) then
				Anim.Sheen(root, 0.7)
			end
		end)
	end
	local _ = ReplicatedStorage
	return api
end

return UnlockCard
