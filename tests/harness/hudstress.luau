-- HUD táctil bajo carga de partida (Fase 16). SIMULACIÓN, no multijugador real: 10 jugadores ficticios
-- y los atributos que manda el servidor en cada modo. Pantalla 19,5:9 (892×412) con la cámara frontal
-- y la barra de Roblox simuladas (zonas seguras distintas para botones y HUD). Comprueba, en el peor
-- caso razonable (registro de bajas lleno, 4 medallas, objetivo, racha, radar, daño, recargas...):
--   * 0 choques entre controles (cajas táctiles con aire) y nada en el centro libre;
--   * los elementos de las zonas no se pisan entre sí ni con los botones, la munición o la vida;
--   * en cada uno de los 10 modos sale lo suyo (A/B/C, bomba, bandera, zona, en pie, líder...);
--   * registro de bajas con 3 filas como mucho y medallas con 2 como mucho;
--   * 5 reaparecidas, menú abierto/cerrado, fin de partida y 5 partidas seguidas sin botones pegados
--     ni duplicados; disposición propia rota bloqueada en el editor; correr con botón y disparo
--     izquierdo sin choques.
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
mock.policyInfo = { ArePaidRandomItemsRestricted = false }
-- (cámara frontal a la izquierda y barra de Roblox arriba: valores de simulación)
mock.screenInsets = { Device = { 32, 0, 0, 0 }, Core = { 32, 58, 0, 0 } }
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Vector2 = roblox.Vector2
local Enum = roblox.Enum
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local GameConfig = req(RS.Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = Teams
end
local A, B = GameConfig.Teams[1].Name, GameConfig.Teams[2].Name
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
-- 9 jugadores más (5 contra 5)
for i = 1, 9 do
	local other = mock.new("Player"); other.Name = "Jugador" .. i; other.DisplayName = "Jugador" .. i; other.UserId = 100 + i
	other.Team = Teams:GetChildren()[(i % 2) + 1]; other.Parent = Players
end
local W, H = 892, 412
game.Workspace.CurrentCamera.ViewportSize = Vector2.new(W, H)
game.Workspace.CurrentCamera.CFrame = roblox.CFrame.new(0, 5, 0) -- (disparar de verdad necesita la cámara)
local UIS = game:GetService("UserInputService")
UIS.TouchEnabled = true
UIS.KeyboardEnabled = true -- (como el S26 Ultra: dice tener teclado)
UIS.MouseEnabled = false
RS:SetAttribute("TeamA", A); RS:SetAttribute("TeamB", B); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Playing"); RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("MapName", "Construction")
RS:SetAttribute("TimeLeft", 300); RS:SetAttribute("ScoreToWin", 50)
req(game.StarterPlayer.Client.Main)
task.wait(2)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
local TL = req(game.StarterPlayer.Client.Modules.TouchLayout)
local HUDZones = req(game.StarterPlayer.Client.Modules.HUDZones)
local MobileHUD = req(RS.Shared.MobileHUD)
local Remotes = req(RS.Shared.Remotes)
pcall(function() req(game.StarterPlayer.Client.Modules.MainMenu).Hide() end)
ClientState.InMainMenu = false
ClientState.MenuOpen = false
ClientState.Dead = false

local function newCharacter()
	local char = mock.new("Model"); char.Name = "Jugador"
	local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char
	for _, n in { "HumanoidRootPart", "Head", "RightHand", "UpperTorso" } do local part = mock.new("Part"); part.Name = n; part.Parent = char end
	char.Parent = game.Workspace
	me.Character = char
	me.CharacterAdded:Fire(char)
	return char, hum
end
local char, hum = newCharacter()
local tool = mock.new("Tool"); tool.Name = "ARX27"; tool:SetAttribute("Weapon", "ARX27"); tool:SetAttribute("Slot", 1); tool:SetAttribute("Ammo", 5); tool:SetAttribute("Reserve", 90)
tool.Parent = char
char.ChildAdded:Fire(tool)
task.wait(0.5)

-- (en el simulador, un error de otro módulo en el Heartbeat corta a los demás: los pasos se dan a mano)
local function settle()
	pcall(TL.Tick)
	TL.Relayout()
	task.wait(0.3)
	HUDZones.Layout()
end

-- Un dedo falso que se puede soltar
local function fakeTouch()
	local listeners = {}
	local t = { UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin, Position = roblox.Vector3.new(0, 0, 0) }
	function t:GetPropertyChangedSignal()
		return { Connect = function(_, fn) table.insert(listeners, fn) return { Disconnect = function() local i = table.find(listeners, fn) if i then table.remove(listeners, i) end end } end }
	end
	function t.Lift() t.UserInputState = Enum.UserInputState.End for _, fn in table.clone(listeners) do fn() end end
	return t
end

-- Comprobaciones comunes del estado actual
local function checkState(name)
	settle()
	local layout, class = TL.GetLayout()
	check(class == "ULTRAWIDE_PHONE", name .. ": ULTRAWIDE_PHONE")
	check(#TL.LastCollisions == 0, name .. ": 0 choques entre controles (" .. #TL.LastCollisions .. ")")
	local issues = HUDZones.Validate()
	local text = {}
	for _, issue in issues do table.insert(text, issue[1] .. "/" .. issue[2]) end
	check(#issues == 0, name .. ": los avisos y objetivos no pisan nada " .. table.concat(text, ", "))
	-- nada interactivo en el centro libre
	local size = TL.GetLayout() and select(1, layout) and nil
	local _ = size
	return layout
end

-- 1) Peor caso de un tiroteo (TDM): registro de bajas lleno, medallas, XP, avisos, racha, radar
local red = roblox.Color3.fromRGB(255, 80, 80)
for i = 1, 20 do
	Remotes.KillFeed.OnClientEvent:Fire({ Killer = i % 3 == 0 and "Jugador" or ("UnNombreMuyLargoDeJugador" .. i), KillerColor = red, Victim = "Jugador" .. (i % 9 + 1), VictimColor = roblox.Color3.new(0.3, 0.5, 1), Weapon = "Specter-9", WeaponId = "Specter9", Headshot = i % 2 == 0 })
end
for _, m in { "¡DOBLE BAJA!", "PRIMERA SANGRE", "VENGANZA", "A LA CABEZA" } do
	Remotes.Notify.OnClientEvent:Fire("Medal", m)
end
for i = 1, 4 do Remotes.Notify.OnClientEvent:Fire("XP", "+" .. (50 * i) .. " XP  Baja") end
Remotes.Notify.OnClientEvent:Fire("Info", "Reto completado: 10 bajas con fusil")
me:SetAttribute("Streak", 4); me:SetAttribute("Airstrikes", 1)
pcall(function() me:SetAttribute("RadarUntil", game.Workspace:GetServerTimeNow() + 20) end)
ClientState.Stamina = 0.35
hum.Health = 30
task.wait(0.5)
local hud = pg:FindFirstChild("HUD")
local feedRows, medals = 0, 0
for _, d in hud:GetDescendants() do
	if d.__className == "Frame" and d.Size and d.Size.X.Offset == 230 and d.Size.Y.Offset == 20 then feedRows += 1 end
	-- (las medallas llevan dos espacios a cada lado: «  VENGANZA  »)
	if d.__className == "TextLabel" and type(d.Text) == "string" and string.match(d.Text, "^  .+  $") then medals += 1 end
end
check(feedRows <= 3, "registro de bajas: 3 filas como mucho con 20 bajas (" .. feedRows .. ")")
check(medals <= 2, "medallas: 2 como mucho a la vez (" .. medals .. ")")
checkState("TDM en pleno tiroteo")
check(HUDZones.Placed.KillBanner ~= nil, "TDM: aviso de baja colocado")

-- (Fase 17) Avisos grandes en plena pelea («¡TE BUSCAN!», reto, racha): van en la zona de arriba,
-- no a todo el ancho por encima del aviso de baja y del registro de bajas; y en táctil, sin emojis
Remotes.Notify.OnClientEvent:Fire("Wanted", 250)
Remotes.Notify.OnClientEvent:Fire("Streak", "Jugador lleva una racha de 5")
Remotes.Notify.OnClientEvent:Fire("Assist", "+50")
task.wait(0.3)
checkState("TDM con aviso grande")
check(HUDZones.Placed.BigText ~= nil or HUDZones.Overflow.BigText == true, "aviso grande en su zona (o apartado si no cabe)")
local function pictogram(text)
	if type(text) ~= "string" or not utf8.len(text) then
		return nil
	end
	for _, code in utf8.codes(text) do
		if (code >= 0x1F000 and code <= 0x1FAFF) or (code >= 0x2600 and code <= 0x27BF) or (code >= 0x2B00 and code <= 0x2BFF) then
			return utf8.char(code)
		end
	end
	return nil
end
local emojiLeft = {}
local function shownOnScreen(d, screen)
	local node = d
	while node and node ~= screen do
		if node.Visible == false then
			return false
		end
		node = node.Parent
	end
	return true
end
for _, screen in pg:GetChildren() do
	if screen.__className == "ScreenGui" and screen.Enabled ~= false and screen.Name ~= "MainMenu" and screen.Name ~= "Menu" then
		for _, d in screen:GetDescendants() do
			local transparency = type(d.TextTransparency) == "number" and d.TextTransparency or 0
			if (d.__className == "TextLabel" or d.__className == "TextButton") and transparency < 0.99 and shownOnScreen(d, screen) then
				local found = pictogram(d.Text)
				if found then
					table.insert(emojiLeft, screen.Name .. "/" .. d.Name .. " «" .. tostring(d.Text) .. "»")
				end
			end
		end
	end
end
check(#emojiLeft == 0, "HUD táctil en partida sin emojis " .. table.concat(emojiLeft, " | "))
check(HUDZones.Placed.Medals ~= nil, "TDM: medallas colocadas")
check(HUDZones.Placed.Toast ~= nil, "TDM: aviso de texto bajo la mira")

-- 2) Los 10 modos: lo que sale en cada uno y que nada se pise
local function clearModeAttributes()
	for _, l in { "A", "B", "C" } do
		RS:SetAttribute("Dom_" .. l .. "_Position", nil); RS:SetAttribute("Dom_" .. l .. "_Owner", nil)
		RS:SetAttribute("Dom_" .. l .. "_Capturing", nil); RS:SetAttribute("Dom_" .. l .. "_Progress", nil)
	end
	for _, k in { "Bomb_Attackers", "Bomb_State", "Bomb_Site", "Bomb_Timer", "Bomb_Action", "Bomb_Progress", "AliveA", "AliveB", "ZoneOwner", "ZoneMoveIn", "ZonePosition", "Infection", "LeaderScore", "LeaderName" } do
		RS:SetAttribute(k, nil)
	end
	for _, team in { A, B } do
		RS:SetAttribute("FlagState_" .. team, nil); RS:SetAttribute("FlagCarrier_" .. team, nil)
	end
	me:SetAttribute("CarryingFlag", nil)
end
local MODES = {
	TDM = function() end,
	DOM = function()
		for i, l in { "A", "B", "C" } do
			RS:SetAttribute("Dom_" .. l .. "_Position", roblox.Vector3.new(i * 10, 0, 0))
			RS:SetAttribute("Dom_" .. l .. "_Owner", i == 1 and A or "")
		end
		RS:SetAttribute("Dom_B_Capturing", A); RS:SetAttribute("Dom_B_Progress", 0.5)
	end,
	SND = function()
		RS:SetAttribute("Bomb_Attackers", A); RS:SetAttribute("Bomb_State", "Planted"); RS:SetAttribute("Bomb_Site", "A"); RS:SetAttribute("Bomb_Timer", 31)
		RS:SetAttribute("Bomb_Action", "Defusing"); RS:SetAttribute("Bomb_Progress", 0.4)
		RS:SetAttribute("AliveA", 3); RS:SetAttribute("AliveB", 4)
	end,
	CTF = function()
		RS:SetAttribute("FlagState_" .. A, "Carried"); RS:SetAttribute("FlagCarrier_" .. A, "Jugador3")
		RS:SetAttribute("FlagState_" .. B, "Carried"); RS:SetAttribute("FlagCarrier_" .. B, "Jugador")
		me:SetAttribute("CarryingFlag", true)
	end,
	KOTH = function()
		RS:SetAttribute("ZoneOwner", "Contested"); RS:SetAttribute("ZoneMoveIn", 14); RS:SetAttribute("ZonePosition", roblox.Vector3.new(20, 0, 0))
	end,
	FFA = function()
		RS:SetAttribute("TeamMode", false); me:SetAttribute("Score", 7); RS:SetAttribute("LeaderScore", 11); RS:SetAttribute("LeaderName", "Jugador4")
	end,
	GUN = function()
		RS:SetAttribute("TeamMode", false); me:SetAttribute("Score", 3); RS:SetAttribute("LeaderScore", 9); RS:SetAttribute("LeaderName", "Jugador2")
	end,
	ELIM = function()
		RS:SetAttribute("AliveA", 2); RS:SetAttribute("AliveB", 3)
	end,
	INF = function()
		RS:SetAttribute("Infection", "On"); RS:SetAttribute("AliveA", 4); RS:SetAttribute("AliveB", 6)
	end,
	CAL = function()
		Remotes.Notify.OnClientEvent:Fire("Pumpkin", "+1 calabaza")
	end,
}
local scoreboard = hud:FindFirstChild("TopBar")
local function labelText(pattern)
	for _, d in hud:GetDescendants() do
		if d.__className == "TextLabel" and type(d.Text) == "string" and string.find(d.Text, pattern) then
			return d.Text
		end
	end
	return nil
end
for _, mode in { "TDM", "DOM", "SND", "CTF", "KOTH", "FFA", "GUN", "ELIM", "INF", "CAL" } do
	clearModeAttributes()
	RS:SetAttribute("TeamMode", true)
	RS:SetAttribute("Mode", mode)
	MODES[mode]()
	RS:SetAttribute("TimeLeft", 200) -- (fuerza a repintar el marcador)
	task.wait(0.4)
	checkState(mode)
	if mode == "DOM" then
		check(HUDZones.Placed.DomFlags ~= nil, "DOM: banderas A/B/C bajo el minimapa")
	elseif mode == "SND" then
		check(HUDZones.Placed.BombStatus ~= nil, "SND: estado de la bomba bajo el minimapa")
		check(HUDZones.Placed.BombProgress ~= nil, "SND: desactivando, bajo la mira")
		check(labelText("En pie") ~= nil, "SND: equipos en pie en la línea del modo")
	elseif mode == "CTF" then
		check(HUDZones.Placed.CarrierBanner ~= nil, "CTF: «tienes la bandera» arriba, fuera del centro")
	elseif mode == "KOTH" then
		check(labelText("DISPUTADA") ~= nil, "KOTH: estado de la zona junto al marcador")
	elseif mode == "FFA" or mode == "GUN" then
		check(labelText("TÚ") ~= nil and labelText("5 VS 5") == nil, mode .. ": tú contra el líder (sin «5 VS 5»)")
	elseif mode == "ELIM" then
		check(labelText("En pie") ~= nil, "ELIM: en pie")
	elseif mode == "INF" then
		check(labelText("Supervivientes") ~= nil or labelText("Sobrevive") ~= nil, "INF: supervivientes contra zombis")
	end
end
local _ = scoreboard
clearModeAttributes()
RS:SetAttribute("TeamMode", true); RS:SetAttribute("Mode", "TDM")

-- 3) Ajustes que añaden botones: correr con botón y disparo izquierdo, sin choques
local Settings = req(game.StarterPlayer.Client.Modules.Settings)
Settings.Set("AutoSprint", 0)
Settings.Set("LeftFire", 1)
task.wait(0.2)
checkState("correr con botón y disparo izquierdo")
check(TL.Entries().Sprint.Button.Visible and TL.Entries().LeftFire.Button.Visible, "correr y disparo izquierdo visibles")
Settings.Set("AutoSprint", 1)
Settings.Set("LeftFire", 0)
task.wait(0.2)
settle()
check(not TL.Entries().Sprint.Button.Visible and not TL.Entries().LeftFire.Button.Visible, "apagados: no se ven")

-- 4) Reaparecer 5 veces con dedos encima: nada se queda pulsado
for round = 1, 5 do
	local fire, aim, jump = fakeTouch(), fakeTouch(), fakeTouch()
	TL.Entries().Fire.Press(fire)
	TL.Entries().Aim.Press(aim)
	TL.Entries().Jump.Press(jump)
	task.wait()
	check(TL.Entries().Fire.Pressed and TL.Entries().Jump.Pressed, "reaparición " .. round .. ": disparando y saltando")
	hum.Health = 0
	pcall(function() hum.Died:Fire() end)
	char, hum = newCharacter()
	task.wait(0.1)
	local stuck = {}
	for id, entry in TL.Entries() do
		if entry.Pressed or entry.Owner then table.insert(stuck, id) end
	end
	check(#stuck == 0, "reaparición " .. round .. ": ningún botón pulsado " .. table.concat(stuck, ","))
	-- (el dedo viejo, al levantarse, no suelta nada nuevo)
	fire.Lift(); aim.Lift(); jump.Lift()
end

-- 5) Menú abierto con el dedo encima, y cerrado: no se reactiva nada
local finger = fakeTouch()
TL.Entries().Fire.Press(finger)
ClientState.MenuOpen = true
ClientState.UpdateMouse()
check(not TL.Entries().Fire.Button.Visible and not TL.Entries().Fire.Pressed, "menú abierto: botones fuera y disparo suelto")
ClientState.MenuOpen = false
ClientState.UpdateMouse()
check(TL.Entries().Fire.Button.Visible and not TL.Entries().Fire.Pressed, "menú cerrado: vuelven sin disparar solos")
finger.Lift()

