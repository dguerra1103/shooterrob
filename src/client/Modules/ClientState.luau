-- Estado compartido entre los módulos del cliente.
local ClientState = {
	Data = nil, -- datos de progreso (nivel, XP, skins...)
	Settings = nil :: { [string]: any }?, -- ajustes del jugador (los rellena Settings)
	EffectiveQuality = "Media", -- calidad real aplicada ("Auto" ya resuelto); la rellena Settings
	Dead = false, -- pantalla de muerte abierta (la rellena DeathScreen)
	KillcamActive = false, -- se está viendo una killcam (Killcam; el HUD oculta su «ELIMINADO POR»)
	KillcamFinal = false, -- es la killcam final de la partida/ronda (el HUD se esconde entero)
	Emoting = false, -- haciendo un emote (cámara en tercera persona, arma oculta)
	EmoteMenuOpen = false, -- menú de emotes abierto (N)
	TutorialOpen = false, -- tarjeta de controles de la primera partida en pantalla
	WheelOpen = false, -- ruleta diaria abierta
	NewsOpen = false, -- tarjeta de novedades abierta (News)
	HUDEditorOpen = false, -- editor de los controles táctiles abierto (HUDEditor): no se juega
	FovKick = 0, -- empujón de campo de visión (habilidades); lo consume WeaponController
	Shake = 0, -- temblor de cámara pendiente (explosiones cercanas); lo consume WeaponController
	ConcussedUntil = 0, -- aturdido por una explosión cercana hasta este os.clock() (CombatFX)
	SuppressedAt = 0, -- última bala que pasó rozando (os.clock(); CombatFX)
	MenuOpen = false, -- menú del pase/tienda abierto
	VoteOpen = false, -- panel de votación con el ratón libre
	InMainMenu = true, -- pantalla de inicio visible
	ResultsScreen = false, -- la pantalla final del flujo existe (sustituye al cuadro de fin del HUD)
	ResultsActive = false, -- la partida ha acabado y se ve (o está a punto) la pantalla final
	StoreModal = false, -- vista previa o confirmación de la tienda abierta
	RevealOpen = false, -- escena de compra abierta
	ConfirmOpen = false, -- confirmación de compra con monedas abierta
	Aiming = false,
	AimAlpha = 0, -- 0 = cadera, 1 = apuntando
	Sprinting = false,
	SprintToggled = false, -- (táctil) el botón de correr está puesto (es de pulsar y soltar)
	Stamina = 1, -- 0..1 (correr la gasta; Movement)
	Exhausted = false, -- se agotó y aún no se ha recuperado lo bastante para correr
	LandKick = 0, -- golpe de cámara al aterrizar desde alto; lo consume WeaponController
	MinimapBottom = nil :: number?, -- borde de abajo del minimapa (para colocar lo de debajo)
	MinimapLeft = nil :: number?, -- su borde izquierdo (lo de debajo se alinea con él)
	ScoreSpot = nil :: Vector2?, -- (táctil) dónde van los puntos de la baja, junto a la mira (lo calcula HUD)
	ScoreSpotLeft = false, -- (y si van a la izquierda de la mira)
	MinimapSize = nil :: number?, -- su lado
	Sliding = false,
	Crouching = false, -- agachado (C sin correr): más bajo, más lento y más preciso
	CurrentTool = nil,
	CurrentDef = nil,
	Ammo = 0,
	Reloading = false,
	ReloadProgress = 0,
	LastShotTime = 0,
	LastHitPosition = nil :: Vector3?, -- dónde dio tu último disparo a un personaje (números de daño)
	LastHitTime = 0,
	LastHitModel = nil :: Model?, -- a quién dio ese disparo (el destello al impactar)
	VotePanelVisible = false, -- hay votación de mapa en pantalla (la V es para votar, no para inspeccionar)
	Dashing = false, -- impulso (E) en curso: no se puede deslizar a la vez
	MenuClosedAt = 0, -- cuándo se cerró la tienda (la B no revive justo después)
	Bloom = 0, -- apertura extra de la mira por disparos
	Spread = 0, -- dispersión actual (grados)
	QAShotHook = nil :: ((Vector3, { any }) -> ())?, -- modo QA de Studio: dibuja cada disparo (QAPanel)
	QASkinPreview = nil :: string?, -- modo QA de Studio: skin que se ve en primera persona (solo aquí, no da la skin)
	WeaponAction = "None", -- acción del viewmodel ahora (WeaponVisual.ActionPriority; "ADS" si apunta en reposo)

	DataChanged = Instance.new("BindableEvent"),
	SettingsChanged = Instance.new("BindableEvent"), -- (Ajustes: se cambió algo que otros módulos aplican)
	WeaponChanged = Instance.new("BindableEvent"),
	ShotFired = Instance.new("BindableEvent"),
	-- Momentos del arma propia para animaciones y audio (WeaponController):
	-- ("Equip", arma) · ("Fire", arma) · ("ReloadStart", arma, { Empty, Duration }) · ("ReloadCancel", arma)
	-- · ("Inspect", arma) · ("InspectCancel", arma)
	WeaponEvent = Instance.new("BindableEvent"),
}

-- ¿Hay algún menú que impida jugar (disparar, moverse con el ratón...)?
function ClientState.IsBlocked()
	return ClientState.MenuOpen or ClientState.VoteOpen or ClientState.InMainMenu or ClientState.Dead or ClientState.EmoteMenuOpen
		or ClientState.TutorialOpen or ClientState.WheelOpen or ClientState.NewsOpen or ClientState.HUDEditorOpen
end

-- Cuenta atrás de Eliminación: quietos y sin disparar (lo decide el servidor)
-- Ajustes → Efectos de pantalla «Reducidos»: sin desenfoques, destellos ni temblores (accesibilidad)
function ClientState.ReducedFX()
	local settings = ClientState.Settings
	return settings ~= nil and settings.ScreenFX == 0
end

function ClientState.Frozen()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	if ReplicatedStorage:GetAttribute("Frozen") == true then
		return true
	end
	-- (Buscar y destruir: los atacantes esperan unos segundos más en su base, ver Round)
	local held = ReplicatedStorage:GetAttribute("HeldTeam")
	local localPlayer = held and game:GetService("Players").LocalPlayer
	local team = localPlayer and localPlayer.Team
	return team ~= nil and team.Name == held
end

-- El cursor se ve siempre que haya algún menú abierto (cada menú llama a esto al abrirse o cerrarse)
function ClientState.UpdateMouse()
	local blocked = ClientState.IsBlocked()
	game:GetService("UserInputService").MouseIconEnabled = blocked
	-- Botones táctiles del juego: ocultos mientras hay un menú abierto
	-- (los botones táctiles son nuestros, de TouchLayout: se pide aquí para no requerirlo al cargar)
	local okLayout, TouchLayout = pcall(require, script.Parent.TouchLayout)
	if not okLayout then
		return
	end
	-- (cuáles se ven lo decide TouchLayout: menús abiertos, cargas del ataque aéreo, ajustes...)
	TouchLayout.RefreshVisibility()
end

function ClientState.SetData(data)
	if type(data) ~= "table" then
		return
	end
	ClientState.Data = data
	ClientState.DataChanged:Fire(data)
end

return ClientState
