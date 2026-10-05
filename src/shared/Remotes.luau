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
	"EnterMenu", -- cliente -> servidor: vuelve a la pantalla de inicio (escudo y fuera de juego)
	"RespawnNow", -- cliente -> servidor: "Regenerar ahora" tras morir
	"SetSecondary", -- cliente -> servidor: elegir arma secundaria
	"SetMelee", -- cliente -> servidor: elegir arma cuerpo a cuerpo (cuchillo, martillo, katana)
	"TutorialDone", -- cliente -> servidor: ya ha visto la tarjeta de controles
	"NewsSeen", -- cliente -> servidor: ya ha visto las novedades (GameConfig.News)
	"EquipOutfit", -- cliente -> servidor: equipar traje de operador
	"VoteMap", -- cliente -> servidor: voto de mapa/modo
	"SetCamo", -- cliente -> servidor: camuflaje de maestría para un arma
	"EquipKillEffect", -- cliente -> servidor: equipar efecto de eliminación
	"EquipCharm", -- cliente -> servidor: equipar colgante de arma (Charms)
	"EquipSpray", -- cliente -> servidor: equipar grafiti (Sprays)
	"EquipTitle", -- cliente -> servidor: elegir título (Titles)
	"Spray", -- cliente -> servidor: pintar el grafiti en un punto (el servidor lo comprueba)
	"SaveSettings", -- cliente -> servidor: ajustes (calidad gráfica, FOV, sensibilidad)
	"KillFX", -- servidor -> clientes: efecto de eliminación (posición, efecto, color)
	"ThrowGrenade", -- cliente -> servidor: lanzar granada (dirección)
	"ExplosionFX", -- servidor -> clientes: explosión de granada (posición, radio)
	"CallAirstrike", -- cliente -> servidor: pedir el ataque aéreo (punto objetivo)
	"AirstrikeMark", -- servidor -> clientes: marcas rojas donde va a caer el ataque aéreo
	"ShotFX", -- servidor -> clientes: efectos de disparo de otros jugadores
	"HitConfirm", -- servidor -> cliente: confirmación de impacto (hitmarker)
	"KillFeed", -- servidor -> clientes: registro de bajas
	"Notify", -- servidor -> cliente(s): mensajes en pantalla
	"DataUpdate", -- servidor -> cliente: datos de progreso
	"Died", -- servidor -> cliente: quién te eliminó
	"RoundEnd", -- servidor -> clientes: resultado de la ronda
	"FinalKillcam", -- servidor -> clientes: repetición de la última baja de la partida/ronda (Killcam)
	"AimPitch", -- cliente -> servidor: hacia dónde mira arriba/abajo (los demás ven el arma inclinada)
	"Flashlight", -- cliente -> servidor: linterna del arma encendida o apagada (de noche; Flashlights)
	"MatchSummary", -- servidor -> cliente: resumen de tu partida (XP, monedas, bajas, mejor racha)
}
local FUNCTIONS = {
	"GetData",
	"BuyItem", -- comprar arma/skin/traje con monedas
	"ClaimDaily", -- recoger la recompensa diaria
	"OpenCrate", -- abrir una caja
	"RerollChallenge", -- cambiar un reto diario
	"InstantRevive", -- revivir donde moriste (gasta un revivir)
	"UsePotion", -- habilidad Poción: cura con el tiempo (el servidor controla la recarga)
	"ClaimGift", -- recoger el siguiente regalo por tiempo jugado
	"SpinWheel", -- girar la ruleta diaria (gratis o gastando un giro comprado)
	"ClaimAchievement", -- reclamar el premio de un logro (GameConfig.Achievements)
	"ClaimGroup", -- reclamar el premio por unirse al grupo (GameConfig.Group)
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
