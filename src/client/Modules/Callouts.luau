-- Avisos de los compañeros (como en los shooters por equipos): encima de la cabeza de un compañero
-- (jugador o bot) sale un momento «🔄 ¡Recargando!» cuando recarga y «💣 ¡Granada!» cuando lanza una.
-- Solo los de tu equipo (de los enemigos no se sabe nada) y solo en modos por equipos. Solo en este
-- cliente.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local Callouts = {}

Callouts.Duration = 1.6
Callouts.Range = 140 -- (más lejos no se ve el cartel)

local player = Players.LocalPlayer
local reloading = setmetatable({}, { __mode = "k" }) -- [Tool] = true
local seenGrenades = setmetatable({}, { __mode = "k" }) -- [granada] = true
local bubbles = setmetatable({}, { __mode = "k" }) -- [Model] = { Gui, Token }
local clock = 0

local function teamMode()
	return ReplicatedStorage:GetAttribute("TeamMode") ~= false
end

-- ¿Es un compañero? (jugador de tu equipo o bot de tu equipo; tú no)
local function teammate(model)
	if not model or model == player.Character or not player.Team or not teamMode() then
		return false
	end
	local owner = Players:GetPlayerFromCharacter(model)
	if owner then
		return owner ~= player and owner.Team == player.Team
	end
	return model:GetAttribute("Bot") == true and model:GetAttribute("Team") == player.Team.Name
end

-- Muestra el aviso encima de la cabeza (si ya había uno, lo sustituye)
function Callouts.Show(model, text)
	local head = model and model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return nil
	end
	local camera = workspace.CurrentCamera
	if camera and (head.Position - camera.CFrame.Position).Magnitude > Callouts.Range then
		return nil
	end
	local entry = bubbles[model]
	if not entry or not entry.Gui.Parent then
		local gui = UI.new("BillboardGui", {
			Name = "Callout",
			Size = UDim2.fromOffset(150, 30),
			StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0),
			AlwaysOnTop = true,
			LightInfluence = 0,
			MaxDistance = Callouts.Range,
			Adornee = head,
			Parent = player:WaitForChild("PlayerGui"),
		})
		local label = UI.label({
			Name = "Text",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(20, 26, 36),
			BackgroundTransparency = 0.35,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(150, 220, 255),
			Parent = gui,
		}, { UI.corner(8) })
		entry = { Gui = gui, Label = label, Token = 0 }
		bubbles[model] = entry
	end
	entry.Token += 1
	local token = entry.Token
	entry.Label.Text = text
	entry.Gui.Enabled = true
	task.delay(Callouts.Duration, function()
		if bubbles[model] == entry and entry.Token == token then
			entry.Gui.Enabled = false
		end
	end)
	return entry.Gui
end

local function characters()
	local list = {}
	for _, p in Players:GetPlayers() do
		if p ~= player and p.Character then
			table.insert(list, p.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			if model:IsA("Model") then
				table.insert(list, model)
			end
		end
	end
	return list
end

local function modelNamed(name)
	local p = Players:FindFirstChild(name)
	if p and p:IsA("Player") then
		return p.Character
	end
	local bots = workspace:FindFirstChild("Bots")
	return bots and bots:FindFirstChild(name) or nil
end

function Callouts.Update(dt)
	clock += dt or 0
	if clock < 0.15 then
		return
	end
	clock = 0
	if ClientState.InMainMenu then
		return
	end
	-- Recargas
	for _, model in characters() do
		local tool = model:FindFirstChildOfClass("Tool")
		if tool and tool:GetAttribute("Weapon") then
			local now = tool:GetAttribute("Reloading") == true
			if now and not reloading[tool] and teammate(model) then
				Callouts.Show(model, "🔄 ¡Recargando!")
			end
			reloading[tool] = now or nil
		end
	end
	-- Granadas recién lanzadas por compañeros
	local folder = workspace:FindFirstChild("Grenades")
	if folder then
		for _, grenade in folder:GetChildren() do
			if not seenGrenades[grenade] then
				seenGrenades[grenade] = true
				local thrower = grenade:GetAttribute("Thrower")
				local model = type(thrower) == "string" and modelNamed(thrower) or nil
				if model and teammate(model) then
					Callouts.Show(model, "💣 ¡Granada!")
				end
			end
		end
	end
end

function Callouts.Init()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(Callouts.Update, dt)
		if not ok then
			warn("[Callouts]", err)
		end
	end)
end

return Callouts
