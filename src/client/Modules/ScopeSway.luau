-- Visor de francotirador realista: con el visor puesto la mira nunca está del todo quieta (el pulso y
-- la respiración la mueven en un "ocho" lento y pequeño). Con Mayús (o el stick izquierdo pulsado en el
-- mando) aguantas la respiración unos 3,5 s y la mira se queda casi quieta; al acabarse el aire se
-- mueve más un momento hasta recuperarlo. Agachado se mueve menos; en el móvil, la mitad (allí no hay
-- tecla para aguantar). WeaponController aplica a la cámara lo que devuelve Update cada fotograma.
local UserInputService = game:GetService("UserInputService")

local ClientState = require(script.Parent.ClientState)

local ScopeSway = {}

ScopeSway.Amplitude = math.rad(0.22) -- cuánto se mueve la mira con el visor (sin aguantar)
ScopeSway.HoldTime = 3.5 -- segundos que se aguanta la respiración
ScopeSway.RecoverTime = 2.5 -- segundos para recuperar todo el aire
ScopeSway.ExhaleTime = 1.2 -- al quedarte sin aire, este rato se mueve el doble
ScopeSway.Holding = false -- aguantando la respiración ahora mismo (el HUD lo dice en el visor)
ScopeSway.Breath = 1 -- aire que queda (0..1)

local exhaleUntil = 0
local amp = 0
local lastPitch, lastYaw = 0, 0

local function holdPressed()
	local ok, down = pcall(function()
		if UserInputService:GetFocusedTextBox() then
			return false
		end
		return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL3)
	end)
	return ok and down == true
end

local function touchOnly()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Cuánto se mueve ahora mismo (radianes; 0 sin visor)
function ScopeSway.Amount()
	return amp
end

-- ¿Sin aire (recuperándolo tras aguantar demasiado)?
function ScopeSway.OutOfBreath()
	return os.clock() < exhaleUntil
end

-- Devuelve el giro (cabeceo, guiñada) que hay que sumar a la cámara en ESTE fotograma: la diferencia
-- con el balanceo del anterior (así no se acumula y al quitar el visor vuelve solo a su sitio)
function ScopeSway.Update(dt, scoped)
	local now = os.clock()
	local holding = false
	if scoped and now >= exhaleUntil and ScopeSway.Breath > 0 and holdPressed() then
		holding = true
		ScopeSway.Breath = math.max(0, ScopeSway.Breath - dt / ScopeSway.HoldTime)
		if ScopeSway.Breath <= 0 then
			exhaleUntil = now + ScopeSway.ExhaleTime
		end
	else
		ScopeSway.Breath = math.min(1, ScopeSway.Breath + dt / ScopeSway.RecoverTime)
	end
	ScopeSway.Holding = holding
	local target = 0
	if scoped then
		target = ScopeSway.Amplitude
		if holding then
			target *= 0.08
		elseif now < exhaleUntil then
			target *= 2
		end
		if ClientState.Crouching then
			target *= 0.6
		end
		if touchOnly() then
			target *= 0.5
		end
	end
	amp += (target - amp) * math.min(1, dt * 4)
	local pitch = (math.sin(now * 0.9) * 0.6 + math.sin(now * 2.3) * 0.15) * amp
	local yaw = (math.sin(now * 0.55) + math.sin(now * 1.7) * 0.2) * amp
	local dPitch, dYaw = pitch - lastPitch, yaw - lastYaw
	lastPitch, lastYaw = pitch, yaw
	return dPitch, dYaw
end

-- Al morir o reaparecer: todo a cero (la cámara nueva no arrastra el balanceo de antes)
function ScopeSway.Reset()
	amp, lastPitch, lastYaw = 0, 0, 0
	exhaleUntil = 0
	ScopeSway.Breath = 1
	ScopeSway.Holding = false
end

return ScopeSway
