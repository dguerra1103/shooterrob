-- Potenciadores activos (Shop.Boosters): "⚡ x2 XP 23:10" arriba en el centro, debajo del marcador.
-- El servidor manda los segundos que quedan; aquí se cuentan hacia atrás solo mientras se juega
-- (igual que en el servidor) y se corrigen con cada actualización de datos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputMode = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InputMode"))

local Shop = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Shop"))
local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)
local HUDZones = require(script.Parent.HUDZones)

local player = Players.LocalPlayer

local BoostHUD = {}

local left = {} -- [Field] = segundos que quedan
local label

local function format(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function render()
	local parts = {}
	for _, booster in Shop.Boosters do
		local seconds = left[booster.Field] or 0
		if seconds > 0 then
			table.insert(parts, booster.Icon .. " x" .. booster.Multiplier .. (booster.Kind == "XP" and " XP " or " ") .. format(seconds))
		end
	end
	label.Text = table.concat(parts, "   ")
	label.Visible = #parts > 0 and not ClientState.InMainMenu and not ClientState.MenuOpen
		-- (táctil, Fase 16: en plena pelea no; se ve al morir, en el calentamiento y en los menús)
		and not (InputMode.TouchUI() and HUDZones.Fighting())
end

function BoostHUD.Init()
	local gui = UI.new("ScreenGui", {
		Name = "Boosters",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = player:WaitForChild("PlayerGui"),
	})
	label = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140), -- (debajo de la fila de jugadores del marcador)
		Size = UDim2.fromOffset(320, 22),
		Text = "",
		TextSize = 17,
		TextColor3 = Color3.fromRGB(120, 230, 255),
		Visible = false,
		Parent = gui,
	})
	local function onData(data)
		if not data then
			return
		end
		for _, booster in Shop.Boosters do
			-- (el servidor descuenta de 5 en 5 s: solo se corrige si se ha ido más que eso, para que
			-- el reloj no salte hacia arriba con cada baja)
			local server = tonumber(data[booster.Field]) or 0
			local mine = left[booster.Field]
			if not mine or math.abs(server - mine) > 6 or server == 0 then
				left[booster.Field] = server
			end
		end
		render()
	end
	ClientState.DataChanged.Event:Connect(onData)
	onData(ClientState.Data)
	task.spawn(function()
		while true do
			task.wait(1)
			if not ClientState.InMainMenu then
				for field, seconds in left do
					left[field] = math.max(0, seconds - 1)
				end
			end
			render()
		end
	end)
end

return BoostHUD
