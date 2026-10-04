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

MapBuilder.Build() -- primer mapa de la rotación (o tu mapa propio si existe workspace.Map)
PlayerData.Init()
Loadout.Init()
Combat.Init()
Combat.OnKill = Round.RegisterKill
Round.Init()
Respawn.Init() -- reaparición propia (CharacterAutoLoads desactivado): después de Round
Dummies.Init()
Hazards.Init()
Grenades.Init()
Leaderboard.Init()
Killstreaks.Init()
Abilities.Init()
Bots.Init()
Gifts.Init()
