-- Contador del evento de temporada (debajo del botón de regalos): caramelos recogidos hacia el
-- siguiente premio (GameConfig.Event.Milestones y la skin final), con marcas en la barra.
-- Solo aparece si el servidor tiene un evento activo (atributo EventName).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local EventHUD = {}

function EventHUD.Init()
	local compact = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local gui = UI.new("ScreenGui", {
		Name = "EventHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local frame = UI.new("Frame", {
		-- En móvil: estrecho, debajo del regalo (a su derecha están los retos)
		Position = compact and UDim2.fromOffset(10, 174) or UDim2.new(0, 66, 0.38, 176),
		Size = compact and UDim2.fromOffset(52, 40) or UDim2.fromOffset(230, 34),
		BackgroundColor3 = Color3.fromRGB(60, 25, 80),
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, { UI.corner(10), UI.stroke(Color3.fromRGB(255, 140, 30), 2, 0.2) })
	local label = UI.label({
		Position = UDim2.fromOffset(2, 0),
		Size = UDim2.new(1, -4, 1, -4),
		Text = "",
		TextSize = 18,
		TextScaled = compact,
		TextWrapped = compact,
		Parent = frame,
	})
	local fill = UI.new("Frame", {
		Position = UDim2.new(0, 4, 1, -5),
		Size = UDim2.new(0, 0, 0, 3),
		BackgroundColor3 = Color3.fromRGB(255, 140, 30),
		BorderSizePixel = 0,
		Parent = frame,
	})
	local milestones = (GameConfig.Event and GameConfig.Event.Milestones) or {}
	local icon = GameConfig.Event and GameConfig.Event.Icon or "🎉"
	local itemIcon = GameConfig.Event and GameConfig.Event.ItemIcon or "⭐"
	local ticks = {}
	for _, milestone in milestones do
		table.insert(ticks, UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(2, 5),
			Position = UDim2.new(0, 0, 1, -6),
			BackgroundColor3 = Color3.fromRGB(255, 230, 150),
			BorderSizePixel = 0,
			Visible = not compact,
			Parent = frame,
		}))
	end
	-- Siguiente premio: caramelos que hacen falta y texto corto (si ya tienes el traje, son monedas)
	local function nextPrize(count, goal, data)
		for _, milestone in milestones do
			if count < milestone.Count and milestone.Count < goal then
				local outfit = milestone.Outfit and not (data.Outfits or {})[milestone.Outfit]
				local weapon = milestone.Weapon and not (data.OwnedWeapons or {})[milestone.Weapon]
				return milestone.Count, (outfit and "Traje") or (weapon and "Arma") or ((milestone.Coins or milestone.Compensate or 0) .. " 🪙")
			end
		end
		return goal, "Skin"
	end
	task.spawn(function()
		while true do
			local name = ReplicatedStorage:GetAttribute("EventName")
			local goal = ReplicatedStorage:GetAttribute("EventGoal") or 100
			local data = ClientState.Data
			gui.Enabled = name ~= nil and data ~= nil and not ClientState.InMainMenu
			if gui.Enabled then
				local count = data.EventCandy or 0
				if count >= goal then
					label.Text = compact and (icon .. "\n✔") or (icon .. " ¡Skin del evento conseguida!")
				else
					local target, prize = nextPrize(count, goal, data)
					label.Text = compact and (itemIcon .. "\n" .. count .. "/" .. target)
						or (icon .. " " .. itemIcon .. " " .. count .. "/" .. target .. "  → " .. prize)
				end
				fill.Size = UDim2.new(math.clamp(count / goal, 0, 1), -8, 0, 3)
				for i, tick in ticks do
					local at = milestones[i].Count / goal
					tick.Visible = not compact and at < 1
					tick.Position = UDim2.new(at, 4 - 8 * at, 1, -6)
					tick.BackgroundColor3 = count >= milestones[i].Count and Color3.fromRGB(255, 140, 30)
						or Color3.fromRGB(255, 230, 150)
				end
			end
			task.wait(0.5)
		end
	end)
end

return EventHUD
