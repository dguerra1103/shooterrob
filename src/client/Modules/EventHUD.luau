-- Contador del evento de temporada (debajo del botón de regalos): caramelos recogidos / objetivo.
-- Solo aparece si el servidor tiene un evento activo (atributo EventName).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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
	task.spawn(function()
		while true do
			local name = ReplicatedStorage:GetAttribute("EventName")
			local goal = ReplicatedStorage:GetAttribute("EventGoal") or 100
			local data = ClientState.Data
			gui.Enabled = name ~= nil and data ~= nil and not ClientState.InMainMenu
			if gui.Enabled then
				local count = data.EventCandy or 0
				if count >= goal then
					label.Text = compact and "🎃\n✔" or "🎃 ¡Skin del evento conseguida!"
				else
					label.Text = compact and ("🍬\n" .. count .. "/" .. goal) or ("🎃 " .. string.upper(name) .. "  🍬 " .. count .. "/" .. goal)
				end
				fill.Size = UDim2.new(math.clamp(count / goal, 0, 1), -8, 0, 3)
			end
			task.wait(0.5)
		end
	end)
end

return EventHUD
