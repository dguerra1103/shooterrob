-- PANTALLA FINAL (ResultsController): sustituye al cuadro de fin de partida del HUD. Se abre con el
-- RoundEnd del servidor (MatchResult real, ver MatchResults) a quien jugó la partida:
--   0,0 s  fundido corto (el HUD se va, nada de la partida se queda flotando)
--   0,3 s  la cámara enseña a tu equipo en una escena 3D dentro del mapa (avatares reales con su arma)
--   0,8 s  VICTORIA / DERROTA + motivo, con su golpe de sonido
--   1,3 s  marcador contando
--   1,7 s  tarjetas de tus compañeros
--   2,2 s  MVP: foco, corona, destello dorado y sus cifras
--   2,8 s  recompensas (XP, monedas, cajas, rango) → barra de nivel → desafíos → desbloqueo
--   3,0 s  JUGAR DE NUEVO (amarillo), VOLVER AL LOBBY, VER MARCADOR
-- Las recompensas llegan aparte (MatchSummary) y solo se pintan las que el servidor ha dado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Remotes = require(Shared.Remotes)
local Catalog = require(Shared.Economy.CosmeticCatalog)
local MonetizationConfig = require(Shared.Economy.MonetizationConfig)

local Modules = script.Parent.Parent.Parent
local ClientState = require(Modules.ClientState)

local Flow = script.Parent.Parent
local Theme = require(Flow.Theme)
local C = require(Flow.Components)
local Transition = require(Flow.Transition)
local UISound = require(Flow.UISound)

local ResultsFolder = Flow.Results
local Data = require(ResultsFolder.Data)
local Stage = require(ResultsFolder.Stage)
local Camera = require(ResultsFolder.Camera)
local Anim = require(ResultsFolder.Anim)
local Components = ResultsFolder.Components
local ResultHeader = require(Components.ResultHeader)
local ScoreDisplay = require(Components.ScoreDisplay)
local PlayerResultCard = require(Components.PlayerResultCard)
local MVPCard = require(Components.MVPCard)
local RewardsPanel = require(Components.RewardsPanel)
local OfferCard = require(Components.OfferCard)
local XPProgress = require(Components.XPProgress)
local UnlockCard = require(Components.UnlockCard)
local ChallengeProgress = require(Components.ChallengeProgress)
local ScoreboardPanel = require(Components.ScoreboardPanel)
local ResultActions = require(Components.ResultActions)

local player = Players.LocalPlayer
local Colors = Theme.Colors

local Results = {}
Results.ReadyForSummary = false -- (las recompensas ya pueden entrar: pasado su momento en la secuencia)

local flow, screen, header, score, cardsRow, bottomRow, rewards, xp, unlock, challenges, scoreboard, actions, offer
local view, summary, stage
local mvpCard
local pendingSummary
local stepConnection
local autoAdvance = true
local nextAt -- (os.clock) cuándo pasa sola a buscar la siguiente partida
local summaryShown = false
local phone = false

-- Orden de las tarjetas de izquierda a derecha (como la formación: 4 · 2 · MVP · 3 · 5)
local CARD_ORDER = { 4, 2, 1, 3, 5 }

---------------------------------------------------------------------------
-- Personajes reales del mundo: ocultos en local mientras se ve la escena
---------------------------------------------------------------------------

local hiddenParts = {}
local function hideWorldCharacters(hidden)
	if not hidden then
		for part in hiddenParts do
			if part.Parent then
				part.LocalTransparencyModifier = 0
			end
		end
		table.clear(hiddenParts)
		return
	end
	local function hideModel(model)
		for _, d in model:GetDescendants() do
			if (d:IsA("BasePart") or d:IsA("Decal")) and not hiddenParts[d] then
				hiddenParts[d] = true
				d.LocalTransparencyModifier = 1
			end
		end
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			hideModel(other.Character)
		end
	end
	local bots = workspace:FindFirstChild("Bots")
	if bots then
		hideModel(bots)
	end
end

---------------------------------------------------------------------------
-- Composición
---------------------------------------------------------------------------

