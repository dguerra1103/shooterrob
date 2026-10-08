-- Controles táctiles (Fase 12): todos los botones existen una sola vez, con su jerarquía (disparar el
-- más grande), sin pisarse ni tapar el centro; apuntar se marca y lo secundario se apaga un poco;
-- recargar se resalta con el cargador vacío; los menús los esconden y sueltan el dedo; los ajustes
-- (correr, disparo izquierdo, disposición propia) se aplican. (Lógica y disposición: la comodidad
-- real con los pulgares solo se puede juzgar en un móvil.)
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
mock.policyInfo = { ArePaidRandomItemsRestricted = false }
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Vector2 = roblox.Vector2
local Enum = roblox.Enum
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local GameConfig = req(RS.Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = Teams
end
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player"); me.Name = "Jugador"; me.DisplayName = "Jugador"; me.UserId = 3; me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
data.TutorialDone = true
data.NewsSeen = GameConfig.News.Version
PlayerData.SendUpdate(me)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
me.Team = Teams:GetChildren()[1]
mock.invokePlayer = me
local W, H = 844, 390
game.Workspace.CurrentCamera.ViewportSize = Vector2.new(W, H)
local UIS = game:GetService("UserInputService")
UIS.TouchEnabled = true
UIS.KeyboardEnabled = false
RS:SetAttribute("TeamA", GameConfig.Teams[1].Name); RS:SetAttribute("TeamB", GameConfig.Teams[2].Name); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Mode", "TDM")
req(game.StarterPlayer.Client.Main)
task.wait(2)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local TL = req(game.StarterPlayer.Client.Modules.TouchLayout)
local MobileHUD = req(RS.Shared.MobileHUD)
local function heartbeat()
	TL.Tick()
end
-- (fuera de los menús, como en partida)
ClientState.InMainMenu = false
ClientState.MenuOpen = false
ClientState.Dead = false
TL.RefreshVisibility()

local gui = pg:FindFirstChild("TouchButtons")
check(gui ~= nil, "pantalla de botones táctiles propia")
local count = {}
for _, b in gui:GetChildren() do
	count[b.Name] = (count[b.Name] or 0) + 1
end
for _, control in MobileHUD.Controls do
	check(count[control.Id] == 1, "botón " .. control.Id .. " (uno solo)")
end
local entries = TL.Entries()

-- Jerarquía: disparar > apuntar > el resto
local layout, breakpoint = TL.GetLayout()
check(breakpoint == "PHONE", "844x390 es PHONE (" .. tostring(breakpoint) .. ")")
local fire, aim = layout.Fire, layout.Aim
check(fire.Size.X > aim.Size.X, "disparar es más grande que apuntar")
for id, info in layout do
	if id ~= "Fire" and id ~= "Aim" and id ~= "SwapWeapon" and id ~= "LeftFire" then
		check(info.Size.X < aim.Size.X, id .. " es más pequeño que apuntar")
	end
end
check(fire.Hit.X > fire.Size.X, "la zona de disparar es algo mayor que el dibujo")
check(#MobileHUD.Overlaps(layout, nil, 0) <= 1, "los controles no se pisan")
local center = Vector2.new(W, H) / 2
local clear = MobileHUD.CenterClear(Vector2.new(W, H))
for id, info in layout do
	check((info.Center - center).Magnitude - info.Size.X / 2 >= clear, id .. " fuera del centro libre")
end

-- Visibilidad por ajustes y estado
check(not entries.Sprint.Button.Visible, "correr: sin botón con «Auto» (por defecto)")
check(not entries.LeftFire.Button.Visible, "disparo izquierdo apagado por defecto")
check(not entries.Airstrike.Button.Visible, "ataque aéreo oculto sin cargas")
me:SetAttribute("Airstrikes", 1)
TL.RefreshVisibility()
check(entries.Airstrike.Button.Visible, "ataque aéreo visible con una carga")
local Settings = req(game.StarterPlayer.Client.Modules.Settings)
Settings.Set("LeftFire", 1)
Settings.Set("AutoSprint", 0)
task.wait(0.1)
check(entries.LeftFire.Button.Visible and entries.Sprint.Button.Visible, "ajustes: disparo izquierdo y botón de correr")
Settings.Set("LeftFire", 0)
Settings.Set("AutoSprint", 1)
task.wait(0.1)

-- Disparar arrastrando (por defecto): la zona de disparar no se come el toque (la cámara gira con
-- el mismo dedo) y el toque se detecta igualmente
check(entries.Fire.Button.ClassName == "Frame" and entries.Fire.Button.Active == false, "disparar deja pasar el toque a la cámara")
local fired = {}
mock.actions.Fire = mock.actions.Fire -- (la tecla sigue en ContextActionService)
local oldHandler = entries.Fire.Handler
entries.Fire.Handler = function(name, state)
	table.insert(fired, state)
end
local input = mock.new("InputObject")
input.UserInputType = Enum.UserInputType.Touch
input.UserInputState = Enum.UserInputState.Begin
input.Position = roblox.Vector3.new(fire.Center.X, fire.Center.Y, 0)
entries.Fire.Press(input)
task.wait(0.05)
check(fired[1] == Enum.UserInputState.Begin and entries.Fire.Pressed, "tocar disparar dispara")
-- Al abrirse un menú con el dedo encima: se suelta (no se queda disparando) y se esconden
ClientState.MenuOpen = true
TL.RefreshVisibility()
task.wait(0.05)
check(fired[2] == Enum.UserInputState.Cancel and not entries.Fire.Pressed, "con un menú, el disparo se suelta")
check(not entries.Fire.Button.Visible and not entries.Aim.Button.Visible, "con un menú, los controles se esconden")
ClientState.MenuOpen = false
TL.RefreshVisibility()
check(entries.Fire.Button.Visible, "al cerrar el menú vuelven")
entries.Fire.Handler = oldHandler

-- Dedos (Fase 13): un dedo falso que se puede soltar (el del simulador no avisa al cambiar)
local function fakeTouch(position)
	local listeners = {}
	local t = { UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin, Position = position or roblox.Vector3.new(0, 0, 0) }
	function t:GetPropertyChangedSignal()
		return {
			Connect = function(_, fn)
				table.insert(listeners, fn)
				return { Disconnect = function()
					local i = table.find(listeners, fn)
					if i then table.remove(listeners, i) end
				end }
			end,
		}
	end
	function t.Lift(state)
		t.UserInputState = state or Enum.UserInputState.End
		for _, fn in table.clone(listeners) do fn() end
	end
	return t
end
local log = {}
local reloadHandler = entries.Reload.Handler
entries.Reload.Handler = function(_, state) table.insert(log, state) end
-- Un botón es de un solo dedo: un segundo dedo encima no hace nada y soltarlo no suelta el primero
local f1, f2 = fakeTouch(), fakeTouch()
entries.Reload.Press(f1)
entries.Reload.Press(f2)
task.wait(0.05)
check(#log == 1 and entries.Reload.Pressed, "un segundo dedo sobre el mismo botón no lo vuelve a pulsar")
f2.Lift()
task.wait(0.05)
check(entries.Reload.Pressed and #log == 1, "soltar el segundo dedo no suelta el botón")
f1.Lift()
task.wait(0.05)
check(not entries.Reload.Pressed and log[2] == Enum.UserInputState.End, "soltar el dedo dueño lo suelta")
-- Se esconde con un dedo encima (menú): se suelta; al volver, un dedo nuevo lo pulsa y el viejo, al
-- levantarse, ya no puede soltar la pulsación nueva
table.clear(log)
local old, new = fakeTouch(), fakeTouch()
entries.Reload.Press(old)
ClientState.MenuOpen = true
TL.RefreshVisibility()
task.wait(0.05)
check(log[2] == Enum.UserInputState.Cancel and entries.Reload.Owner == nil, "con un menú el botón se suelta y el dedo deja de ser suyo")
ClientState.MenuOpen = false
TL.RefreshVisibility()
entries.Reload.Press(new)
old.Lift()
task.wait(0.05)
check(entries.Reload.Pressed and #log == 3, "el dedo viejo no suelta la pulsación nueva")
new.Lift()
task.wait(0.05)
check(not entries.Reload.Pressed, "el dedo nuevo sí")
entries.Reload.Handler = reloadHandler
-- Disparar + disparo izquierdo: el gatillo se suelta con el último dedo
Settings.Set("LeftFire", 1) -- (el botón izquierdo tiene que estar puesto)
task.wait(0.05)
local trigger = {}
TL.BindAction("Fire", function(_, state) table.insert(trigger, state) return nil end, true)
entries = TL.Entries()
local right, left = fakeTouch(), fakeTouch()
entries.Fire.Press(right)
entries.LeftFire.Press(left)
task.wait(0.05)
check(#trigger == 1 and trigger[1] == Enum.UserInputState.Begin, "dos botones de disparo: un solo inicio del gatillo")
right.Lift()
task.wait(0.05)
check(#trigger == 1, "soltar uno no corta el disparo del otro (" .. #trigger .. ": " .. tostring(trigger[2]) .. ")")
left.Lift()
task.wait(0.05)
check(#trigger == 2 and trigger[2] == Enum.UserInputState.End, "soltar el último suelta el gatillo")
Settings.Set("LeftFire", 0)
task.wait(0.05)

-- Apuntar: el botón se marca y lo secundario se apaga un poco (sigue visible y funcionando)
local grenadeBefore = entries.Grenade.Face.BackgroundTransparency
ClientState.Aiming = true
heartbeat()
check(entries.Aim.Active == true, "apuntando: el botón de apuntar se marca")
check(entries.Grenade.Face.BackgroundTransparency > grenadeBefore, "apuntando: la granada se apaga un poco")
check(entries.Grenade.Button.Visible, "apuntando: la granada sigue ahí")
ClientState.Aiming = false
heartbeat()
check(entries.Aim.Active == false and math.abs(entries.Grenade.Face.BackgroundTransparency - grenadeBefore) < 1e-6, "al dejar de apuntar vuelve todo")

-- Recargar: resaltado con el cargador vacío (sin parpadeo)
ClientState.CurrentDef = { Type = "Gun", MagSize = 30 }
ClientState.Ammo = 0
ClientState.Reloading = false
heartbeat()
check(entries.Reload.Emphasis == 2, "cargador vacío: recargar resaltado")
ClientState.Ammo = 6
heartbeat()
check(entries.Reload.Emphasis == 1, "pocas balas: aviso suave")
ClientState.Ammo = 30
heartbeat()
check(entries.Reload.Emphasis == 0, "cargador lleno: normal")

-- Tarjeta del arma y recargas de habilidades
TL.SetCard("SwapWeapon", { Title = "ARX-27", Value = "24 / 90", Sub = "1/2" })
check(entries.SwapWeapon.CardTexts.Value.Text == "24 / 90" and entries.SwapWeapon.CardTexts.Title.Text == "ARX-27", "tarjeta del arma con la munición")
-- Nombre del arma: siempre una línea (sin escalar ni partir), mínimo 11 px y cortado con «…»
for _, name in { "ARX-27", "X", "Lanzagranadas experimental de asalto pesado MK-II" } do
	TL.SetCard("SwapWeapon", { Title = name, Value = "120 / 999", Sub = "2/2" })
	local title = entries.SwapWeapon.CardTexts.Title
	local value = entries.SwapWeapon.CardTexts.Value
	check(title.TextWrapped == false and title.TextScaled == false and title.TextTruncate == Enum.TextTruncate.AtEnd, "«" .. name .. "»: una sola línea, cortada si no cabe")
	check(title.TextSize >= 11 and title.TextSize <= 13 and value.TextSize >= 11, "«" .. name .. "»: texto legible (" .. title.TextSize .. " px)")
end
TL.SetCooldown("AbilityDash", 0.5, "3")
check(entries.AbilityDash.Cover.Visible and entries.AbilityDash.Timer.Text == "3", "recarga de habilidad visible")
TL.SetCooldown("AbilityDash", 0, "0")
check(not entries.AbilityDash.Cover.Visible and entries.AbilityDash.Timer.Text == "", "habilidad lista")
TL.SetBadge("Airstrike", "x2")
check(entries.Airstrike.Badge.Visible and entries.Airstrike.Badge.Text == "x2", "globo con las cargas")

-- Disposición propia (guardada en los ajustes): se aplica y se valida
Settings.Set("HudLayout", { Fire = { X = 0.5, Y = 0.8, S = 1.2, O = 0.5 }, Bogus = { X = 1 }, Aim = { S = 99 } })
task.wait(0.1)
layout = TL.GetLayout()
check(math.abs(layout.Fire.Center.X - W * 0.5) < 1 and math.abs(layout.Fire.Center.Y - H * 0.8) < 1, "disposición propia: disparar movido")
check(math.abs(layout.Fire.Size.X - 84 * 1.2) < 0.5, "disposición propia: tamaño")
check(math.abs(layout.Aim.Size.X - 56 * MobileHUD.Limits.S[2]) < 0.5, "tamaño fuera de rango recortado")
check(ClientState.Settings.HudLayout.Bogus == nil, "controles desconocidos fuera")
Settings.Set("HudLayout", {})
task.wait(0.1)
layout = TL.GetLayout()
check(math.abs(layout.Fire.Size.X - 84) < 0.5, "restablecer: vuelve la disposición por defecto")

-- Modo editor: se ven todos y tocar no dispara nada
TL.SetEditing(true, {})
check(entries.Sprint.Button.Visible and entries.LeftFire.Button.Visible, "editor: se ven todos los controles")
TL.SetEditing(false)
check(not entries.Sprint.Button.Visible, "al salir del editor, como antes")
print("BOTONES TACTILES OK")
process.exit(0)
