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

MapBuilder.Build() -- primer mapa de la rotación (o tu mapa propio si existe workspace.Map)
PlayerData.Init()
Loadout.Init()
Combat.Init()
Combat.OnKill = Round.RegisterKill
Round.Init()
Dummies.Init()
Hazards.Init()
Grenades.Init()
Leaderboard.Init()
Killstreaks.Init()
