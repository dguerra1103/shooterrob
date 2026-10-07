-- Arranca el cliente entero (Main.client) en el simulador: ningún sistema debe fallar al iniciar
local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = task
local game, req = mock.buildGame(process.args[1])
local RS = game.ReplicatedStorage
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local teamA, teamB = mock.new("Team"), mock.new("Team")
teamA.Name, teamA.TeamColor = "Rojo", roblox.BrickColor.new("Really red")
teamB.Name, teamB.TeamColor = "Azul", roblox.BrickColor.new("Really blue")
teamA.Parent, teamB.Parent = Teams, Teams
local PlayerData = req(game.ServerScriptService.Server.Modules.PlayerData)
PlayerData.Init()
local me = mock.new("Player")
me.Name, me.DisplayName, me.UserId, me.Team = "Yo", "Yo", 1, teamA
me.Parent = Players
table.insert(mock.players, me)
Players.PlayerAdded:Fire(me)
PlayerData.WaitFor(me, 3)
local pg = mock.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = me
Players.LocalPlayer = me
game.Workspace.CurrentCamera.ViewportSize = roblox.Vector2.new(1280, 720)
RS:SetAttribute("TeamA", "Rojo"); RS:SetAttribute("TeamB", "Azul"); RS:SetAttribute("TeamMode", true)
RS:SetAttribute("State", "Intermission"); RS:SetAttribute("Mode", "TDM"); RS:SetAttribute("ModeName", "Duelo por equipos")
RS:SetAttribute("EventName", "Halloween"); game.ReplicatedStorage:SetAttribute("EventId", "Halloween2026"); RS:SetAttribute("EventGoal", 100)
local warnings = {}
mock.onWarn = function(...)
	table.insert(warnings, table.concat({ ... }, " "))
end
local ok, err = pcall(req, game.StarterPlayer.Client.Main)
print("Main.client:", ok, err)
local Sounds = req(RS.Shared.Sounds)
local played = {}
local origPlay = Sounds.Play
Sounds.Play = function(name, parent, ...)
	local sound = origPlay(name, parent, ...)
	table.insert(played, { Name = name, Parent = parent, Sound = sound, Time = os.clock() })
	return sound
end
local function count(name) local n = 0 for _, p in played do if p.Name == name then n += 1 end end return n end
local function clear() table.clear(played) end
task.wait(3)
-- Datos del servidor
local view
for _, sent in mock.sent do
	if sent.Remote == "DataUpdate" then view = sent.Args[1] end
end
local Remotes = req(RS.Shared.Remotes)
if view then
	Remotes.DataUpdate.OnClientEvent:Fire(view)
end
task.wait(2)
-- Entra en partida: personaje, estado Playing e Infección
local char = mock.new("Model"); char.Name = "Yo"
local hum = mock.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100; hum.Parent = char
for _, n in { "HumanoidRootPart", "Head", "RightHand", "UpperTorso" } do
	local part = mock.new("Part"); part.Name = n; part.Position = roblox.Vector3.new(0, 3, 0); part.Parent = char
end
char.Parent = game.Workspace
me.Character = char
me.CharacterAdded:Fire(char)
local ClientState = req(game.StarterPlayer.Client.Modules.ClientState)
ClientState.InMainMenu = false
RS:SetAttribute("State", "Playing")
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local cam = game.Workspace.CurrentCamera
cam.CFrame = roblox.CFrame.new(0, 5, 0)

local Weapons = req(RS.Shared.Weapons)
local render = mock.renderSteps.WeaponViewmodel
local function frames(n) for _ = 1, n do render(1 / 60) end end
local function rel(vm, name)
	local handle = vm.PrimaryPart
	for _, part in vm:GetChildren() do
		if part.Name == name or (name == "LeftGlove" and part.Name == "Glove" and part:GetAttribute("Side") == "Left")
			or (name == "RightGlove" and part.Name == "Glove" and part:GetAttribute("Side") == "Right") then
			return handle.CFrame:ToObjectSpace(part.CFrame).Position, part
		end
	end
	return nil
end
local names = {}
for name, d in Weapons.List do if d.Type == "Gun" then table.insert(names, name) end end
table.sort(names)
local current
local fails = 0
local function equip(name)
	if current then current.Parent = nil; pcall(function() char.ChildRemoved:Fire(current) end) end
	local tool = mock.new("Tool"); tool.Name = name
	local d = Weapons.Get(name)
	tool:SetAttribute("Weapon", name); tool:SetAttribute("Slot", 1); tool:SetAttribute("Ammo", d.MagSize); tool:SetAttribute("Reserve", 90)
	tool.Parent = char
	pcall(function() char.ChildAdded:Fire(tool) end)
	current = tool
	return tool, d
end
local function unblock()
	for _, key in { "MenuOpen", "VoteOpen", "InMainMenu", "Dead", "EmoteMenuOpen", "TutorialOpen", "WheelOpen", "NewsOpen" } do
		ClientState[key] = false
	end
