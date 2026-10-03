-- Estado compartido entre los módulos del cliente.
local ClientState = {
	Data = nil, -- datos de progreso (nivel, XP, skins...)
	Settings = nil :: { [string]: any }?, -- ajustes del jugador (los rellena Settings)
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
	return ClientState.MenuOpen or ClientState.VoteOpen or ClientState.InMainMenu
end

-- El cursor se ve siempre que haya algún menú abierto (cada menú llama a esto al abrirse o cerrarse)
function ClientState.UpdateMouse()
	game:GetService("UserInputService").MouseIconEnabled = ClientState.IsBlocked()
end

function ClientState.SetData(data)
	if type(data) ~= "table" then
		return
	end
	ClientState.Data = data
	ClientState.DataChanged:Fire(data)
end

return ClientState
