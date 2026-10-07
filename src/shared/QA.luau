-- Modo QA (Fase 8): la única comprobación de si está activo, la misma en el servidor y en el cliente.
-- Activo = GameConfig.QA.Enabled == true Y el juego corre en Roblox Studio. Fuera de Studio (un servidor
-- publicado) nunca, aunque alguien deje Enabled = true por error. Ver FASE_08_VALIDACION_STUDIO.md.
local RunService = game:GetService("RunService")

local GameConfig = require(script.Parent.GameConfig)

local QA = {}

QA.RemoteName = "QACommand" -- (el RemoteEvent solo existe si el modo QA está activo)

function QA.IsActive()
	local config = GameConfig.QA
	if type(config) ~= "table" or config.Enabled ~= true then
		return false
	end
	local ok, studio = pcall(function()
		return RunService:IsStudio()
	end)
	return ok and studio == true
end

-- Modos que se pueden pedir desde el panel (los mismos del juego)
function QA.IsMode(mode)
	return type(mode) == "string" and table.find(GameConfig.Modes, mode) ~= nil
end

return QA