end
for _, name in names do
	unblock()
	local tool, d = equip(name)
	task.wait(0.45)
	frames(5)
	local vm = cam:FindFirstChild("Viewmodel")
	local counts = {}
	for _, part in vm:GetChildren() do
		local n = part.Name
		local g = part:GetAttribute("Side") and ("Arm" .. part:GetAttribute("Side")) or (n:sub(1,3) == "Mag" and n ~= "MagTube" and "Mag") or (n:sub(1,4) == "Drum" and "Mag") or (n:sub(1,7) == "AmmoBox" and "Mag") or (n:sub(1,5) == "Slide" and "Slide") or (n:sub(1,4) == "Pump" and n:sub(1,7) ~= "Pumpkin" and "Pump") or ((n:sub(1,10) == "BoltHandle" or n:sub(1,8) == "BoltKnob") and "Bolt")
		if g then counts[g] = (counts[g] or 0) + 1 end
	end
	local line = {}
	for k, v in counts do table.insert(line, k .. "=" .. v) end
	table.sort(line)
	-- Disparo: corredera / bomba / cerrojo
	local slide0 = rel(vm, "Slide")
	local pump0 = rel(vm, "Pump")
	local bolt0 = rel(vm, "BoltHandle")
	local glove0 = rel(vm, "LeftGlove")
	local rglove0 = rel(vm, "RightGlove")
	mock.actions.Fire("Fire", roblox.Enum.UserInputState.Begin, {})
	mock.actions.Fire("Fire", roblox.Enum.UserInputState.End, {})
	local maxSlide, maxPump, maxBolt, maxPumpHand, maxRHand = 0, 0, 0, 0, 0
	local t0 = os.clock()
	while os.clock() - t0 < 0.75 do
		render(1 / 60)
		if slide0 then maxSlide = math.max(maxSlide, (rel(vm, "Slide") - slide0).Magnitude) end
		if pump0 then maxPump = math.max(maxPump, (rel(vm, "Pump") - pump0).Magnitude); maxPumpHand = math.max(maxPumpHand, (rel(vm, "LeftGlove") - glove0).Magnitude) end
		if bolt0 then maxBolt = math.max(maxBolt, (rel(vm, "BoltHandle") - bolt0).Magnitude); maxRHand = math.max(maxRHand, (rel(vm, "RightGlove") - rglove0).Magnitude) end
		task.wait(1 / 60)
	end
	frames(3)
	if ClientState.Reloading then
		-- (armas de un tiro: recargan solas tras disparar) se espera a que acabe
		local t1 = os.clock()
		while os.clock() - t1 < d.ReloadTime + 0.1 do render(1 / 60); task.wait(1 / 30) end
		tool:SetAttribute("Ammo", d.MagSize); tool.AttributeChanged:Fire("Ammo")
		tool:SetAttribute("Reloading", false); tool.AttributeChanged:Fire("Reloading")
		task.wait(0.1); frames(3)
	end
	local function back(pos0, n) return not pos0 or (rel(vm, n) - pos0).Magnitude < 0.01 end
	if not (back(glove0, "LeftGlove") and back(rglove0, "RightGlove")) then print("  guantes:", rel(vm, "LeftGlove") - glove0, rel(vm, "RightGlove") - rglove0, ClientState.Reloading) end
	local settled = back(slide0, "Slide") and back(pump0, "Pump") and back(bolt0, "BoltHandle") and back(glove0, "LeftGlove") and back(rglove0, "RightGlove")
	-- Recarga en vacío
	tool:SetAttribute("Ammo", 0); tool.AttributeChanged:Fire("Ammo")
	task.wait(0.1)
	unblock()
	local mag0 = rel(vm, "Mag") or rel(vm, "Drum") or rel(vm, "AmmoBox")
	local magName = rel(vm, "Mag") and "Mag" or (rel(vm, "Drum") and "Drum") or (rel(vm, "AmmoBox") and "AmmoBox")
	mock.actions.Reload("Reload", roblox.Enum.UserInputState.Begin, {})
	render(1 / 60)
	print("  recargando:", ClientState.Reloading, ClientState.Ammo, tool:GetAttribute("Reserve"), ClientState.Aiming, ClientState.IsBlocked())
	local magDrop, handMove, pumpRack = 0, 0, 0
	local hidden = false
	t0 = os.clock()
	while os.clock() - t0 < d.ReloadTime * 0.97 do
		render(1 / 60)
		if mag0 then
			local pos, part = rel(vm, magName)
			magDrop = math.max(magDrop, mag0.Y - pos.Y)
			if tonumber(part.LocalTransparencyModifier) and part.LocalTransparencyModifier > 0.9 then hidden = true end
		end
		if glove0 then handMove = math.max(handMove, (rel(vm, "LeftGlove") - glove0).Magnitude) end
		if pump0 then pumpRack = math.max(pumpRack, (rel(vm, "Pump") - pump0).Magnitude) end
		task.wait(1 / 60)
	end
	tool:SetAttribute("Ammo", d.MagSize); tool.AttributeChanged:Fire("Ammo")
	tool:SetAttribute("Reloading", false); tool.AttributeChanged:Fire("Reloading")
	task.wait(0.6)
	frames(5)
	local magBack = not mag0 or (rel(vm, magName) - mag0).Magnitude < 0.01
	local _, magPart = rel(vm, magName or "x")
	local visible = not magPart or not tonumber(magPart.LocalTransparencyModifier) or magPart.LocalTransparencyModifier == 0
	local handBack = not glove0 or (rel(vm, "LeftGlove") - glove0).Magnitude < 0.01
	print(string.format("%-16s %-40s corredera %.2f bomba %.2f/%.2f cerrojo %.2f/%.2f | recarga: cargador baja %.2f oculto %s, mano %.2f, bombeo %.2f | vuelve %s %s %s %s",
		name, table.concat(line, " "), maxSlide, maxPump, maxPumpHand, maxBolt, maxRHand, magDrop, tostring(hidden), handMove, pumpRack,
		tostring(settled), tostring(magBack), tostring(visible), tostring(handBack)))
	if not (settled and magBack and visible and handBack) then fails += 1; print("FALLO: " .. name .. " no vuelve a su sitio") end
	if counts.Slide and maxSlide < 0.1 then fails += 1; print("FALLO: corredera quieta " .. name) end
	if counts.Pump and d.FireRate <= 1.6 and maxPump < 0.2 then fails += 1; print("FALLO: bomba quieta " .. name) end
	if counts.Bolt and d.FireRate <= 1.6 and maxBolt < 0.2 then fails += 1; print("FALLO: cerrojo quieto " .. name) end
	if mag0 and (magDrop < 0.5 or not hidden) then fails += 1; print("FALLO: cargador no sale " .. name) end
	if glove0 and handMove < 0.3 then fails += 1; print("FALLO: mano quieta en la recarga " .. name) end
