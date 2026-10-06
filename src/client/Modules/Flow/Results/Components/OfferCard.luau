-- Oferta pequeña de después de la partida: "DOMINASTE CON PHANTOM-X · 9 BAJAS" y una skin que no
-- tienes para esa arma, con VER (la previsualización 3D) y ✕. Sale de vez en cuando (ver
-- MonetizationConfig.PostMatchOffer), entra suave por la derecha y se quita con un toque. Nada de
-- relojes ni de "última oportunidad".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage:WaitForChild("Shared").Weapons)

local Flow = script.Parent.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local ItemArt = require(Flow.Store.ItemArt)
local ItemCard = require(Flow.Store.ItemCard)

local Colors = Theme.Colors

local OfferCard = {}
OfferCard.Current = nil :: any -- (la oferta que se ve)

-- callbacks = { OnView(offer), OnClose() }
function OfferCard.new(parent, callbacks)
	local root = C.panel({ Name = "OfferCard", Size = UDim2.fromOffset(330, 84), Parent = parent }, { Alpha = 0.12, StrokeColor = Colors.Yellow, StrokeAlpha = 0.6 })
	root.Visible = false
	local holder = C.new("Frame", { Name = "Thumb", BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(96, 68), Parent = root })
	local title = C.text({ Name = "OfferTitle", Text = "", Role = "TitleItalic", TextSize = 16, Color = Colors.YellowText, Scaled = true, Position = UDim2.fromOffset(112, 8), Size = UDim2.new(1, -150, 0, 20), Parent = root })
	local sub = C.text({ Name = "OfferSub", Text = "", Role = "Body", TextSize = 12, Color = Colors.Text, Scaled = true, Position = UDim2.fromOffset(112, 30), Size = UDim2.new(1, -150, 0, 16), Parent = root })
	local view = C.button({ Name = "View", Text = "VER", Icon = "👁", Style = "Ghost", TextSize = 14, Position = UDim2.fromOffset(112, 50), Size = UDim2.fromOffset(110, 28), Parent = root, OnClick = function()
		if root:GetAttribute("Shown") then
			callbacks.OnView(OfferCard.Current)
		end
	end })
	local _ = view
	C.button({ Name = "Close", Text = "✕", Style = "Ghost", TextSize = 16, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(32, 32), Parent = root, Sound = "Back", OnClick = function()
		root.Visible = false
		if callbacks.OnClose then
			callbacks.OnClose()
		end
	end })
	local api = { Frame = root }
	function api.Show(offer)
		OfferCard.Current = offer
		for _, child in holder:GetChildren() do
			child:Destroy()
		end
		if not offer then
			root.Visible = false
			root:SetAttribute("Shown", nil)
			return
		end
		local weapon = Weapons.Get(offer.Weapon)
		local weaponName = weapon and weapon.DisplayName or tostring(offer.Weapon)
		ItemArt.Backdrop(holder, offer.Item.Rarity, { Size = UDim2.fromScale(1, 1) })
		ItemArt.Weapon(holder, offer.Weapon, offer.Item.Id, { Size = UDim2.fromScale(0.94, 0.9), Position = UDim2.fromScale(0.03, 0.05), ZIndex = 2 })
		title.Text = "DOMINASTE CON " .. C.upper(weaponName)
		sub.Text = offer.Kills .. " bajas · " .. offer.Item.Name .. " · " .. ItemCard.PriceText(offer.Item)
		root.Visible = true
		root:SetAttribute("Shown", true)
		Transition.SlideIn(root, Vector2.new(60, 0), 0.3)
	end
	function api.Layout(phone)
		root.Size = UDim2.fromOffset(phone and 300 or 330, phone and 76 or 84)
	end
	return api
end

return OfferCard