local function applyLayout()
	phone = C.Breakpoint() == "PHONE"
	local width = flow.Root and flow.Root:GetAttribute("VirtualWidth") or 1280
	local margin = phone and 16 or 32
	header.Layout(phone)
	header.Frame.Position = UDim2.fromOffset(margin, phone and 10 or 22)
	score.Layout(phone)
	score.Frame.AnchorPoint = Vector2.new(1, 0)
	score.Frame.Position = UDim2.new(1, -margin, 0, phone and 12 or 30)
	rewards.Layout(phone)
	rewards.Frame.AnchorPoint = Vector2.new(1, 0)
	rewards.Frame.Position = UDim2.new(1, -margin, 0, phone and 104 or 160)
	offer.Layout(phone)
	offer.Frame.AnchorPoint = Vector2.new(1, 0)
	offer.Frame.Position = UDim2.new(1, -margin, 0, phone and 202 or 284)
	actions.Layout(phone)
	actions.Frame.AnchorPoint = Vector2.new(0.5, 1)
	actions.Frame.Position = UDim2.new(0.5, 0, 1, phone and -10 or -14)
	actions.Frame.Size = UDim2.new(1, -margin * 2, 0, phone and 56 or 64)
	-- Paneles de abajo (nivel, desafíos, desbloqueo): en el teléfono solo el nivel, a la izquierda
	local panelWidth = math.min(380, math.floor((width - margin * 2 - 24) / 3))
	xp.Layout(phone)
	for _, panel in { xp, challenges, unlock } do
		panel.Frame.Size = UDim2.fromOffset(phone and 300 or panelWidth, phone and 78 or 96)
	end
	bottomRow.Position = UDim2.new(0.5, 0, 1, phone and -76 or -90)
	bottomRow.Size = UDim2.new(1, -margin * 2, 0, phone and 78 or 96)
	-- Tarjetas: todas en escritorio y tableta; en el teléfono solo la del MVP
	cardsRow.Position = UDim2.new(0.5, 0, 1, phone and -76 or -198)
	cardsRow.Size = UDim2.new(1, -margin * 2, 0, 112)
	for _, card in cardsRow:GetChildren() do
		if card:IsA("GuiObject") and card.Name == "PlayerCard" then
			card.Visible = not phone
			card.Size = UDim2.fromOffset(width < 1150 and 150 or 176, 80)
		end
	end
	if phone then
		-- (el nivel a la izquierda de la tarjeta del MVP; desafíos y desbloqueo, solo en pantallas grandes)
		challenges.Frame.Visible = false
		unlock.Frame.Visible = false
	end
	scoreboard.Layout(phone)
end

local function clearCards()
	for _, child in cardsRow:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	mvpCard = nil
end

local function buildCards()
	clearCards()
	local lineup = view.Lineup
	for order, index in CARD_ORDER do
		local entry = lineup[index]
		if entry then
			if index == 1 then
				mvpCard = MVPCard.new(cardsRow, { Entry = entry, IsMVP = view.FeaturedIsMVP, Me = entry.Id == view.Me.Id, Order = order })
				mvpCard.Frame.Visible = false
			else
				local card = PlayerResultCard.new(cardsRow, { Rank = index, Entry = entry, Me = entry.Id == view.Me.Id, Order = order })
				card.Frame.Visible = false
			end
		end
	end
end

---------------------------------------------------------------------------
-- Secuencia
---------------------------------------------------------------------------

-- Recompensas, nivel, desafíos y desbloqueo (cuando ya ha llegado el resumen)
local function playSummary(token)
	if summaryShown or not summary then
		return
	end
	summaryShown = true
	rewards.Set(Data.Rewards(summary), summary)
	xp.Set(Data.LevelSteps(summary))
	challenges.Set(summary.Challenges)
	unlock.Set(summary.Unlocks)
	if phone then
		challenges.Frame.Visible = false
		unlock.Frame.Visible = false
	end
	if rewards.Frame.Visible then
		Transition.SlideIn(rewards.Frame, Vector2.new(60, 0), 0.3)
		rewards.Play(token)
	end
	task.delay(0.35, function()
		if not Anim.Alive(token) then
			return
		end
		if xp.Frame.Visible then
			Transition.Pop(xp.Frame, 0.9, 0.22)
			xp.Play(token)
		end
		task.wait(0.25)
		if not Anim.Alive(token) then
			return
		end
		if challenges.Frame.Visible then
			Transition.Pop(challenges.Frame, 0.9, 0.22)
			challenges.Play(token)
		end
		task.wait(0.3)
		if Anim.Alive(token) and unlock.Frame.Visible then
			unlock.Play(token)
		end
		-- Oferta pequeña (de vez en cuando, por lo que hiciste en la partida; se quita con ✕)
		task.wait(1)
		if Anim.Alive(token) and flow.State == "Results" then
			local data = ClientState.Data
			offer.Show(Data.PostMatchOffer(summary, MonetizationConfig.PostMatchOffer, Catalog.StoreItems({ "Skin" }), function(kind, id)
				return data ~= nil and Catalog.Owns(data, kind, id)
			end))
		end
	end)
end

local function at(token, time, fn)
	task.delay(time, function()
		if Anim.Alive(token) and flow.State == "Results" then
			fn()
		end
	end)
end

