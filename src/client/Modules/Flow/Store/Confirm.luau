-- Confirmar una compra con monedas: qué compras, cuánto cuesta y cuánto te queda. CANCELAR a la
-- izquierda y CONFIRMAR a la derecha (nunca en el mismo sitio que el botón que la abrió, así un
-- doble toque no compra sin querer). Si no te llega, lo dice y no deja confirmar.
-- (Las compras con Robux usan la ventana de confirmación de Roblox, no esta.)
local UserInputService = game:GetService("UserInputService")

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)
local ClientState = require(Flow.Parent.ClientState)
local ItemArt = require(script.Parent.ItemArt)

local Colors = Theme.Colors

local Confirm = {}

local modal, connection

function Confirm.Close()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	if modal then
		modal:Destroy()
		modal = nil
	end
end

function Confirm.IsOpen()
	return modal ~= nil
end

-- onConfirm(): la compra de verdad; onCoins(): ir a MONEDAS (si no le llega)
function Confirm.Open(root, item, onConfirm, onCoins)
	Confirm.Close()
	local data = ClientState.Data
	local coins = data and data.Coins or 0
	local price = item.Coins or 0
	local enough = coins >= price
	modal = C.new("TextButton", { Name = "Confirm", Text = "", AutoButtonColor = false, BackgroundColor3 = Colors.Black, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 30, Parent = root })
	local box = C.panel({ Name = "Box", Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 300), Parent = modal }, { Alpha = 0.02, StrokeColor = Colors.Yellow, StrokeAlpha = 0.5 })
	C.text({ Text = "CONFIRMAR COMPRA", Role = "TitleItalic", TextSize = 26, Color = Colors.YellowText, AlignX = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 32), Parent = box })
	ItemArt.Thumb(box, item, { Position = UDim2.fromOffset(20, 56), Size = UDim2.fromOffset(150, 130) })
	C.text({ Text = C.upper(item.Name), Role = "TitleItalic", TextSize = 24, Scaled = true, Position = UDim2.fromOffset(184, 60), Size = UDim2.new(1, -200, 0, 30), Parent = box })
	C.text({ Text = C.upper(item.Rarity) .. "  ·  " .. (item.Label or ""), Role = "Title", TextSize = 13, Color = ItemArt.RarityColor(item.Rarity), Scaled = true, Position = UDim2.fromOffset(184, 92), Size = UDim2.new(1, -200, 0, 16), Parent = box })
	C.text({ Name = "Price", Text = "🪙 " .. price, Role = "Number", TextSize = 30, Color = Colors.YellowText, Position = UDim2.fromOffset(184, 114), Size = UDim2.new(1, -200, 0, 36), Parent = box })
	C.text({
		Name = "Balance",
		Text = enough and string.format("Tienes %d 🪙 · te quedarán %d 🪙", coins, coins - price) or string.format("Te faltan %d 🪙", price - coins),
		Role = "Body",
		TextSize = 13,
		Color = enough and Colors.TextDim or Colors.Red,
		Wrap = true,
		Position = UDim2.fromOffset(184, 152),
		Size = UDim2.new(1, -200, 0, 34),
		Parent = box,
	})
	C.button({ Name = "Cancel", Text = "CANCELAR", Style = "Ghost", TextSize = 18, Position = UDim2.new(0, 20, 1, -70), Size = UDim2.new(0.5, -26, 0, 52), Parent = box, Sound = "Back", OnClick = Confirm.Close })
	if enough then
		C.button({ Name = "Accept", Text = "CONFIRMAR", Icon = "🪙", Style = "Primary", TextSize = 20, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -20, 1, -70), Size = UDim2.new(0.5, -26, 0, 52), Parent = box, Sound = "Click", OnClick = function()
			Confirm.Close()
			onConfirm()
		end })
	else
		C.button({ Name = "GetCoins", Text = "CONSEGUIR MONEDAS", Style = "Ghost", TextSize = 16, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -20, 1, -70), Size = UDim2.new(0.5, -26, 0, 52), Parent = box, OnClick = function()
			Confirm.Close()
			if onCoins then
				onCoins()
			end
		end })
	end
	modal.Activated:Connect(function()
		UISound.Play("Back")
		Confirm.Close()
	end)
	connection = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
			Confirm.Close()
		end
	end)
	Transition.Pop(box, 0.9, 0.18)
	return modal
end

return Confirm
