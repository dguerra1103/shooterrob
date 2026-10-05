-- Pantalla de carga entre partidas (como en los shooters): mientras el servidor construye el mapa
-- nuevo (atributo LoadingMap de ReplicatedStorage) se tapa todo con el nombre del mapa y un consejo
-- de juego, y luego se va con un fundido.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)
local ClientState = require(script.Parent.ClientState)

local LoadingScreen = {}

local TIPS = {
	"Agáchate (C o el botón Agachar): apuntas más estable y eres más difícil de acertar.",
	"Si una granada enemiga cae cerca, verás un 💣 rojo alrededor de la mira: ¡aléjate!",
	"Con 3 bajas seguidas consigues el Radar; con 5, el Ataque aéreo.",
	"En Buscar y destruir solo el portador puede plantar: si cae, recoge la bomba.",
	"Un destello en una ventana es un tirador enemigo apuntándote.",
	"Los pasos del enemigo se oyen: escucha antes de girar la esquina.",
	"La vida se recupera sola si dejas de recibir daño unos segundos.",
	"Disparar sin silenciador te marca en rojo en el minimapa del rival.",
	"Las vallas y barandillas se pueden atravesar a tiros.",
	"Elige tu ventaja en Ajustes: Ligero, Persistente o Fantasma.",
}

local player = Players.LocalPlayer
local gui, panel, title, tip
local shown = false

local function show(mapName)
	title.Text = UI.upper(tostring(mapName))
	tip.Text = "💡 " .. TIPS[math.random(1, #TIPS)]
	gui.Enabled = true
	if not shown then
		shown = true
		panel.GroupTransparency = 1
		TweenService:Create(panel, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()
	end
end

local function hide()
	if not shown then
		return
	end
	shown = false
	local fade = TweenService:Create(panel, TweenInfo.new(0.6), { GroupTransparency = 1 })
	fade.Completed:Once(function()
		if not shown then
			gui.Enabled = false
		end
	end)
	fade:Play()
end

local function refresh()
	local mapName = ReplicatedStorage:GetAttribute("LoadingMap")
	-- (en la pantalla de inicio no: taparía el menú, la tienda y las noticias)
	if mapName and not ClientState.InMainMenu then
		show(mapName)
	else
		hide()
	end
end

function LoadingScreen.Init()
	gui = UI.new("ScreenGui", {
		Name = "LoadingScreen",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 7, -- (por debajo de la presentación de la partida)
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	panel = UI.new("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 12, 16),
		GroupTransparency = 1,
		Parent = gui,
	})
	UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.new(0.9, 0, 0, 26),
		Text = "CARGANDO MAPA…",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(255, 210, 90),
		Parent = panel,
	})
	title = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0, 56),
		Text = "",
		TextSize = 48,
		Parent = panel,
	})
	tip = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.66, 0),
		Size = UDim2.new(0.8, 0, 0, 48),
		Text = "",
		TextSize = 18,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(200, 205, 220),
		Parent = panel,
	})
	ReplicatedStorage:GetAttributeChangedSignal("LoadingMap"):Connect(refresh)
	refresh()
end

LoadingScreen.Refresh = refresh
return LoadingScreen
