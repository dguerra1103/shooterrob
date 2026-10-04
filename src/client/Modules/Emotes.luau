-- Emotes (tecla N): menú con los bailes y gestos que trae Roblox (script Animate). Mientras dura el
-- emote la cámara pasa a tercera persona para verte; vuelve a primera persona al moverte o al acabar.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local ClientState = require(script.Parent.ClientState)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Emotes = {}

local EMOTES = {
	{ Id = "wave", Name = "Saludar", Icon = "👋" },
	{ Id = "dance", Name = "Baile 1", Icon = "🕺" },
	{ Id = "dance2", Name = "Baile 2", Icon = "💃" },
	{ Id = "dance3", Name = "Baile 3", Icon = "🎶" },
	{ Id = "cheer", Name = "Celebrar", Icon = "🙌" },
	{ Id = "laugh", Name = "Reír", Icon = "😂" },
	{ Id = "point", Name = "Señalar", Icon = "👉" },
}
local EMOTE_TIME = 4

local gui, wheel
local emoteUntil = 0
local zoom = { 0.5, 400 }

local function setThirdPerson(on)
	if on then
		-- Solo se guarda el zoom de primera persona (no el de un emote anterior)
		if not ClientState.Emoting then
			zoom = { player.CameraMinZoomDistance, player.CameraMaxZoomDistance }
		end
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 9
		player.CameraMaxZoomDistance = 12
	else
		player.CameraMinZoomDistance = zoom[1]
		player.CameraMaxZoomDistance = zoom[2]
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local function stopEmote()
	if not ClientState.Emoting then
		return
	end
	ClientState.Emoting = false
	emoteUntil = 0
	if not ClientState.Dead then
		setThirdPerson(false)
	end
end

local function play(id)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animate = character and character:FindFirstChild("Animate")
	local playEmote = animate and animate:FindFirstChild("PlayEmote")
	if not humanoid or humanoid.Health <= 0 or not playEmote or not playEmote:IsA("BindableFunction") then
		return
	end
	local ok, played = pcall(function()
		return playEmote:Invoke(id)
	end)
	-- PlayEmote devuelve true solo si de verdad empieza (nil si estás saltando, sentado, etc.)
	if ok and played == true then
		setThirdPerson(true)
		ClientState.Emoting = true
		emoteUntil = os.clock() + EMOTE_TIME
	end
end

local function setWheel(open)
	wheel.Visible = open
	ClientState.EmoteMenuOpen = open
	ClientState.UpdateMouse()
end

-- Otros motivos para cerrar el menú (no cuenta el propio menú de emotes)
local function otherBlock()
	return ClientState.MenuOpen or ClientState.VoteOpen or ClientState.InMainMenu or ClientState.Dead
end

local function build()
	gui = UI.new("ScreenGui", {
		Name = "Emotes",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Parent = player:WaitForChild("PlayerGui"),
	})
	wheel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 360),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	-- Libera el ratón mientras el menú está abierto
	UI.new("TextButton", { Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Parent = wheel })
	UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(120, 40),
		Text = "EMOTES",
		TextSize = 24,
		Parent = wheel,
	})
	for i, emote in EMOTES do
		local angle = (i - 1) / #EMOTES * math.pi * 2 - math.pi / 2
		local button = UI.button({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(angle) * 130, 0.5, math.sin(angle) * 130),
			Size = UDim2.fromOffset(92, 92),
			Text = "",
			BackgroundColor3 = Color3.fromRGB(40, 44, 70),
			BackgroundTransparency = 0.15,
			Parent = wheel,
		}, { UI.stroke(Color3.new(1, 1, 1), 3, 0), UI.corner(46) })
		UI.label({ Size = UDim2.new(1, 0, 0.7, 0), Text = emote.Icon, TextSize = 40, Parent = button })
		UI.label({ Position = UDim2.fromScale(0, 0.62), Size = UDim2.new(1, 0, 0.3, 0), Text = emote.Name, TextSize = 15, Parent = button })
		button.Activated:Connect(function()
			Sounds.Play("Click")
			setWheel(false)
			play(emote.Id)
		end)
	end
end

function Emotes.Init()
	build()
	ContextActionService:BindAction("Emotes", function(_, state)
		if state == Enum.UserInputState.Begin then
			if wheel.Visible then
				setWheel(false)
			elseif not ClientState.IsBlocked() then
				setWheel(true)
			end
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.N)
	-- Botón táctil en móvil
	ContextActionService:SetTitle("Emotes", "😀")
	ContextActionService:SetPosition("Emotes", UDim2.new(1, -120, 1, -320))
	RunService.Heartbeat:Connect(function()
		if wheel.Visible and otherBlock() then
			setWheel(false)
		end
		if not ClientState.Emoting then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		-- Se acaba al pasar el tiempo, al moverse, al morir o al disparar
		local moved = humanoid and humanoid.MoveDirection.Magnitude > 0.1
		if os.clock() > emoteUntil or moved or not humanoid or humanoid.Health <= 0 or ClientState.Aiming then
			stopEmote()
		end
	end)
	ClientState.ShotFired.Event:Connect(stopEmote)
	player.CharacterAdded:Connect(stopEmote)
end

return Emotes
