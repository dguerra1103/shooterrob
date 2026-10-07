-- Prueba de retos diarios y maestría (PlayerData + remotes)
local process = require("@lune/process")
local mock = require("./mock")
local game, req = mock.buildGame(process.args[1])
local M = game.ServerScriptService.Server.Modules
local Shared = game.ReplicatedStorage.Shared
local GameConfig = req(Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local Remotes = req(Shared.Remotes)
local Challenges = req(Shared.Challenges)
local Mastery = req(Shared.Mastery)
local PlayerData = req(M.PlayerData)
local Loadout = req(M.Loadout)
PlayerData.Init()
local skinRefreshes = 0
PlayerData.OnSkinChanged = function() skinRefreshes += 1 end

local function check(cond, msg)
	if not cond then
		error("FALLO: " .. msg, 2)
	end
	print("ok  " .. msg)
end

local p = mock.new("Player"); p.Name = "Tester"; p.UserId = 4242; p.Parent = game:GetService("Players")
table.insert(mock.players, p)
game:GetService("Players").PlayerAdded:Fire(p)
local data = PlayerData.Get(p)
check(data ~= nil, "datos cargados")
local view = Remotes.GetData.OnServerInvoke(p)
check(view.Challenges and #view.Challenges.List == Challenges.PerDay, "3 retos en la vista pública")
check(view.Challenges.RerollsLeft == 1, "1 cambio de reto disponible")
for _, c in view.Challenges.List do
	print("     reto:", c.Id, c.Text)
end
-- Retos: no hay retos de nivel alto para un jugador de nivel 1
for _, c in data.Challenges.List do
	check((Challenges.Get(c.Id).MinLevel or 1) <= 1, "reto apto para nivel 1: " .. c.Id)
end
-- Determinista: mismo día y jugador -> mismos retos
local a = Challenges.Pick(100, 4242, 20, 3)
local b = Challenges.Pick(100, 4242, 20, 3)
check(table.concat(a, ",") == table.concat(b, ","), "elección determinista")
check(a[1] ~= a[2] and a[2] ~= a[3] and a[1] ~= a[3], "retos sin repetir")

-- Cambio de reto
local before = data.Challenges.List[1].Id
check(Remotes.RerollChallenge.OnServerInvoke(p, 1) == true, "cambiar reto 1")
check(data.Challenges.List[1].Id ~= before, "reto cambiado (" .. before .. " -> " .. data.Challenges.List[1].Id .. ")")
check(Remotes.RerollChallenge.OnServerInvoke(p, 2) == false, "segundo cambio rechazado")
check(Remotes.RerollChallenge.OnServerInvoke(p, "x") == false, "índice inválido rechazado")

-- Forzamos retos conocidos y los completamos
data.Challenges.List = {
	{ Id = "Kills", Progress = 0, Done = false },
	{ Id = "Shotguns", Progress = 0, Done = false },
	{ Id = "Streak", Progress = 0, Done = false },
}
local coins0, crates0 = data.Coins, data.FreeCrates
for _ = 1, 14 do
	PlayerData.Track(p, "Kill", 1, "ARX27")
end
check(not data.Challenges.List[1].Done and data.Challenges.List[1].Progress == 14, "14/15 bajas")
PlayerData.Track(p, "Kill", 1, "ARX27")
check(data.Challenges.List[1].Done, "reto de bajas completado")
check(data.Coins == coins0 + 150, "monedas del reto entregadas (" .. data.Coins - coins0 .. ")")
check(data.Challenges.List[2].Progress == 0, "bajas con fusil no cuentan para escopeta")
for _ = 1, 6 do
	PlayerData.Track(p, "Kill", 1, "BreachHammer")
end
check(data.Challenges.List[2].Done, "reto de escopeta completado")
PlayerData.Track(p, "Streak", 3)
PlayerData.Track(p, "Streak", 2)
check(data.Challenges.List[3].Progress == 3, "racha guarda el máximo, no suma")
check(not data.Challenges.Bonus, "sin premio aún")
PlayerData.Track(p, "Streak", 5)
check(data.Challenges.Bonus and data.FreeCrates == crates0 + 1, "premio por completar los 3: caja gratis")
local coins1 = data.Coins
PlayerData.Track(p, "Kill", 1, "ARX27")
check(data.Coins == coins1, "un reto completado no paga dos veces")

-- Nuevo día: retos nuevos
data.Challenges.Day -= 1
Remotes.GetData.OnServerInvoke(p)
check(data.Challenges.Day == req(Shared.Shop).DayNumber() and not data.Challenges.Bonus, "al cambiar de día se reparten retos nuevos")

-- Maestría
check(PlayerData.SkinFor(data, "ARX27") == "Default", "sin camuflaje al empezar")
Remotes.SetCamo.OnServerEvent:Fire(p, "ARX27", "MaestriaCarbono")
check(data.WeaponCamos.ARX27 == nil, "no se puede equipar un camuflaje no ganado")
local c2 = data.Coins
for _ = 1, 24 do
	PlayerData.AddWeaponKill(p, "ARX27")
end
check(Mastery.Level(data.WeaponKills.ARX27) == 0, "24 bajas: sin maestría")
local nearMsg
for i = #mock.sent, 1, -1 do
	local m = mock.sent[i]
	if m.Remote == "Notify" and type(m.Args[2]) == "string" and string.find(m.Args[2], "para el camuflaje", 1, true) then nearMsg = m.Args[2]; break end
end
check(nearMsg ~= nil and string.find(nearMsg, "¡1 baja para el camuflaje Carbono!", 1, true) ~= nil, "a 1 baja del camuflaje, aviso de «ya casi» (" .. tostring(nearMsg) .. ")")
PlayerData.AddWeaponKill(p, "ARX27")
check(data.WeaponCamos.ARX27 == "MaestriaCarbono" and PlayerData.SkinFor(data, "ARX27") == "MaestriaCarbono", "25 bajas: Carbono equipado")
check(data.Coins == c2 + 100, "monedas de maestría")
check(PlayerData.SkinFor(data, "HavocPump") == data.EquippedSkin, "las demás armas siguen con la skin general")
Remotes.SetCamo.OnServerEvent:Fire(p, "ARX27", "MaestriaOro")
check(data.WeaponCamos.ARX27 == "MaestriaCarbono", "Oro aún bloqueado")
Remotes.SetCamo.OnServerEvent:Fire(p, "ARX27", "Default")
check(PlayerData.SkinFor(data, "ARX27") == "Default", "volver a la skin general")
Remotes.SetCamo.OnServerEvent:Fire(p, "NoExiste", "Default")
Remotes.SetCamo.OnServerEvent:Fire(p, "ARX27", 5)
check(true, "entradas inválidas ignoradas sin error")
for _ = 1, 300 do
	PlayerData.AddWeaponKill(p, "Knife")
end
check(data.WeaponCamos.Knife == "MaestriaOscura", "300 bajas: Materia oscura")
PlayerData.AddWeaponKill(p, "NoExiste")
-- Los camuflajes no se pueden equipar como skin general ni comprar
data.Skins.MaestriaOro = true
Remotes.EquipSkin.OnServerEvent:Fire(p, "MaestriaOro")
check(data.EquippedSkin ~= "MaestriaOro", "camuflaje no equipable como skin general")
local ok = Remotes.BuyItem.OnServerInvoke(p, "Skin", "MaestriaDiamante")
check(ok == false, "camuflaje no se vende")
-- Las cajas nunca dan camuflajes
data.Coins = 1e6
data.Skins.MaestriaOro = nil
for _ = 1, 400 do
	local okc, prize = Remotes.OpenCrate.OnServerInvoke(p, "Neon", false)
	if okc and prize.Kind == "Skin" then
		assert(not req(Shared.Skins).List[prize.Id].Mastery, "caja dio camuflaje " .. prize.Id)
	end
end
check(true, "400 cajas sin camuflajes de maestría")

-- Efectos de eliminación
data.Coins = 5000
Remotes.EquipKillEffect.OnServerEvent:Fire(p, "Rayo")
check(data.EquippedKillEffect == "Default", "no se equipa un efecto no comprado")
local okb = Remotes.BuyItem.OnServerInvoke(p, "KillEffect", "Rayo")
check(okb == true and data.KillEffects.Rayo and data.EquippedKillEffect == "Rayo", "comprar efecto lo equipa")
local okb2 = Remotes.BuyItem.OnServerInvoke(p, "KillEffect", "Rayo")
check(okb2 == false, "no se compra dos veces")
check(Remotes.BuyItem.OnServerInvoke(p, "KillEffect", "Default") == false, "el normal no se vende")
check(Remotes.BuyItem.OnServerInvoke(p, "KillEffect", "NoExiste") == false, "efecto inexistente rechazado")
Remotes.EquipKillEffect.OnServerEvent:Fire(p, "Default")
check(data.EquippedKillEffect == "Default", "volver al efecto normal")
data.Coins = 0
check(Remotes.BuyItem.OnServerInvoke(p, "KillEffect", "AgujeroNegro") == false, "sin monedas no se compra")

-- Ajustes del jugador
check(data.Settings and data.Settings.Quality == "Auto" and data.Settings.QualityVersion == 2 and data.Settings.FOV == 80, "ajustes por defecto")
Remotes.SaveSettings.OnServerEvent:Fire(p, { Quality = "Ultra", FOV = 95, Sensitivity = 1.37, AimSensitivity = 9 })
check(data.Settings.Quality == "Ultra" and data.Settings.FOV == 95 and data.Settings.Sensitivity == 1.37 and data.Settings.AimSensitivity == 1.5, "ajustes guardados y acotados")
Remotes.SaveSettings.OnServerEvent:Fire(p, { Quality = "Hackeada", FOV = 0 / 0, Sensitivity = "x" })
check(data.Settings.Quality == "Ultra" and data.Settings.FOV == 95 and data.Settings.Sensitivity == 1.37, "valores inválidos ignorados")
Remotes.SaveSettings.OnServerEvent:Fire(p, "nada")
check(Remotes.GetData.OnServerInvoke(p).Settings.FOV == 95, "ajustes en la vista pública")
check(data.Settings.QualityVersion == 2, "la versión de calidad se conserva al guardar")

-- Vista pública serializable (sin funciones ni instancias)
local function plain(t, path)
	for k, v in t do
		local tv = typeof(v)
		if tv == "table" then
			plain(v, path .. "." .. tostring(k))
		elseif tv ~= "string" and tv ~= "number" and tv ~= "boolean" then
			error("valor no serializable en " .. path .. "." .. tostring(k) .. ": " .. tv)
		end
	end
end
plain(Remotes.GetData.OnServerInvoke(p), "view")
check(true, "vista pública serializable")
local kinds = {}
for _, m in mock.sent do
	if m.Remote == "Notify" then
		kinds[m.Args[1]] = (kinds[m.Args[1]] or 0) + 1
	end
end
print("avisos enviados:", kinds.Challenge, "retos,", kinds.Mastery, "maestrías,", kinds.Unlock, "desbloqueos")
print("repintados de armas:", skinRefreshes)
print("TODO OK")
