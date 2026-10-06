-- Pantalla de inicio: ahora es el flujo completo de menús (ver Flow/FlowController). Este módulo
-- solo lo arranca con todas sus pantallas y mantiene la entrada de siempre para el resto del juego
-- (MainMenu.Show desde la pantalla de muerte). La ScreenGui sigue llamándose "MainMenu".
local Flow = script.Parent:WaitForChild("Flow")
local FlowController = require(Flow.FlowController)

local MainMenu = {}

local SCREENS = {
	"Home",
	"Squad",
	"Armory",
	"Operator",
	"Matchmaking",
	"MatchFound",
	"MapIntro",
	"TeamIntro",
	"Loadout",
	"Deploy",
	"Results",
}

-- "Volver al menú" (por ejemplo desde la pantalla de muerte)
function MainMenu.Show()
	FlowController.ReturnToLobby()
end

function MainMenu.Init()
	local screens = {}
	local folder = Flow:WaitForChild("Screens")
	for _, name in SCREENS do
		local module = folder:FindFirstChild(name)
		if module then
			local ok, result = pcall(require, module)
			if ok then
				screens[name] = result
			else
				warn("[MainMenu] " .. name .. ": " .. tostring(result))
			end
		end
	end
	FlowController.Init(screens)
	FlowController.SetState("Home")
end

MainMenu.Flow = FlowController
return MainMenu