function Results.Open(result)
	local built = Data.Build(result)
	if not built then
		return false
	end
	view = built
	-- (el resumen llega justo después del resultado; uno guardado de hace rato es de otra partida)
	summary = (pendingSummary and os.clock() - pendingSummary.At < 6) and pendingSummary.Data or nil
	pendingSummary = nil
	flow.SetState("Results", { View = built })
	return true
end

function Results.Build(flowController, root)
	flow = flowController
	screen = C.new("Frame", { Name = "Results", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = root })
	-- Degradados arriba y abajo: el texto se lee sobre cualquier mapa sin tapar a los personajes
	for _, spec in { { 0, 0.32, 0 }, { 1, 0.42, 180 } } do
		C.new("Frame", { Name = "Shade", BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, spec[1]), Position = UDim2.fromScale(0, spec[1]), Size = UDim2.fromScale(1, spec[2]), Parent = screen }, {
			C.new("UIGradient", { Rotation = 90 + spec[3], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) }) }),
		})
	end
	header = ResultHeader.new(screen)
	score = ScoreDisplay.new(screen)
	rewards = RewardsPanel.new(screen)
	offer = OfferCard.new(screen, {
		OnView = function(current)
			-- (mirándola no se pasa sola a la siguiente partida)
			autoAdvance = false
			actions.SetCountdown(nil)
			local ok, Store = pcall(require, script.Parent.Store)
			if ok and Store.Preview and current then
				Store.Preview(current.Item, { Weapon = current.Weapon })
			end
		end,
	})
	cardsRow = C.new("Frame", { Name = "Cards", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1, -64, 0, 112), Parent = screen }, {
		C.new("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	bottomRow = C.new("Frame", { Name = "Bottom", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Parent = screen }, {
		C.new("UIListLayout", {
			Padding = UDim.new(0, 12),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	xp = XPProgress.new(bottomRow)
	xp.Frame.LayoutOrder = 1
	challenges = ChallengeProgress.new(bottomRow)
	challenges.Frame.LayoutOrder = 2
	unlock = UnlockCard.new(bottomRow)
	unlock.Frame.LayoutOrder = 3
	actions = ResultActions.new(screen, {
		OnScoreboard = function()
			scoreboard.Open()
		end,
		OnLobby = function()
			flow.ReturnToLobby()
		end,
		OnPlay = function()
			flow.Requeue()
		end,
		OnCancelAuto = function()
			autoAdvance = false
			actions.SetCountdown(nil)
		end,
	})
	-- El marcador completo va encima de todo lo demás
	scoreboard = ScoreboardPanel.new(screen)
	scoreboard.Frame.ZIndex = 50
	-- Esc / B: cierra el marcador
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or flow.State ~= "Results" then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			scoreboard.Close()
		elseif input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.ButtonY then
			scoreboard.Open()
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			flow.Requeue()
		end
	end)
	-- Datos del servidor: el resultado abre la pantalla; el resumen personal llega justo después
	ClientState.ResultsScreen = true
	Remotes.RoundEnd.OnClientEvent:Connect(function(info)
		if type(info) ~= "table" or type(info.Result) ~= "table" then
			return
		end
		-- (solo a quien estaba jugando: en el lobby o en plena presentación no se interrumpe)
		if flow.State == "Gameplay" or flow.State == "Deploy" then
			Results.Open(info.Result)
		end
	end)
	Remotes.MatchSummary.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		if flow.State == "Results" and not summaryShown then
			summary = data
			if Results.ReadyForSummary then
				playSummary(Anim.Token)
			end
		else
			pendingSummary = { Data = data, At = os.clock() }
		end
	end)
	Results.Screen = screen
end

function Results.Show(ctx)
	view = ctx.View or view
	if not view then
		flow.SetState("Gameplay")
		return
	end
	Anim.Token += 1
	local token = Anim.Token
	summaryShown = false
	Results.ReadyForSummary = false
	autoAdvance = true
	ClientState.ResultsActive = true
	-- Siguiente partida: la pantalla final dura EndScreenTime; luego el descanso con la votación
	local endedAt = flow.EndedAt or os.clock()
	local screenLeft = math.max(0, (GameConfig.EndScreenTime or 8) - (os.clock() - endedAt))
	nextAt = os.clock() + screenLeft
	-- 0,0: fundido corto (el HUD ya se ha ido al cambiar de estado)
	flow.SetBackdrop(0, 0.01)
	Transition.Blur(0, 0.15)
	local fade = Instance.new("Frame")
	fade.Name = "ResultsFade"
	fade.BackgroundColor3 = Colors.Bg
	fade.BackgroundTransparency = 1
	fade.BorderSizePixel = 0
	fade.Size = UDim2.fromScale(1, 1)
	fade.ZIndex = 60
	fade.Parent = flow.Guis.FX and flow.Guis.FX:FindFirstChild("Layer") or screen
	Transition.Tween(fade, 0.22, { BackgroundTransparency = 0 })
	-- Componentes con los datos (ocultos hasta su momento)
	screen.Visible = true
	header.Set(view)
	header.Frame.Visible = false
	score.Set(view)
	score.Frame.Visible = false
	rewards.Frame.Visible = false
	xp.Frame.Visible = false
	challenges.Frame.Visible = false
	unlock.Frame.Visible = false
	actions.Frame.Visible = false
	actions.SetCountdown(screenLeft + (GameConfig.IntermissionTime or 20))
	scoreboard.Set(view)
	scoreboard.Close()
	buildCards()
	applyLayout()
	-- 0,25: escena 3D montada a oscuras, cámara puesta, y se abre
	at(token, 0.25, function()
		hideWorldCharacters(true)
		stage = Stage.new()
		stage:SetMap(view.Map)
		stage:SetResult(view)
		stage:SetPlayers(view.Lineup)
		stage:SetMVP(view.Featured and view.Featured.Id)
		stage:SetScore(view.MyScore, view.EnemyScore)
		local ok, err = pcall(stage.Build, stage)
		if not ok then
			warn("[Results] escena: " .. tostring(err))
		end
		local targets = stage:CameraTargets()
		if targets then
			Camera.Start(targets, workspace.CurrentCamera)
			flow.SetCamera("Scripted", Camera.Step)
		end
		Transition.Tween(fade, 0.4, { BackgroundTransparency = 1 })
		task.delay(0.45, function()
			fade:Destroy()
		end)
	end)
	-- Respiración de los personajes, cuenta atrás y personajes del mundo ocultos (solo mientras se ve)
	if stepConnection then
		stepConnection:Disconnect()
	end
	local lastSweep = 0
	stepConnection = RunService.RenderStepped:Connect(function()
		if flow.State ~= "Results" then
			return
		end
		if stage then
			stage:Step(os.clock())
		end
		if os.clock() - lastSweep > 0.5 then
			lastSweep = os.clock()
			hideWorldCharacters(true)
			if autoAdvance and actions.Frame.Visible then
				local left = nextAt - os.clock()
				actions.SetCountdown(math.max(0, left) + (left > 0 and (GameConfig.IntermissionTime or 20) or 0))
			end
		end
	end)
	-- 0,8: VICTORIA / DERROTA
	at(token, 0.8, function()
		header.Play()
		if view.Outcome == "Victory" then
			UISound.Play("Victory")
			task.delay(0.08, function()
				UISound.Play("VictorySting")
			end)
			Transition.Flash(Color3.fromRGB(200, 225, 255), 0.25, 0.35)
		elseif view.Outcome == "Defeat" then
			UISound.Play("Defeat")
		else
			UISound.Play("Whoosh")
		end
	end)
	-- 1,3: marcador
	at(token, 1.3, function()
		score.Frame.Visible = true
		score.Play(token)
	end)
	-- 1,7: compañeros
	at(token, 1.7, function()
		local i = 0
		for _, card in cardsRow:GetChildren() do
			if card:IsA("GuiObject") and card.Name == "PlayerCard" and not phone then
				i += 1
				-- (están en una lista: entran con un salto, una tras otra)
				task.delay(i * 0.06, function()
					if Anim.Alive(token) then
						card.Visible = true
						Transition.Pop(card, 0.8, 0.22)
					end
				end)
			end
		end
	end)
	-- 2,2: MVP
	at(token, 2.2, function()
		if mvpCard then
			mvpCard.Frame.Visible = true
			mvpCard.Highlight(token)
		end
		if stage then
			stage:HighlightMVP()
		end
		Camera.SetPreset("MVP")
	end)
	-- 2,8: recompensas (si el resumen ya llegó; si no, en cuanto llegue)
	at(token, 2.8, function()
		Results.ReadyForSummary = true
		playSummary(token)
	end)
	-- 3,0: acciones
	at(token, 3.0, function()
		actions.Show()
	end)
	-- 6,0: la cámara pasa a una deriva lenta
	at(token, 6.0, function()
		Camera.SetPreset("Drift")
	end)
end

function Results.Hide()
	Anim.Token += 1
	ClientState.ResultsActive = false
	Results.ReadyForSummary = false
	if stepConnection then
		stepConnection:Disconnect()
		stepConnection = nil
	end
	Camera.Stop()
	if stage then
		stage:Destroy()
		stage = nil
	end
	hideWorldCharacters(false)
	clearCards()
	scoreboard.Close()
	offer.Show(nil)
	pcall(function()
		require(Flow.Store.Inspect).Close()
	end)
	screen.Visible = false
	view = nil
	summary = nil
end

-- (para las pruebas)
Results.Data = Data
function Results.AutoAdvance()
	return autoAdvance
end

local _ = player
return Results
