-- Punto de entrada del servidor: inicia todos los sistemas en orden.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.Remotes) -- crea los RemoteEvents antes que nada

local Modules = script.Parent.Modules
local MapBuilder = require(Modules.MapBuilder)
local PlayerData = require(Modules.PlayerData)
local Loadout = require(Modules.Loadout)
local Combat = require(Modules.Combat)
local Round = require(Modules.Round)
local Dummies = require(Modules.Dummies)
local Hazards = require(Modules.Hazards)
local Grenades = require(Modules.Grenades)
local Leaderboard = require(Modules.Leaderboard)
local Killstreaks = require(Modules.Killstreaks)
local Respawn = require(Modules.Respawn)
local Abilities = require(Modules.Abilities)
local Bots = require(Modules.Bots)
local Gifts = require(Modules.Gifts)
local Friends = require(Modules.Friends)
local Event = require(Modules.Event)
local Graffiti = require(Modules.Graffiti)


-- Arranca cada sistema por separado: si uno falla, se avisa en Output y los demás siguen
local function start(name, fn, ...)
	local ok, err = xpcall(fn, debug.traceback, ...)
	if not ok then
		warn("[Arranque] " .. name .. " falló: " .. tostring(err))
	end
end

start("MapBuilder", MapBuilder.Build) -- primer mapa de la rotación (o tu mapa propio si existe workspace.Map)
start("PlayerData", PlayerData.Init)
start("Loadout", Loadout.Init)
start("Combat", Combat.Init)
Combat.OnKill = Round.RegisterKill
Combat.OnAssist = Round.RegisterAssist
start("Round", Round.Init)
start("Respawn", Respawn.Init) -- reaparición propia (CharacterAutoLoads desactivado): después de Round
start("Dummies", Dummies.Init)
start("Hazards", Hazards.Init)
start("Grenades", Grenades.Init)
start("Leaderboard", Leaderboard.Init)
start("Killstreaks", Killstreaks.Init)
start("Abilities", Abilities.Init)
start("Bots", Bots.Init)
start("Gifts", Gifts.Init)
start("Friends", Friends.Init)
start("Event", Event.Init)
start("Graffiti", Graffiti.Init)
