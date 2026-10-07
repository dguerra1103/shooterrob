local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local Players = game:GetService("Players")
local me = mock.new("Player"); me.Name = "Yo"; me.UserId = 1; me.Parent = Players
Players.LocalPlayer = me
local Effects = req(game.StarterPlayer.Client.Modules.Effects)
local KillEffects = req(game.ReplicatedStorage.Shared.KillEffects)
local n = 0
for id in KillEffects.List do
	local ok, err = pcall(Effects.KillEffect, id, roblox.Vector3.new(0, 3, 0), roblox.Color3.new(1, 0, 0))
	if not ok then print("FALLO " .. id .. ": " .. tostring(err)) process.exit(1) end
	n += 1
end
task.wait(0.5)
print("efectos probados:", n)
print("EFECTOS OK")
process.exit(0)
