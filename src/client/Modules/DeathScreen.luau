-- Pantalla de muerte (estilo shooters de Roblox):
--   * Observas al que te eliminó en tercera persona (clic / clic derecho cambia de jugador)
--   * VOLVER AL MENÚ, REVIVIR INSTANTÁNEO (B, gasta un revivir: vuelves donde caíste) y
--     REGENERAR AHORA (Espacio o F, a partir de GameConfig.RespawnNowDelay)
-- Sin revivir disponibles, el botón abre la compra del pack (si está configurado en Shop).
-- En plena ronda de Eliminación (NoRespawn) no hay revivir ni regenerar: se observa hasta la siguiente.
-- También se puede observar a los bots (modelos en workspace.Bots).
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Shop = require(Shared.Shop)
local MonetizationConfig = require(Shared.Economy.MonetizationConfig)
local Sounds = require(Shared.Sounds)

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)
local Killcam = require(script.Parent.Killcam)
local MainMenu = require(script.Parent.MainMenu)
local Menu = require(script.Parent.Menu)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local DeathScreen = {}

local gui: any = nil
local refs: { [string]: any } = {}
local deathTime = 0
local targets = {} -- jugadores (Player) o bots (Model) que se pueden observar
local targetIndex = 0
local spectating = nil -- Player o bot observado
local reviving = false
local originalZoom = { 0.5, 400 } -- zoom de la cámara del jugador (se restaura al reaparecer)

local BLUE = Color3.fromRGB(40, 140, 255)
local PINK = Color3.fromRGB(255, 70, 200)
local GREEN = Color3.fromRGB(70, 220, 60)

-- Personaje de un objetivo: el Character de un jugador o el propio modelo de un bot
local function characterOf(target)
	if target:IsA("Player") then
		return target.Character
	end
	return target.Parent and target or nil
end

local function teamOf(target)
	if target:IsA("Player") then
		return target.Team
	end
	local name = target:GetAttribute("Team")
	local team = name and name ~= "" and Teams:FindFirstChild(name)
	return team and team:IsA("Team") and team or nil
end

local function alive(p)
	local character = characterOf(p)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0, humanoid
end

local function noRespawn()
	return ReplicatedStorage:GetAttribute("NoRespawn") == true
end

-- Cámara en tercera persona detrás del jugador observado
local function watch(target)
	spectating = target
	local ok, humanoid = alive(target)
	if not ok then
		return
	end
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = 10
	player.CameraMaxZoomDistance = 14
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	refs.SpectateName.Text = target:IsA("Player") and (target.DisplayName .. " (" .. target.Name .. ")") or target.Name
	refs.SpectatePanel.Visible = true
end

local function stopWatching()
	spectating = nil
	refs.SpectatePanel.Visible = false
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function restoreCamera()
	player.CameraMinZoomDistance = originalZoom[1]
	player.CameraMaxZoomDistance = originalZoom[2]
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

-- En Eliminación solo se observa a compañeros (si no, se podría chivar dónde están los enemigos)
local function canWatch(target)
	if target:IsA("Player") and target:GetAttribute("InMenu") then
		return false
	end
	if noRespawn() and player.Team then
		return teamOf(target) == player.Team
	end
	return true
end

local function refreshTargets(firstChoice)
	targets = {}
	for _, p in Players:GetPlayers() do
		if p ~= player and alive(p) and canWatch(p) then
			table.insert(targets, p)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		for _, model in bots:GetChildren() do
			if model:IsA("Model") and alive(model) and canWatch(model) then
				table.insert(targets, model)
			end
		end
	end
	-- Primero el que te eliminó, luego tus compañeros
	local function rank(p)
		if p == firstChoice then
			return 0
		end
		return (player.Team and teamOf(p) == player.Team) and 1 or 2
	end
	table.sort(targets, function(a, b)
		return rank(a) < rank(b)
	end)
end

