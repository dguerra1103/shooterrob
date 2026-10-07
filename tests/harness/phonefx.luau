-- El HUD usa los efectos de recompensa: bajas seguidas, XP, subir de nivel y próximo premio
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId = "Yo", "Yo", 1
me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(844, 390)
local UIS = game:GetService("UserInputService")
UIS.TouchEnabled = true
UIS.KeyboardEnabled = false
RS:SetAttribute("State", "Playing"); RS:SetAttribute("TeamMode", true)
local Remotes = req(RS.Shared.Remotes)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.Data = { Level = 3, XP = 10, XPPerLevel = 1000, Coins = 500 }
ClientState.InMainMenu = false
local RewardFX = req(game.StarterPlayer.Client.Modules.RewardFX)
RewardFX.Init()
local HUD = req(game.StarterPlayer.Client.Modules.HUD)
local ok, err = pcall(HUD.Init)
check(ok, "HUD.Init en el móvil sin errores " .. tostring(err))
check(RewardFX.IsPhone(), "se detecta el teléfono")
local hud = pg:FindFirstChild("HUD")
local banner
for _, d in hud:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "¡DOBLE BAJA!" then banner = d end
end
local red = roblox.Color3.new(1, 0, 0)
Remotes.KillFeed.OnClientEvent:Fire({ Killer = "Yo", KillerColor = red, VictimColor = red, Victim = "Bot A", Weapon = "X" })
Remotes.KillFeed.OnClientEvent:Fire({ Killer = "Yo", KillerColor = red, VictimColor = red, Victim = "Bot B", Weapon = "X" })
for _, d in hud:GetDescendants() do
	if d.__className == "TextLabel" and d.Text == "¡DOBLE BAJA!" then banner = d end
end
local frame = banner and banner.Parent
check(frame and frame.Position.Y.Scale < 0.5, "el aviso de baja va por encima de la mira (no tapa los botones)")
local scale = frame:FindFirstChildOfClass("UIScale")
check(scale and scale.Scale < 1, "y más pequeño")
for i = 1, 4 do Remotes.Notify.OnClientEvent:Fire("XP", "+" .. (i * 10) .. " XP  Prueba") end
local popups = 0
for _, d in hud:GetDescendants() do
	if d.__className == "TextLabel" and type(d.Text) == "string" and string.find(d.Text, "XP  Prueba", 1, true) then popups += 1 end
end
check(popups <= 2, "como mucho 2 avisos de XP a la vez (" .. popups .. ")")
local fx = pg:FindFirstChild("RewardFX")
local holder = RewardFX.Celebrate("¡UN TÍTULO MUY LARGO PARA UN MÓVIL!", "sub", nil, false)
local title
for _, d in holder:GetDescendants() do if d.__className == "TextLabel" and d.Text == "¡UN TÍTULO MUY LARGO PARA UN MÓVIL!" then title = d end end
check(title and title.TextScaled and title.Size.X.Scale > 0 and title.Position.Y.Scale < 0.3, "las celebraciones caben y van más arriba en el móvil")
-- Disposición del teléfono: sin las ranuras de armas a la derecha (ahí van los botones), vida en el
-- centro, minimapa pequeño bajo los botones de Roblox y sin el panel de retos
local healthText
for _, d in hud:GetDescendants() do if d.__className == "TextLabel" and d.Text == "100" then healthText = d end end
check(healthText and healthText.Parent.Position.X.Scale == 0.5, "la vida va abajo en el centro (no encima del joystick)")
local slotsHidden = false
for _, d in hud:GetDescendants() do
	if d.__className == "Frame" and d.Visible == false and d.Size and d.Size.X.Offset == 230 and d.Size.Y.Offset == 196 then slotsHidden = true end
end
check(slotsHidden, "las ranuras de armas no tapan los botones táctiles")
local Minimap = req(game.StarterPlayer.Client.Modules.Minimap)
Minimap.Init()
local mm = pg:FindFirstChild("Minimap")
local mmFrame
for _, c in mm:GetChildren() do if c.__className == "Frame" then mmFrame = c end end
check(mmFrame.Position.Y.Offset >= 50 and mmFrame.Size.X.Offset <= 100, "minimapa pequeño y debajo de los botones de Roblox (" .. mmFrame.Position.Y.Offset .. ", " .. mmFrame.Size.X.Offset .. ")")
local QT = req(game.StarterPlayer.Client.Modules.QuestTracker)
QT.Init()
game:GetService("RunService").Heartbeat:Fire(1 / 60)
check(pg:FindFirstChild("QuestTracker").Enabled == false, "sin el panel de retos en el teléfono")
-- Botones táctiles del teléfono: ninguno pisa a otro ni al botón de saltar de Roblox
local TL = req(game.StarterPlayer.Client.Modules.TouchLayout)
local W, H = 830, 380
local rects = { { "Saltar", W - 95, H - 90, 70 } }
for name, spot in TL.Phone do
	local pos, size = spot[1], spot[2]
	local x = pos.X.Scale * W + pos.X.Offset
	local y = pos.Y.Scale * H + pos.Y.Offset
	check(x >= 0 and y >= 0 and x + size <= W and y + size <= H, name .. " dentro de la pantalla")
	table.insert(rects, { name, x, y, size })
end
for i = 1, #rects do
	for j = i + 1, #rects do
		local a, b = rects[i], rects[j]
		local overlap = a[2] < b[2] + b[4] and b[2] < a[2] + a[4] and a[3] < b[3] + b[4] and b[3] < a[3] + a[4]
		if overlap then check(false, a[1] .. " pisa a " .. b[1]) end
	end
end
check(true, "ningún botón táctil pisa a otro (" .. #rects .. " botones)")
print("MOVIL OK")
process.exit(0)
