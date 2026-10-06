-- Datos de la pantalla final a partir del MatchResult del servidor (Round.endRound → RoundEnd.Result)
-- y del resumen personal (MatchSummary). Aquí solo se ordena y se decide qué enseñar; nada se inventa:
-- si un dato no llega, su panel no sale.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MatchResults = require(Shared.MatchResults)

local player = Players.LocalPlayer

local Data = {}

Data.MyId = "u" .. tostring(player.UserId)

local function sorted(list)
	local copy = table.clone(list)
	table.sort(copy, MatchResults.Better)
	return copy
end

-- Prepara lo que pinta la pantalla. Devuelve nil si este jugador no jugó la partida
-- (p. ej. entró y siguió en el lobby): a él no se le enseña.
function Data.Build(result)
	if type(result) ~= "table" or type(result.Players) ~= "table" then
		return nil
	end
	local me
	for _, entry in result.Players do
		if entry.Id == Data.MyId then
			me = entry
		end
	end
	if not me then
		return nil
	end
	local view = {
		Raw = result,
		Me = me,
		Mode = result.Mode,
		ModeName = tostring(result.ModeName or ""),
		Map = tostring(result.Map or ""),
		TeamMode = result.TeamMode ~= false,
		Reason = MatchResults.ReasonText(result.Reason),
		ReasonCode = result.Reason,
		MVP = result.MVP,
	}
	if view.TeamMode then
		local myTeam = me.Team
		local enemyTeam = myTeam == result.TeamA and result.TeamB or result.TeamA
		view.MyTeam = myTeam
		view.EnemyTeam = enemyTeam
		view.MyScore = myTeam == result.TeamA and result.ScoreA or result.ScoreB
		view.EnemyScore = myTeam == result.TeamA and result.ScoreB or result.ScoreA
		view.Outcome = result.Winner == nil and "Draw" or (result.Winner == myTeam and "Victory" or "Defeat")
		local mine, enemies = {}, {}
		for _, entry in result.Players do
			if entry.Team == myTeam then
				table.insert(mine, entry)
			else
				table.insert(enemies, entry)
			end
		end
		view.Allies = sorted(mine)
		view.Enemies = sorted(enemies)
	else
		-- Todos contra todos: "tu equipo" es la clasificación entera; el marcador, tus puntos y los del líder
		local all = sorted(result.Players)
		view.Allies = all
		view.Enemies = {}
		local leader = all[1]
		local won = result.Winner ~= nil and (result.Winner == player.Name or (leader and leader.Id == Data.MyId))
		view.Outcome = result.Winner == nil and "Draw" or (won and "Victory" or "Defeat")
		view.MyScore = me.Kills
		view.EnemyScore = leader and leader.Id ~= Data.MyId and leader.Kills or (all[2] and all[2].Kills or 0)
	end
	-- En escena: los 5 primeros de tu equipo (el mejor en el centro: MVP o tu jugador destacado)
	view.Lineup = {}
	for i = 1, math.min(5, #view.Allies) do
		view.Lineup[i] = view.Allies[i]
	end
	view.Featured = view.Lineup[1]
	view.FeaturedIsMVP = view.Featured ~= nil and view.Featured.Id == result.MVP
	-- Marcador pequeño (S&D, Eliminación): sin contador largo
	view.SmallScore = math.max(tonumber(view.MyScore) or 0, tonumber(view.EnemyScore) or 0) <= 12
	return view
end

-- Recompensas que de verdad ha dado el servidor (MatchSummary): solo las que existen
function Data.Rewards(summary)
	if type(summary) ~= "table" then
		return nil
	end
	local list = {}
	local xp = tonumber(summary.XP) or 0
	if xp > 0 then
		table.insert(list, { Kind = "XP", Amount = xp, Label = "EXPERIENCIA" })
	end
	local coins = (tonumber(summary.Coins) or 0) + (tonumber(summary.BonusCoins) or 0)
	if coins > 0 then
		table.insert(list, { Kind = "Coins", Amount = coins, Label = "MONEDAS" })
	end
	local crates = tonumber(summary.Crates) or 0
	if crates > 0 then
		table.insert(list, { Kind = "Crate", Amount = crates, Label = crates == 1 and "CAJA GRATIS" or "CAJAS GRATIS" })
	end
	-- XP del pase de batalla (y si ha subido de nivel del pase)
	local passXP = tonumber(summary.PassXP) or 0
	if passXP > 0 then
		local per = math.max(1, tonumber(summary.PassXPPerTier) or 2500)
		local tiers = tonumber(summary.PassTiers) or 50
		local before = math.min(tiers, math.floor((tonumber(summary.PassStartXP) or 0) / per) + 1)
		local after = math.min(tiers, math.floor((tonumber(summary.PassNowXP) or 0) / per) + 1)
		table.insert(list, { Kind = "Pass", Amount = passXP, Label = after > before and ("PASE · ¡NIVEL " .. after .. "!") or ("PASE · NIVEL " .. after), TierUp = after > before })
	end
	return list
end

-- Oferta pequeña de después de la partida (MonetizationConfig.PostMatchOffer): solo según lo que
-- hiciste en la partida (el arma con la que más bajas hiciste) y como mucho una de cada pocas
-- partidas. Devuelve { Weapon, Kills, Item } o nil. owns(kind, id) dice si ya lo tienes.
function Data.PostMatchOffer(summary, config, items, owns)
	if type(summary) ~= "table" or not config or not config.Enabled then
		return nil
	end
	local matches = tonumber(summary.Matches) or 0
	local kills = tonumber(summary.TopWeaponKills) or 0
	if not summary.TopWeapon or matches < (config.MinMatches or 3) or kills < (config.MinWeaponKills or 6) then
		return nil
	end
	if matches % math.max(1, config.EveryMatches or 4) ~= 0 then
		return nil
	end
	-- Una skin que no tienes, para verla en esa arma (va cambiando de una oferta a la siguiente)
	local candidates = {}
	for _, item in items do
		if item.Kind == "Skin" and not owns(item.Kind, item.Id) then
			table.insert(candidates, item)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local pick = candidates[(matches // math.max(1, config.EveryMatches or 4)) % #candidates + 1]
	return { Weapon = summary.TopWeapon, Kills = kills, Item = pick }
end

-- Progreso de nivel: tramos de la barra (uno por nivel subido) para animarla de verdad
function Data.LevelSteps(summary)
	if type(summary) ~= "table" then
		return nil
	end
	local per = math.max(1, tonumber(summary.XPPerLevel) or 1000)
	local startLevel = tonumber(summary.StartLevel) or tonumber(summary.Level) or 1
	local endLevel = tonumber(summary.Level) or startLevel
	local steps = {}
	local level = startLevel
	local from = (tonumber(summary.StartXP) or 0) / per
	while level < endLevel do
		table.insert(steps, { Level = level, From = from, To = 1, LevelUp = true })
		level += 1
		from = 0
	end
	table.insert(steps, { Level = level, From = from, To = math.clamp((tonumber(summary.LevelXP) or 0) / per, 0, 1) })
	return {
		Steps = steps,
		StartLevel = startLevel,
		EndLevel = endLevel,
		PerLevel = per,
		StartXP = tonumber(summary.StartXP) or 0,
		EndXP = tonumber(summary.LevelXP) or 0,
		Gained = tonumber(summary.XP) or 0,
	}
end

return Data