---------------------------------------------------------------------------
-- Killcam al morir (ver Killcam): unos segundos desde los ojos del que te eliminó, mirando hacia donde
-- estabas. Luego sigue la pantalla de muerte de siempre (observar al que te eliminó). Clic o toque:
-- saltarla. No hay en los modos de una sola vida (enseñaría en directo dónde está el enemigo) ni con
-- granadas o ataques aéreos, ni si al morir no había línea de visión (se vería una pared).
---------------------------------------------------------------------------
DeathScreen.KillcamEnabled = true

local spectateAfterKillcam -- (se define más abajo)

-- Empieza la repetición si hay suficiente historia del que te eliminó; si no, devuelve false
local function startKillcam(target, weaponName)
	if not DeathScreen.KillcamEnabled or not target or noRespawn() then
		return false
	end
	if weaponName == "Grenade" or weaponName == "Airstrike" then
		return false
	end
	local killerModel = characterOf(target)
	local myModel = player.Character
	if not killerModel or not myModel or killerModel == myModel then
		return false
	end
	local started = Killcam.Play({
		Killer = killerModel,
		Victim = myModel,
		At = deathTime,
		Title = "▶ KILLCAM",
		Name = Killcam.Caption(target, weaponName),
		CheckSight = true,
		OnEnd = function()
			if ClientState.Dead then
				spectateAfterKillcam(target)
			end
		end,
	})
	if started then
		refs.SpectatePanel.Visible = false
	end
	return started
end

DeathScreen.KillcamActive = function()
	return Killcam.Active()
end

local function cycle(step)
	-- (durante la killcam, el clic la salta)
	if Killcam.Active() then
		Killcam.Stop(true)
		return
	end
	refreshTargets(spectating)
	if #targets == 0 then
		stopWatching()
		return
	end
	local current = spectating and table.find(targets, spectating) or 0
	targetIndex = ((current - 1 + step) % #targets) + 1
	watch(targets[targetIndex])
end

local function revivesLeft()
	local data = ClientState.Data
	return data and data.Revives or 0
end

local function toast(text)
	refs.Toast.Text = text
	refs.Toast.Visible = true
	task.delay(2, function()
		if refs.Toast.Text == text then
			refs.Toast.Visible = false
		end
	end)
end

local function tryRevive()
	if not ClientState.Dead or reviving then
		return
	end
	if noRespawn() then
		toast("Una sola vida por ronda")
		return
	end
	if revivesLeft() <= 0 then
		-- (revivir donde caíste es ventaja en combate: ya no se vende con Robux, solo se gana jugando)
		local pack = Shop.RevivePacks[1]
		if MonetizationConfig.Rules.SellRevives and pack and pack.ProductId ~= 0 then
			MarketplaceService:PromptProductPurchase(player, pack.ProductId)
		else
			toast("No te quedan revivir")
		end
		return
	end
	reviving = true
	Sounds.Play("Click")
	local ok, result, reason = pcall(function()
		return Remotes.InstantRevive:InvokeServer()
	end)
	reviving = false
	if not ok or not result then
		toast(reason or "No se pudo revivir")
	end
end

local function respawnNow()
	if ClientState.Dead and os.clock() - deathTime >= GameConfig.RespawnNowDelay and not noRespawn() then
		Sounds.Play("Click")
		Remotes.RespawnNow:FireServer()
	end
end

local function close()
	-- (la killcam final del servidor sigue aunque reaparezcas; la de tu muerte no)
	if not ClientState.KillcamFinal then
		Killcam.Stop(false)
	end
	if not ClientState.Dead then
		return
	end
	ClientState.Dead = false
	gui.Enabled = false
	stopWatching()
	restoreCamera()
	ClientState.UpdateMouse()
end

local function open(killerName, weaponName)
	ClientState.Dead = true
	-- La tienda se cierra al morir (si no, la B que iba a cerrarla gastaría un revivir)
	Menu.Close()
	deathTime = os.clock()
	gui.Enabled = true
	refs.Toast.Visible = false
	ClientState.UpdateMouse()
	local bots = workspace:FindFirstChild("Bots")
	local killer = killerName and (Players:FindFirstChild(killerName) or (bots and bots:FindFirstChild(killerName)))
	-- Primero la killcam (si hay con qué); al acabar, a observar como siempre
	if killer and startKillcam(killer, weaponName) then
		return
	end
	spectateAfterKillcam(killer)
end

function spectateAfterKillcam(killer)
	refreshTargets(killer)
	if killer and alive(killer) and canWatch(killer) then
		watch(killer)
	elseif #targets > 0 then
		watch(targets[1])
	else
		refs.SpectatePanel.Visible = false
	end
end

-- Botón grande con texto encima ("Presiona B") y barra debajo
local function actionButton(text, hint, color, x)
	local holder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, x, 1, -150),
		Size = UDim2.fromOffset(280, 110),
		BackgroundTransparency = 1,
		Parent = refs.Bottom,
	})
	if hint then
		UI.label({
			Size = UDim2.new(1, 0, 0, 26),
			Text = hint,
			TextSize = 22,
			Parent = holder,
		})
	end
	local button = UI.button({
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 58),
		Text = text,
		TextSize = 26,
		BackgroundColor3 = color,
		Parent = holder,
	}, { UI.stroke(Color3.new(1, 1, 1), 3, 0), UI.gloss() })
	local bar = UI.new("Frame", {
		Position = UDim2.fromOffset(6, 92),
		Size = UDim2.new(1, -12, 0, 14),
		BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.65),
		Parent = holder,
	}, { UI.corner(7) })
	local fill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		Parent = bar,
	}, { UI.corner(7) })
	return holder, button, fill
