-- Estado compartido entre los módulos del cliente.
local ClientState = {
	Data = nil, -- datos de progreso (nivel, XP, skins...)
	MenuOpen = false,
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

function ClientState.SetData(data)
	if type(data) ~= "table" then
		return
	end
	ClientState.Data = data
	ClientState.DataChanged:Fire(data)
end

return ClientState
