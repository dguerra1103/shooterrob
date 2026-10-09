-- shared/InputMode (Fase 15, captura del Galaxy S26 Ultra): un teléfono Android que dice tener teclado
-- (KeyboardEnabled = true) sigue siendo un teléfono: HUD táctil, sin ranuras de armas ni «PASE · TIENDA».
-- (Lune no tiene Enum.PreferredInput: aquí se prueba el criterio de respaldo, sin ratón = táctil.)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local UIS = game:GetService("UserInputService")
local InputMode = req(RS.Shared.InputMode)

UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled = false, true, true
check(InputMode.TouchUI() == false, "ordenador (teclado y ratón): interfaz de ordenador")
UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled = true, false, false
check(InputMode.TouchUI() == true, "teléfono normal: táctil")
UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled = true, true, false
check(InputMode.TouchUI() == true, "teléfono que dice tener teclado (S26 Ultra): táctil")
UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled = true, true, true
check(InputMode.TouchUI() == false, "portátil con pantalla táctil, teclado y ratón: ordenador")

-- El HUD entero con los datos del S26 Ultra (táctil + «teclado», sin ratón, 892×412)
UIS.TouchEnabled, UIS.KeyboardEnabled, UIS.MouseEnabled = true, true, false
local Players = game:GetService("Players")
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId = "Yo", "Yo", 1
me.Parent = Players
table.insert(mock.players, me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(892, 412)
RS:SetAttribute("State", "Playing"); RS:SetAttribute("TeamMode", true)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.Data = { Level = 3, XP = 10, XPPerLevel = 1000, Coins = 500 }
ClientState.InMainMenu = false
local UI = req(game.StarterPlayer.Client.Modules.UI)
check(UI.IsPhone(), "UI.IsPhone: teléfono")
req(game.StarterPlayer.Client.Modules.RewardFX).Init()
local HUD = req(game.StarterPlayer.Client.Modules.HUD)
local ok, err = pcall(HUD.Init)
check(ok, "HUD.Init sin errores " .. tostring(err))
local hud = pg:FindFirstChild("HUD")
local slotsHidden, touchAmmo = false, false
for _, d in hud:GetDescendants() do
	if d.__className == "Frame" and d.Visible == false and d.Size and d.Size.X.Offset == 230 and d.Size.Y.Offset == 196 then slotsHidden = true end
	if d.Name == "TouchAmmo" then touchAmmo = true end
end
check(slotsHidden, "sin las ranuras de armas de ordenador")
check(touchAmmo, "munición compacta del HUD táctil")
local TL = req(game.StarterPlayer.Client.Modules.TouchLayout)
TL.BindAction("Fire", function() return nil end, true)
check(TL.GetButton("Fire") ~= nil, "con botones táctiles propios")
local _, class = TL.GetLayout()
check(class == "ULTRAWIDE_PHONE", "892×412: ULTRAWIDE_PHONE (" .. tostring(class) .. ")")
print("INPUTMODE OK")
process.exit(0)
