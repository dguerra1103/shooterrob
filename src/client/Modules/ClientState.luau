-- Estado compartido entre los módulos del cliente.
local ClientState = {
	Data = nil, -- datos de progreso (nivel, XP, skins...)
	Settings = nil :: { [string]: any }?, -- ajustes del jugador (los rellena Settings)
	EffectiveQuality = "Media", -- calidad real aplicada ("Auto" ya resuelto); la rellena Settings
	Dead = false, -- pantalla de muerte abierta (la rellena DeathScreen)
	Emoting = false, -- haciendo un emote (cámara en tercera persona, arma oculta)
	EmoteMenuOpen = false, -- menú de emotes abierto (N)
	TutorialOpen = false, -- tarjeta de controles de la primera partida en pantalla
	FovKick = 0, -- empujón de campo de visión (habilidades); lo consume WeaponController
	Shake = 0, -- temblor de cámara pendiente (explosiones cercanas); lo consume WeaponController
	MenuOpen = false, -- menú del pase/tienda abierto
	VoteOpen = false, -- panel de votación con el ratón libre
	InMainMenu = true, -- pantalla de inicio visible
	Aiming = false,
	AimAlpha = 0, -- 0 = cadera, 1 = apuntando
	Sprinting = false,
	Sliding = false,
	CurrentTool = nil,
	CurrentDef = nil,
	Ammo = 0,
	Reloading = false,
	ReloadProgress = 0,
	LastShotTime = 0,
	LastHitPosition = nil :: Vector3?, -- dónde dio tu último disparo a un personaje (números de daño)
	LastHitTime = 0,
	VotePanelVisible = false, -- hay votación de mapa en pantalla (la V es para votar, no para inspeccionar)
	Dashing = false, -- impulso (E) en curso: no se puede deslizar a la vez
	MenuClosedAt = 0, -- cuándo se cerró la tienda (la B no revive justo después)
	Bloom = 0, -- apertura extra de la mira por disparos
	Spread = 0, -- dispersión actual (grados)

	DataChanged = Instance.new("BindableEvent"),
	WeaponChanged = Instance.new("BindableEvent"),
	ShotFired = Instance.new("BindableEvent"),
}

-- ¿Hay algún menú que impida jugar (disparar, moverse con el ratón...)?
function ClientState.IsBlocked()
	return ClientState.MenuOpen or ClientState.VoteOpen or ClientState.InMainMenu or ClientState.Dead or ClientState.EmoteMenuOpen or ClientState.TutorialOpen
end

-- Cuenta atrás de Eliminación: quietos y sin disparar (lo decide el servidor)
function ClientState.Frozen()
	return game:GetService("ReplicatedStorage"):GetAttribute("Frozen") == true
end

-- El cursor se ve siempre que haya algún menú abierto (cada menú llama a esto al abrirse o cerrarse)
function ClientState.UpdateMouse()
	local blocked = ClientState.IsBlocked()
	game:GetService("UserInputService").MouseIconEnabled = blocked
	-- Botones táctiles del juego: ocultos mientras hay un menú abierto
	local cas = game:GetService("ContextActionService")
	for _, name in { "Fire", "Aim", "Reload", "Melee", "SwapWeapon", "Sprint", "Slide", "Grenade", "Airstrike", "Emotes", "Scoreboard" } do
		local button = cas:GetButton(name)
		if button then
			button.Visible = not blocked
		end
	end
end

function ClientState.SetData(data)
	if type(data) ~= "table" then
		return
	end
	ClientState.Data = data
	ClientState.DataChanged:Fire(data)
end

return ClientState
