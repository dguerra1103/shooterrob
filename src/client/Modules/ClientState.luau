-- Estado compartido entre los módulos del cliente.
local ClientState = {
	Data = nil, -- datos de progreso (nivel, XP, skins...)
	Settings = nil :: { [string]: any }?, -- ajustes del jugador (los rellena Settings)
	EffectiveQuality = "Media", -- calidad real aplicada ("Auto" ya resuelto); la rellena Settings
	Dead = false, -- pantalla de muerte abierta (la rellena DeathScreen)
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
	Bloom = 0, -- apertura extra de la mira por disparos
	Spread = 0, -- dispersión actual (grados)

	DataChanged = Instance.new("BindableEvent"),
	WeaponChanged = Instance.new("BindableEvent"),
	ShotFired = Instance.new("BindableEvent"),
}

-- ¿Hay algún menú que impida jugar (disparar, moverse con el ratón...)?
function ClientState.IsBlocked()
	return ClientState.MenuOpen or ClientState.VoteOpen or ClientState.InMainMenu or ClientState.Dead
end

-- El cursor se ve siempre que haya algún menú abierto (cada menú llama a esto al abrirse o cerrarse)
function ClientState.UpdateMouse()
	local blocked = ClientState.IsBlocked()
	game:GetService("UserInputService").MouseIconEnabled = blocked
	-- Botones táctiles del juego: ocultos mientras hay un menú abierto
	local cas = game:GetService("ContextActionService")
	for _, name in { "Fire", "Aim", "Reload", "Melee", "SwapWeapon", "Sprint", "Slide", "Grenade", "Airstrike" } do
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
