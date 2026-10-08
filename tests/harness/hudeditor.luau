-- Editor de HUD (Fase 12): abrir bloquea el juego y enseña todos los controles; mover, tamaño y
-- opacidad cambian la disposición en vivo; CANCELAR no guarda; GUARDAR va a los ajustes del jugador;
-- RESTABLECER vuelve a lo de fábrica; el servidor valida lo que le llega (sin DataStore aparte).
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
mock.policyInfo = { ArePaidRandomItemsRestricted = false }
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Vector2 = roblox.Vector2
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
local W, H = 667, 375
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
local Settings = req(game.StarterPlayer.Client.Modules.Settings)
local Editor = req(game.StarterPlayer.Client.Modules.HUDEditor)
local MobileHUD = req(RS.Shared.MobileHUD)
ClientState.InMainMenu = false
ClientState.MenuOpen = false
TL.RefreshVisibility()
local defaults = TL.GetLayout()
local fireDefault = defaults.Fire.Center

-- Abrir
local closedCalls = 0
check(Editor.Open(function() closedCalls += 1 end), "el editor se abre en pantalla táctil")
check(not Editor.Open(), "no se abre dos veces")
check(ClientState.HUDEditorOpen and ClientState.IsBlocked(), "mientras se edita no se juega")
check(TL.IsEditing(), "los controles en modo editor")
local entries = TL.Entries()
check(entries.Sprint.Button.Visible and entries.LeftFire.Button.Visible, "se ven todos los controles (también los apagados)")
local editorGui = pg:FindFirstChild("HUDEditor")
check(editorGui ~= nil and editorGui:FindFirstChild("Catcher") ~= nil, "pantalla del editor que recoge los toques")
local panel = editorGui:FindFirstChild("Panel")
local found = {}
for _, d in panel:GetDescendants() do
	if d.ClassName == "TextButton" then found[d.Text] = true end
end
check(found.RESTABLECER and found.CANCELAR and found.GUARDAR, "RESTABLECER, CANCELAR y GUARDAR")
local names = 0
for _, d in editorGui:GetChildren() do
	if string.sub(d.Name, 1, 5) == "Name_" then names += 1 end
end
check(names >= #MobileHUD.Controls, "cada control con su nombre (" .. names .. ")")

-- Mover, tamaño y opacidad (en vivo)
Editor.Select("Fire")
Editor.MoveSelected(Vector2.new(W * 0.6, H * 0.7))
local layout = TL.GetLayout()
check((layout.Fire.Center - Vector2.new(W * 0.6, H * 0.7)).Magnitude < 1, "arrastrar mueve disparar")
Editor.SetValue("S", 5)
layout = TL.GetLayout()
check(math.abs(layout.Fire.Size.X - 84 * MobileHUD.Limits.S[2]) < 0.5, "tamaño con tope (" .. layout.Fire.Size.X .. ")")
Editor.SetValue("O", 0)
check(Editor.Working().Fire.O == MobileHUD.Limits.O[1], "opacidad con tope inferior (no desaparece)")
Editor.MoveSelected(Vector2.new(-500, 9000))
layout = TL.GetLayout()
local half = layout.Fire.Size / 2
check(layout.Fire.Center.X >= half.X - 0.5 and layout.Fire.Center.Y <= H - half.Y + 0.5, "nunca se sale de la pantalla")

-- CANCELAR: nada cambia
Editor.Cancel()
task.wait(0.1)
check(not ClientState.HUDEditorOpen and not TL.IsEditing() and not Editor.IsOpen(), "cancelar cierra el editor")
check(closedCalls == 1, "y vuelve a Ajustes")
check(next(ClientState.Settings.HudLayout or {}) == nil, "cancelar no guarda")
check((TL.GetLayout().Fire.Center - fireDefault).Magnitude < 1, "cancelar deja los controles donde estaban")
check(not entries.Sprint.Button.Visible, "los apagados se vuelven a esconder")

-- GUARDAR
Editor.Open()
Editor.Select("Aim")
Editor.MoveSelected(Vector2.new(W * 0.5, H * 0.5))
Editor.SetValue("S", 1.2)
Editor.Save()
task.wait(0.1)
local saved = ClientState.Settings.HudLayout
check(saved and saved.Aim and math.abs(saved.Aim.X - 0.5) < 0.01 and saved.Aim.S == 1.2, "guardar lo pone en los ajustes del jugador")
check((TL.GetLayout().Aim.Center - Vector2.new(W * 0.5, H * 0.5)).Magnitude < 1, "y se aplica en partida")
-- Llega al servidor (con los demás ajustes, sin DataStore aparte) y se valida allí
task.wait(1.7)
local sent
for _, s in mock.serverSent do
	if s.Remote == "SaveSettings" then sent = s.Args[1] end
end
check(sent and sent.HudLayout and sent.HudLayout.Aim, "se envía con los ajustes")
local Remotes = req(RS.Shared.Remotes)
task.wait(1.1)
Remotes.SaveSettings.OnServerEvent:Fire(me, { HudLayout = { Aim = { X = 7, Y = -3, S = 0.01, O = 99 }, Nope = { X = 1, Y = 1 }, Fire = "x", Melee = { X = 0.5 } } })
task.wait(0.1)
local stored = data.Settings.HudLayout
check(stored.Aim.X == 1 and stored.Aim.Y == 0 and stored.Aim.S == MobileHUD.Limits.S[1] and stored.Aim.O == 1, "el servidor recorta los valores")
check(stored.Nope == nil and stored.Fire == nil, "el servidor descarta controles desconocidos y basura")
check(stored.Melee == nil, "posición a medias descartada")

-- RESTABLECER
Editor.Open()
Editor.Reset()
check(next(Editor.Working()) == nil, "restablecer vuelve a lo de fábrica")
Editor.Save()
task.wait(0.1)
check(next(ClientState.Settings.HudLayout) == nil, "y se guarda así")
check((TL.GetLayout().Fire.Center - fireDefault).Magnitude < 1, "disparar en su sitio de fábrica")
print("EDITOR HUD OK")
process.exit(0)