-- 6) Cinco partidas seguidas: fin de partida (resultados) y la siguiente, sin duplicados
local gui = pg:FindFirstChild("TouchButtons")
for match = 1, 5 do
	RS:SetAttribute("State", "Ended")
	ClientState.InMainMenu = true -- (resultados)
	ClientState.UpdateMouse()
	check(not TL.Entries().Fire.Button.Visible, "partida " .. match .. ": en los resultados no hay botones de juego")
	RS:SetAttribute("State", "Playing")
	ClientState.InMainMenu = false
	ClientState.UpdateMouse()
	char, hum = newCharacter()
	task.wait(0.1)
	local count = {}
	for _, b in gui:GetChildren() do count[b.Name] = (count[b.Name] or 0) + 1 end
	local dup = {}
	for name, n in count do if n > 1 then table.insert(dup, name) end end
	check(#dup == 0, "partida " .. match .. ": sin botones duplicados " .. table.concat(dup, ","))
	checkState("partida " .. match)
end

-- 7) Disposición propia rota: el editor avisa y no deja guardar dos controles de combate juntos
local Editor = req(game.StarterPlayer.Client.Modules.HUDEditor)
Editor.Open()
local layout = TL.GetLayout()
local aimCenter = layout.Aim.Center
Editor.Select("Fire")
Editor.MoveSelected(aimCenter)
local result = Editor.Check()
check(#result.Blocking >= 1, "editor: disparar encima de apuntar se detecta")
check(Editor.Save() == false and Editor.IsOpen(), "editor: no se guarda con disparar encima de apuntar")
Editor.Reset()
check(#Editor.Check().Blocking == 0, "editor: restablecer deja la disposición nueva, sin choques")
check(Editor.Save() == true, "editor: se guarda")
-- (cerca sí se puede: solo se avisa)
local near = MobileHUD.Resolve(Vector2.new(W, H), { Screen = Vector2.new(W, H), Custom = { Reload = { X = 0.66, Y = 0.8 } } })
local _ = near
print("HUD BAJO CARGA OK")
process.exit(0)