end
-- Pared delante: el arma se recoge
equip("ARX27")
task.wait(0.5)
frames(10)
local vm = cam:FindFirstChild("Viewmodel")
local free = cam.CFrame:ToObjectSpace(vm.PrimaryPart.CFrame)
local wall = mock.new("Part"); wall.Size = roblox.Vector3.new(20, 20, 1); wall.CFrame = roblox.CFrame.new(0, 5, -1.6); wall.CanCollide = true; wall.Parent = game.Workspace
mock.raycastImpl = function(origin, direction)
	if direction.Z < 0 and origin.Z > -1.6 and origin.Z + direction.Z < -1.6 then
		local t = (origin.Z + 1.6) / -direction.Z
		return { Instance = wall, Position = origin + direction * t, Normal = roblox.Vector3.new(0, 0, 1), Distance = (direction * t).Magnitude, Material = roblox.Enum.Material.Plastic }
	end
	return nil
end
for _ = 1, 40 do render(1 / 60) end
mock.raycastImpl = nil
local near = cam.CFrame:ToObjectSpace(vm.PrimaryPart.CFrame)
print(string.format("pared: z %.2f -> %.2f", free.Position.Z, near.Position.Z))
if near.Position.Z < free.Position.Z + 0.3 then fails += 1; print("FALLO: el arma no se recoge contra la pared") end
wall.Parent = nil
-- Cuerpo a cuerpo alterno: dos golpes van a lados opuestos
local knifeTool = mock.new("Tool"); knifeTool.Name = "Knife"; knifeTool:SetAttribute("Weapon", "Knife"); knifeTool:SetAttribute("Slot", 3); knifeTool.Parent = char
current.Parent = nil; pcall(function() char.ChildRemoved:Fire(current) end)
pcall(function() char.ChildAdded:Fire(knifeTool) end)
task.wait(0.5)
frames(10)
vm = cam:FindFirstChild("Viewmodel")
unblock()
local function swingX()
	mock.actions.Fire("Fire", roblox.Enum.UserInputState.Begin, {})
	mock.actions.Fire("Fire", roblox.Enum.UserInputState.End, {})
	local x = 0
	local t0 = os.clock()
	while os.clock() - t0 < 0.12 do render(1 / 60); task.wait(1 / 60) end
	x = cam.CFrame:ToObjectSpace(vm.PrimaryPart.CFrame).Position.X
	task.wait(0.8); frames(5)
	return x
end
local rest = cam.CFrame:ToObjectSpace(vm.PrimaryPart.CFrame).Position.X
local a, b = swingX(), swingX()
print(string.format("cuchillo: reposo %.2f, golpe 1 %.2f, golpe 2 %.2f", rest, a, b))
if not ((a - rest) * (b - rest) < 0) then fails += 1; print("FALLO: los golpes no alternan de lado") end
print(fails == 0 and "ANIMACIONES OK" or ("FALLOS: " .. fails))
process.exit(fails == 0 and 0 or 1)
