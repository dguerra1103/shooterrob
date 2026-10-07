-- Prueba del menú (B): cada pestaña se construye sin errores con datos reales del servidor
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Players = game:GetService("Players")
-- Datos tal como los manda el servidor
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId = "Yo", "Yo", 1
me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
local data = PlayerData.WaitFor(me, 3)
data.WeaponKills = { ARX27 = 12, Viper = 3, Claws = 50 }
data.TotalKills, data.TotalDeaths, data.Wins, data.Matches, data.BestStreak, data.Headshots = 40, 20, 5, 9, 7, 11
data.RankPoints = 300
data.Level = 60 -- (por encima del último nivel del pase: la pestaña no debe quedar vacía)
data.Pass.XP = req(RS.Shared.Economy.BattlePassConfig).MaxXP() -- (y el pase de temporada terminado)
PlayerData.SendUpdate(me)
local RS = game.ReplicatedStorage
local view
for _, sent in mock.sent do
	if sent.Remote == "DataUpdate" then view = sent.Args[1] end
end
check(view and view.Matches == 9 and view.TotalDeaths == 20, "el servidor manda las estadísticas del perfil")
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
RS:SetAttribute("EventName", "Halloween"); game.ReplicatedStorage:SetAttribute("EventId", "Halloween2026")
view.EventCandy = 60
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.Data = view
local Menu = req(game.StarterPlayer.Client.Modules.Menu)
local ok, err = pcall(Menu.Init)
check(ok, "Menu.Init sin errores " .. tostring(err))
for _, tab in { "Perfil", "Pase", "Retos", "Armas", "Skins", "Trajes", "Efectos", "Tienda", "Ajustes" } do
	local okTab, errTab = pcall(Menu.Open, tab)
	check(okTab, "pestaña " .. tab .. " " .. tostring(errTab))
	if tab == "Pase" then
		local tiers = 0
		for _, d in pg:GetDescendants() do
			if d.__className == "TextLabel" and string.find(d.Text, "^NIVEL %d") then tiers += 1 end
		end
		check(tiers >= 10, "el pase muestra niveles aunque ya lo hayas terminado (" .. tiers .. ")")
	end
	if tab == "Perfil" then
		local claimText
		for _, d in pg:GetDescendants() do
			if d.__className == "TextButton" and string.find(d.Text, "Reclamar", 1, true) then claimText = d.Text end
		end
		check(claimText ~= nil, "hay logros para reclamar en el perfil (" .. tostring(claimText) .. ")")
		local texts = {}
		for _, d in pg:GetDescendants() do
			if d.__className == "TextLabel" then texts[d.Text] = true end
		end
		check(texts["⚖ 2.00"] and texts["📈 56%"] and texts["🔥 7"], "estadísticas del perfil (K/D, % victorias, racha)")
		check(texts["ORO   ·   300 RP"], "rango en el perfil")
		check(texts["Pulse ARX-27\n12 bajas"] or texts[(req(RS.Shared.Weapons).Get("ARX27").DisplayName) .. "\n12 bajas"], "arma favorita (sin contar las garras)")
	end
end
Menu.Open("Retos")
local texts = {}
for _, d in pg:GetDescendants() do
	if d.__className == "TextLabel" then texts[d.Text] = true end
end
check(texts["🎃 EVENTO DE HALLOWEEN  ·  🍬 60 / 100 caramelos"] and texts["Traje Cabeza de Calabaza"] and texts["Skin Embrujada"] and texts["🍬 75"], "pista del evento con sus premios")
-- Logros: el servidor da el premio una vez y solo si se ha llegado a la meta
local Remotes = req(RS.Shared.Remotes)
local coinsBefore = data.Coins
local okClaim, reward = Remotes.ClaimAchievement.OnServerInvoke(me, "TotalKills10")
check(okClaim == true and data.Coins == coinsBefore + reward and data.Achievements.TotalKills10, "logro de 10 bajas reclamado (+" .. tostring(reward) .. ")")
check(Remotes.ClaimAchievement.OnServerInvoke(me, "TotalKills10") == false, "no se reclama dos veces")
check(Remotes.ClaimAchievement.OnServerInvoke(me, "TotalKills5000") == false, "no se reclama sin llegar a la meta")
print("MENU OK")
process.exit(0)
