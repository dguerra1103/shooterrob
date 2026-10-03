-- Punto de entrada del cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local Modules = script.Parent:WaitForChild("Modules")
local ClientState = require(Modules.ClientState)
local WeaponController = require(Modules.WeaponController)
local Movement = require(Modules.Movement)
local HUD = require(Modules.HUD)
local Menu = require(Modules.Menu)
local MainMenu = require(Modules.MainMenu)
local WorldFX = require(Modules.WorldFX)
local VoteUI = require(Modules.VoteUI)
local GrenadeController = require(Modules.GrenadeController)
local KillstreakController = require(Modules.KillstreakController)
local Settings = require(Modules.Settings)
local Footprints = require(Modules.Footprints)

Remotes.DataUpdate.OnClientEvent:Connect(ClientState.SetData)
task.spawn(function()
	local ok, data = pcall(function()
		return Remotes.GetData:InvokeServer()
	end)
	if ok and data and not ClientState.Data then
		ClientState.SetData(data)
	end
end)

Settings.Init()
HUD.Init()
Menu.Init()
Movement.Init()
WeaponController.Init()
WorldFX.Init()
Footprints.Init()
VoteUI.Init()
GrenadeController.Init()
KillstreakController.Init()
MainMenu.Init() -- la última: muestra la pantalla de inicio