end

local function build()
	gui = UI.new("ScreenGui", {
		Name = "DeathScreen",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 3,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Libera el ratón aunque la cámara esté en primera persona
	UI.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Parent = gui })

	refs.Bottom = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	local scale = UI.new("UIScale", { Parent = refs.Bottom })
	local function rescale()
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.55, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	local _, menuButton = actionButton("VOLVER AL MENÚ", nil, BLUE, -300)
	local reviveHolder, reviveButton, reviveFill = actionButton("REVIVIR INSTANTÁNEO", "Presiona B", PINK, 0)
	local respawnHolder, respawnButton, respawnFill = actionButton("REGENERAR AHORA", "Presiona Espacio o F", GREEN, 300)
	refs.ReviveButton, refs.ReviveFill, refs.RespawnButton, refs.RespawnFill = reviveButton, reviveFill, respawnButton, respawnFill
	refs.ReviveHolder, refs.RespawnHolder = reviveHolder, respawnHolder
	-- Eliminación: en lugar de revivir/regenerar, un aviso
	refs.WaitLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 150, 1, -170),
		Size = UDim2.fromOffset(560, 60),
		Text = "UNA VIDA POR RONDA\nEspera a la siguiente ronda",
		TextSize = 26,
		TextColor3 = Color3.fromRGB(255, 220, 90),
		Visible = false,
		Parent = refs.Bottom,
	})

	-- Corazón con alas y "N restantes"
	refs.ReviveBadge = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, -6, 0, 22),
		Size = UDim2.fromOffset(150, 30),
		Rotation = -14,
		Text = "",
		TextSize = 22,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = reviveHolder,
	})
	UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, -2, 0, 58),
		Size = UDim2.fromOffset(60, 60),
		Text = "💖",
		TextSize = 48,
		Parent = reviveHolder,
	})

	menuButton.Activated:Connect(function()
		Sounds.Play("Click")
		close()
		MainMenu.Show()
	end)
	reviveButton.Activated:Connect(tryRevive)
	respawnButton.Activated:Connect(respawnNow)

	-- Panel de observar (izquierda)
	refs.SpectatePanel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 30, 0.5, 20),
		Size = UDim2.fromOffset(440, 220),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = refs.Bottom,
	})
	refs.SpectateName = UI.label({
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.SpectatePanel,
	})
	UI.label({
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "Haz clic / clic derecho para cambiar",
		TextSize = 20,
		TextColor3 = Color3.fromRGB(215, 215, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.SpectatePanel,
	})
	local stop = UI.button({
		Position = UDim2.fromOffset(0, 90),
		Size = UDim2.fromOffset(230, 46),
		Text = "DEJAR DE OBSERVAR",
		TextSize = 20,
		BackgroundColor3 = Color3.fromRGB(230, 50, 60),
		Parent = refs.SpectatePanel,
	}, { UI.stroke(Color3.new(1, 1, 1), 2, 0), UI.gloss() })
	stop.Activated:Connect(function()
		Sounds.Play("Click")
		stopWatching()
	end)

	refs.Toast = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -270),
		Size = UDim2.fromOffset(500, 34),
		Text = "",
		TextSize = 26,
		TextColor3 = Color3.fromRGB(255, 120, 140),
		Visible = false,
		Parent = refs.Bottom,
	})
