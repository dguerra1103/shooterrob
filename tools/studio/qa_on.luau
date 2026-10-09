-- Activa el modo QA SOLO en la copia abierta en Studio (no toca el repo): GameConfig.QA.Enabled = true
local m = game:GetService("ReplicatedStorage").Shared.GameConfig
local src, n = string.gsub(m.Source, "GameConfig%.QA = { Enabled = false }", "GameConfig.QA = { Enabled = true }")
if n == 1 then m.Source = src end
return "QA activado en Studio: " .. tostring(n == 1 or string.find(m.Source, "QA = { Enabled = true }", 1, true) ~= nil)
