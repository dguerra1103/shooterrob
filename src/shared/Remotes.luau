-- Crea (servidor) o espera (cliente) todos los RemoteEvents/RemoteFunctions del juego.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = {
	"Fire", -- cliente -> servidor: disparo
	"Reload", -- cliente -> servidor: recargar
	"Melee", -- cliente -> servidor: cuchillazo
	"EquipSkin", -- cliente -> servidor: equipar skin
	"SetPrimary", -- cliente -> servidor: elegir arma principal
	"LeaveMenu", -- cliente -> servidor: ha salido de la pantalla de inicio
	"SetSecondary", -- cliente -> servidor: elegir arma secundaria
	"EquipOutfit", -- cliente -> servidor: equipar traje de operador
	"VoteMap", -- cliente -> servidor: voto de mapa/modo
	"SetCamo", -- cliente -> servidor: camuflaje de maestría para un arma
	"EquipKillEffect", -- cliente -> servidor: equipar efecto de eliminación
	"KillFX", -- servidor -> clientes: efecto de eliminación (posición, efecto, color)
	"ShotFX", -- servidor -> clientes: efectos de disparo de otros jugadores
	"HitConfirm", -- servidor -> cliente: confirmación de impacto (hitmarker)
	"KillFeed", -- servidor -> clientes: registro de bajas
	"Notify", -- servidor -> cliente(s): mensajes en pantalla
	"DataUpdate", -- servidor -> cliente: datos de progreso
	"Died", -- servidor -> cliente: quién te eliminó
	"RoundEnd", -- servidor -> clientes: resultado de la ronda
}
local FUNCTIONS = {
	"GetData",
	"BuyItem", -- comprar arma/skin/traje con monedas
	"ClaimDaily", -- recoger la recompensa diaria
	"OpenCrate", -- abrir una caja
	"RerollChallenge", -- cambiar un reto diario
}

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENTS do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
	for _, name in FUNCTIONS do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in EVENTS do
		Remotes[name] = folder:WaitForChild(name)
	end
	for _, name in FUNCTIONS do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
