-- Contador del evento de temporada (debajo del botón de regalos): caramelos recogidos hacia el
-- siguiente premio (GameConfig.Event.Milestones y la skin final), con marcas en la barra.
-- Solo aparece si el servidor tiene un evento activo (atributo EventName).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local EventHUD = {}

function EventHUD.Init()
	local compact = InputMode.TouchUI()
	local gui = UI.new("ScreenGui", {
		Name = "EventHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	UI.WaitViewport()
	local phone = UI.IsPhone()
	local frame = UI.new("Frame", {
		-- En móvil: estrecho, debajo del regalo (teléfono: los dos a la derecha del minimapa)
		Position = compact and UDim2.fromOffset(14 + (phone and 96 or 160) + 6, UI.TopbarBottom() + (phone and 60 or 70))
			or UDim2.new(0, 66, 0.38, 176),
		Size = phone and UDim2.fromOffset(44, 34) or (compact and UDim2.fromOffset(52, 40) or UDim2.fromOffset(230, 34)),
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
	-- (el evento lo dice el servidor: atributo EventId; se mira cada vez por si cambia)
	local milestones, icon, itemIcon = {}, "🎉", "⭐"
	local function syncEvent()
		local event = GameConfig.CurrentEvent()
		milestones = (event and event.Milestones) or {}
		icon = event and event.Icon or "🎉"
		itemIcon = event and event.ItemIcon or "⭐"
	end
	syncEvent()
	local ticks = {}
	for _ = 1, 4 do -- (marcas de los premios por el camino; las que sobran se ocultan)
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
	-- (mientras se juega solo sale un rato: al aparecer y cuando sumas; HUD de combate limpio)
	local shownUntil, lastCount = 0, nil
	Players.LocalPlayer.CharacterAdded:Connect(function()
		shownUntil = os.clock() + 6
	end)
	task.spawn(function()
		while true do
			syncEvent()
			local name = ReplicatedStorage:GetAttribute("EventName")
			local goal = ReplicatedStorage:GetAttribute("EventGoal") or 100
			local data = ClientState.Data
			local candy = data and data.EventCandy or 0
			-- (solo con los datos ya cargados: al cargar no cuenta como «has sumado»)
			if data and candy ~= lastCount then
				if lastCount ~= nil then
					shownUntil = os.clock() + 5
				end
				lastCount = candy
			end
			gui.Enabled = name ~= nil and data ~= nil and not ClientState.InMainMenu
				and (ReplicatedStorage:GetAttribute("State") ~= "Playing" or os.clock() < shownUntil)
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
					local milestone = milestones[i]
					if not milestone then
						tick.Visible = false
						continue
					end
					local at = milestone.Count / goal
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