end

local function update()
	if not ClientState.Dead then
		return
	end
	local oneLife = noRespawn()
	refs.ReviveHolder.Visible = not oneLife
	refs.RespawnHolder.Visible = not oneLife
	refs.WaitLabel.Visible = oneLife
	local elapsed = os.clock() - deathTime
	-- Revivir: la barra se vacía mientras queda tiempo para usarlo
	local reviveWindow = math.clamp(1 - elapsed / GameConfig.RespawnTime, 0, 1)
	refs.ReviveFill.Size = UDim2.fromScale(reviveWindow, 1)
	local left = revivesLeft()
	refs.ReviveBadge.Text = left > 0 and (left .. " restantes") or (MonetizationConfig.Rules.SellRevives and "¡Consigue más!" or "Se ganan jugando")
	refs.ReviveButton.AutoButtonColor = reviveWindow > 0
	-- Regenerar: la barra se llena hasta que se puede pulsar
	local charge = math.clamp(elapsed / GameConfig.RespawnNowDelay, 0, 1)
	refs.RespawnFill.Size = UDim2.fromScale(charge, 1)
	refs.RespawnButton.BackgroundTransparency = charge >= 1 and 0 or 0.35
	-- Si el observado muere o se va, pasa al siguiente
	if spectating and not alive(spectating) then
		cycle(1)
	end
end

function DeathScreen.Init()
	originalZoom = { player.CameraMinZoomDistance, player.CameraMaxZoomDistance }
	build()
	Remotes.Died.OnClientEvent:Connect(open)
	-- Fin de partida: la pantalla final ocupa todo (si no, esta se quedaría debajo de la escena)
	ReplicatedStorage:GetAttributeChangedSignal("State"):Connect(function()
		if ReplicatedStorage:GetAttribute("State") == "Ended" and ClientState.ResultsScreen then
			close()
		end
	end)
	player.CharacterAdded:Connect(function(character)
		close()
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid and not ClientState.InMainMenu then
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
		end
	end)
	-- Las teclas B, F y Espacio están enlazadas con ContextActionService (menú, cuchillo, salto), así que
	-- llegan marcadas como "procesadas": solo se ignoran si se está escribiendo en el chat. Los clics sí se
	-- ignoran cuando caen sobre un botón de la interfaz.
	UserInputService.InputBegan:Connect(function(input, processed)
		if not ClientState.Dead or UserInputService:GetFocusedTextBox() then
			return
		end
		local isClick = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.Touch
		if isClick and processed then
			return
		end
		-- (en el móvil, tocar la pantalla salta la killcam)
		if input.UserInputType == Enum.UserInputType.Touch then
			if Killcam.Active() then
				Killcam.Stop(true)
			end
			return
		end
		if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.ButtonY then
			-- No gasta un revivir si la B era para cerrar la tienda
			if not ClientState.MenuOpen and os.clock() - ClientState.MenuClosedAt > 1 then
				tryRevive()
			end
		elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonA then
			respawnNow()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR1 then
			cycle(1)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL1 then
			cycle(-1)
		end
	end)
	RunService.RenderStepped:Connect(update)
	-- Muerto en Eliminación y de vuelta desde la pantalla de inicio: vuelve a la pantalla de muerte
	-- (se observa a los compañeros hasta la siguiente ronda en vez de quedarse mirando el cuerpo)
	RunService.Heartbeat:Connect(function()
		if ClientState.Dead or ClientState.InMainMenu or not noRespawn() then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			open(nil)
		end
	end)
end

return DeathScreen
