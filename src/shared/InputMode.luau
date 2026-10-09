-- Cómo se juega en este dispositivo (Fase 15, tras la captura del Galaxy S26 Ultra): UN solo criterio
-- para todo el cliente. Antes cada módulo decidía «móvil» con `TouchEnabled and not KeyboardEnabled`,
-- y algunos Android (el S26 Ultra entre ellos) dicen KeyboardEnabled = true aunque se juegue con los
-- dedos: el juego ponía el HUD de ordenador (ranuras de armas, «PASE · TIENDA», vida grande...).
--
-- Criterio: con pantalla táctil, manda UserInputService.PreferredInput (la API del motor que dice con
-- qué se está jugando: Touch en un teléfono aunque declare teclado). Si el motor no la tiene, se juega
-- con los dedos cuando no hay teclado o no hay ratón (un teléfono no tiene ratón; un portátil táctil
-- sí, y ahí sigue la interfaz de ordenador).
local UserInputService = game:GetService("UserInputService")

local InputMode = {}

function InputMode.TouchUI(): boolean
	if not UserInputService.TouchEnabled then
		return false
	end
	local ok, preferred = pcall(function()
		return (UserInputService :: any).PreferredInput
	end)
	if ok and typeof(preferred) == "EnumItem" then
		local okTouch, touch = pcall(function()
			return (Enum :: any).PreferredInput.Touch
		end)
		if okTouch and touch ~= nil then
			return preferred == touch
		end
	end
	return not UserInputService.KeyboardEnabled or UserInputService.MouseEnabled ~= true
end

return InputMode
