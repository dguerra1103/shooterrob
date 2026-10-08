-- Granada en el cliente: tecla G (L1 en mando, botón en móvil), indicador de recarga y explosiones.
-- Como en los shooters realistas, se puede "cocinar": un toque la lanza enseguida; manteniendo la
-- tecla se le quita la anilla y la mecha corre (pitidos cada vez más rápidos y cuenta atrás) y al
-- soltar sale con menos tiempo para que el enemigo no pueda escapar. Si se acaba, sale sola.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared.Weapons)
local Sounds = require(Shared.Sounds)
local Remotes = require(Shared.Remotes)

local TouchLayout = require(script.Parent.TouchLayout)
local ClientState = require(script.Parent.ClientState)
local Effects = require(script.Parent.Effects)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local GrenadeController = {}

local DEF = Weapons.Grenade

local widget, label, fill
local touchOnly = false
local cookStart = nil -- os.clock() al quitar la anilla (cocinando)
local nextBeep = 0
local AUTO_THROW = 0.25 -- (si queda tan poca mecha, sale sola)

local function readyAt()
	return player:GetAttribute("GrenadeReadyAt") or 0
end

local function canThrow()
	if ClientState.IsBlocked() or ClientState.Frozen() or ReplicatedStorage:GetAttribute("Mode") == "GUN" then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and workspace:GetServerTimeNow() >= readyAt()
end

local function throw(cook)
	if not canThrow() then
		return
	end
	-- Un poco hacia arriba para que la parábola llegue más lejos
	local direction = (camera.CFrame.LookVector + Vector3.new(0, 0.12, 0)).Unit
	Remotes.ThrowGrenade:FireServer(direction, cook or 0)
	Sounds.Play("Swing", nil, 0.8, 1)
end

-- Quitar la anilla (empieza a cocinarse)
local function startCook()
	if cookStart or not canThrow() then
		return
	end
	cookStart = os.clock()
	nextBeep = cookStart + 0.5
	Remotes.GrenadePin:FireServer()
	Sounds.Play("Click", nil, 1.7, 0.7)
end

-- Soltar: sale con el tiempo que lleva cocinándose
local function release()
	if not cookStart then
		return
	end
	local cook = math.clamp(os.clock() - cookStart, 0, DEF.Fuse - AUTO_THROW)
	cookStart = nil
	throw(cook)
end

-- Segundos de mecha que le quedan a la granada que se está cocinando (nil si no hay)
function GrenadeController.CookLeft()
	return cookStart and math.max(0, DEF.Fuse - (os.clock() - cookStart)) or nil
end

local lastKey
local function updateWidget()
	local gunGame = ReplicatedStorage:GetAttribute("Mode") == "GUN"
	local active = not ClientState.InMainMenu and not gunGame
	-- (con pantalla táctil el cartel no sale: está el botón 💣, que tampoco sale en la Escalada)
	widget.Visible = active and not touchOnly
	local touchButton = TouchLayout.GetButton("Grenade")
	if touchButton then
		touchButton.Visible = active and not ClientState.IsBlocked()
	end
	if not active then
		cookStart = nil
		return
	end
	-- Cocinando: pitidos cada vez más rápidos y, si se acaba la mecha, sale sola
	if cookStart then
		if not canThrow() then
			cookStart = nil -- (muerto, bloqueado...)
		else
			local fuseLeft = DEF.Fuse - (os.clock() - cookStart)
			if fuseLeft <= AUTO_THROW then
				release()
			else
				if os.clock() >= nextBeep then
					Sounds.Play("Click", nil, 2.2, 0.5)
					nextBeep = os.clock() + math.clamp(fuseLeft * 0.25, 0.12, 0.5)
				end
				local key = -1000 - math.floor(fuseLeft * 10)
				if key ~= lastKey then
					lastKey = key
					label.Text = string.format("💣 %.1f", fuseLeft)
					label.TextColor3 = Color3.fromRGB(255, 220, 120)
					fill.Size = UDim2.fromScale(fuseLeft / DEF.Fuse, 1)
					fill.BackgroundColor3 = Color3.fromRGB(230, 40, 30)
					if touchOnly then
						pcall(function()
							TouchLayout.SetBadge("Grenade", string.format("%.1f", fuseLeft))
						end)
					end
				end
				return
			end
		end
	end
	local left = readyAt() - workspace:GetServerTimeNow()
	-- (solo se escribe cuando cambia el segundo o la barra en pasos de 1/40)
	local key = left <= 0 and -1 or math.ceil(left) * 100 + math.floor((1 - left / DEF.Cooldown) * 40)
	if key == lastKey then
		return
	end
	lastKey = key
	-- (en pantallas táctiles, en el propio botón: velo que baja con los segundos que faltan)
	if touchOnly then
		pcall(function()
			TouchLayout.SetBadge("Grenade", nil)
			TouchLayout.SetCooldown("Grenade", left > 0 and left / DEF.Cooldown or 0, tostring(math.ceil(math.max(left, 0))))
		end)
	end
	if left <= 0 then
		label.Text = "💣 G"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(255, 90, 40)
	else
		label.Text = "💣 " .. math.ceil(left)
		label.TextColor3 = Color3.fromRGB(190, 190, 200)
		fill.Size = UDim2.fromScale(1 - left / DEF.Cooldown, 1)
		fill.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	end
end

function GrenadeController.Init()
	local gui = UI.new("ScreenGui", {
		Name = "Grenade",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- (con pantalla táctil no se ve: quedaba encima de los botones; ahí está el botón 💣)
	touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	widget = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -150),
		Size = UDim2.fromOffset(84, 34),
		Visible = not touchOnly,
		BackgroundColor3 = Color3.fromRGB(20, 22, 34),
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, { UI.corner(10), UI.stroke(Color3.fromRGB(255, 120, 60), 2, 0.3) })
	fill = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.55,
		Parent = widget,
	}, { UI.corner(10) })
	label = UI.label({ Size = UDim2.fromScale(1, 1), Text = "💣 G", TextSize = 20, ZIndex = 2, Parent = widget })

	TouchLayout.BindAction("Grenade", function(_, state)
		if state == Enum.UserInputState.Begin then
			startCook()
		elseif state == Enum.UserInputState.End then
			release()
		elseif state == Enum.UserInputState.Cancel then
			-- (otra cosa se quedó la tecla, p. ej. se abrió un menú: no se lanza, se vuelve a poner la anilla)
			cookStart = nil
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.G, Enum.KeyCode.ButtonL1)
	TouchLayout.Set("Grenade", UDim2.new(1, -200, 1, -270))

	Remotes.ExplosionFX.OnClientEvent:Connect(function(position, radius)
		if typeof(position) == "Vector3" then
			-- Sonido en el punto de la explosión (se oye más fuerte cuanto más cerca). Antes del efecto: si
			-- te aturde, el estampido se oye entero y luego todo se apaga
			local spot = Instance.new("Attachment")
			spot.WorldPosition = position
			spot.Parent = workspace.Terrain
			local bang = Sounds.Play("ShotHeavy", spot, 0.45, 1.6)
			if bang then
				bang.SoundGroup = nil
			end
			Debris:AddItem(spot, 5)
			Effects.Explosion(position, type(radius) == "number" and radius or 14)
		end
	end)

	RunService.Heartbeat:Connect(updateWidget)
end

return GrenadeController
