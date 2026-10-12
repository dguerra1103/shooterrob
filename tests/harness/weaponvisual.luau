-- Fase 9 (ARX-27 gold standard): lógica de la presentación de las armas sin mirar nada en pantalla.
-- Familias completas, marcas de la recarga (y que siguen en los tiempos de siempre), prioridad de
-- acciones, cinemática inversa de los brazos, piezas móviles, ribetes de las skins, modelo externo con
-- su respaldo, huecos de audio, presupuestos por calidad y que el ARX-27 NO cambia de equilibrio.
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local V = roblox.Vector3.new
local Shared = game.ReplicatedStorage.Shared
local WeaponVisual = req(Shared.WeaponVisual)
local WeaponFeel = req(Shared.WeaponFeel)
local Weapons = req(Shared.Weapons)
local WeaponModels = req(Shared.WeaponModels)
local Sounds = req(Shared.Sounds)
local Skins = req(Shared.Skins)

-- 1) Familias: todas las secciones, con valores razonables
local SECTIONS = { "Idle", "Sprint", "Equip", "Unequip", "Inspect", "Reload", "Jump", "Charm", "Melee" }
local families = {}
for family in WeaponFeel.Profiles do
	table.insert(families, family)
end
table.sort(families)
for _, family in families do
	check(WeaponVisual.Families[family] ~= nil, "familia " .. family .. " en WeaponVisual")
end
-- Un arma de cada familia (y todas las armas de fuego) resuelven su presentación completa
local gunCount, problems = 0, {}
for name, def in Weapons.List do
	local visual = WeaponVisual.Get(name, def)
	gunCount += 1
	for _, section in SECTIONS do
		if type(visual[section]) ~= "table" then
			table.insert(problems, name .. "." .. section)
		end
	end
	local inspect = visual.Inspect
	local keys = inspect.Keys
	if inspect.Duration < 1.5 or inspect.Duration > 3.2 then
		table.insert(problems, name .. ": inspección de " .. inspect.Duration .. " s")
	end
	if keys[1][1] ~= 0 or keys[#keys][1] ~= 1 or keys[1][2].Magnitude > 0 or keys[#keys][3].Magnitude > 0 then
		table.insert(problems, name .. ": la inspección no empieza y acaba en la pose de siempre")
	end
	for i = 2, #keys do
		if keys[i][1] <= keys[i - 1][1] then
			table.insert(problems, name .. ": claves de inspección desordenadas")
		end
	end
	if visual.Unequip.Time > 0.2 then
		table.insert(problems, name .. ": guardar el arma tarda demasiado (" .. visual.Unequip.Time .. ")")
	end
end
check(#problems == 0, "las " .. gunCount .. " armas tienen su presentación completa (" .. table.concat(problems, ", ") .. ")")
local arx = WeaponVisual.Get("ARX27", Weapons.Get("ARX27"))
check(arx.Family == "Rifle" and WeaponVisual.ReferenceWeapon == "ARX27", "ARX-27: familia Rifle y arma de referencia")
-- Cada familia se nota distinta (no son copias del fusil)
local lmg = WeaponVisual.Get("TitanLMG", Weapons.Get("TitanLMG"))
local pistol = WeaponVisual.Get("Viper", Weapons.Get("Viper"))
local smg = WeaponVisual.Get("Specter9", Weapons.Get("Specter9"))
check(lmg.Sprint.Angles ~= arx.Sprint.Angles and pistol.Sprint.Angles ~= arx.Sprint.Angles, "sprint propio de ametralladora y pistola")
check(pistol.Unequip.Time < arx.Unequip.Time and smg.Unequip.Time < arx.Unequip.Time and lmg.Unequip.Time > arx.Unequip.Time,
	"guardar: pistola y subfusil más rápido que el fusil; ametralladora más lento")
check(lmg.Jump.Kick > arx.Jump.Kick, "la ametralladora pesa más al saltar")

-- 2) Marcas de la recarga
local function names(list)
	local out = {}
	for _, marker in list do
		table.insert(out, marker.Name)
	end
	return table.concat(out, ",")
end
local function sorted(list)
	for i = 2, #list do
		if list[i].At < list[i - 1].At then
			return false
		end
	end
	for _, marker in list do
		if marker.At <= 0 or marker.At >= 1 then
			return false
		end
	end
	return true
end
local tactical = WeaponVisual.ReloadMarkers(arx, false)
local empty = WeaponVisual.ReloadMarkers(arx, true)
local shells = WeaponVisual.ReloadMarkers(WeaponVisual.Get("HavocPump", Weapons.Get("HavocPump")), true, true)
check(names(tactical) == "MagOut,MagIn,Ready" and sorted(tactical), "recarga táctica: MagOut → MagIn → Ready (" .. names(tactical) .. ")")
check(names(empty) == "MagOut,MagIn,Bolt,Ready" and sorted(empty), "recarga vacía: MagOut → MagIn → Bolt → Ready (" .. names(empty) .. ")")
check(names(shells) == "ShellIn,ShellIn,ShellIn,ShellIn,Bolt,Ready" and sorted(shells), "escopeta: cartucho a cartucho y bombeo")
-- (los sonidos siguen en los mismos instantes que antes de la Fase 9)
check(empty[1].At == 0.12 and empty[2].At == 0.55 and empty[3].At == 0.85, "las marcas del fusil son las de siempre (0,12 / 0,55 / 0,85)")

-- 3) Prioridad de acciones
check(WeaponVisual.ResolveAction({}) == "Idle", "sin nada: reposo")
check(WeaponVisual.ResolveAction({ Sprint = true, Inspect = true }) == "Inspect", "inspección por encima del sprint")
check(WeaponVisual.ResolveAction({ Reload = true, Inspect = true, Sprint = true }) == "Reload", "recarga por encima de inspección y sprint")
check(WeaponVisual.ResolveAction({ Melee = true, Reload = true }) == "Melee", "cuchillo por encima de todo")
check(WeaponVisual.ResolveAction({ IdleVariant = true, Sprint = true }) == "Sprint", "el gesto de reposo nunca pisa al sprint")

-- 4) Cinemática inversa de los brazos
local seed = 7
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end
local ikOk, ikBad = 0, {}
for _ = 1, 200 do
	local shoulder = V(rnd() * 2 - 1, rnd() * 2 - 1, rnd() * 2 - 1)
	local upper, lower = 0.8 + rnd(), 0.8 + rnd()
	local dir = V(rnd() - 0.5, rnd() - 0.5, rnd() - 0.5).Unit
	local minD, maxD = math.abs(upper - lower), upper + lower -- (solo distancias alcanzables)
	local hand = shoulder + dir * (minD + (maxD - minD) * (0.05 + rnd() * 0.9))
	local pole = V(1, -1.4, 0)
	local elbow, reached = WeaponVisual.SolveArm(shoulder, hand, upper, lower, pole)
	local e1, e2 = (elbow - shoulder).Magnitude, (hand - elbow).Magnitude
	if reached and math.abs(e1 - upper) < 1e-3 and math.abs(e2 - lower) < 1e-3 then
		ikOk += 1
	else
		table.insert(ikBad, string.format("%.3f/%.3f %.3f/%.3f %s", e1, upper, e2, lower, tostring(reached)))
	end
end
check(ikOk == 200, "IK: el brazo y el antebrazo miden lo que deben y la mano llega (" .. table.concat(ikBad, " | ") .. ")")
local elbow = WeaponVisual.SolveArm(V(0, 0, 0), V(0, 0, -2), 1.1, 1.1, V(1, -1, 0))
check(elbow.X > 0 and elbow.Y < 0, "IK: el codo se dobla hacia el polo (abajo y fuera)")
local far, reached = WeaponVisual.SolveArm(V(0, 0, 0), V(0, 0, -5), 1, 1, V(0, -1, 0))
check(not reached and math.abs((far - V(0, 0, -1)).Magnitude) < 0.01, "IK: si no llega, el codo queda en la recta (el antebrazo se estira)")
local same = WeaponVisual.SolveArm(V(1, 1, 1), V(1, 1, 1), 1, 1, V(0, -1, 0))
check(same.X == same.X and same.Y == same.Y and same.Z == same.Z, "IK: mano en el hombro sin NaN")

-- 5) Piezas móviles
check(WeaponVisual.PieceGroup("Mag") == "Mag" and WeaponVisual.PieceGroup("MagLowerEdge") == "Mag" and WeaponVisual.PieceGroup("MagBase") == "Mag", "cargador por nombre")
check(WeaponVisual.PieceGroup("ChargingHandle") == "Charge", "palanca de carga del fusil")
check(WeaponVisual.PieceGroup("MagTube") == nil and WeaponVisual.PieceGroup("BoltRelease") == nil and WeaponVisual.PieceGroup("Pumpkin") == nil, "lo que se llama parecido pero no se mueve")
check(WeaponVisual.PieceGroup("Cualquiera", "Mag") == "Mag" and WeaponVisual.PieceGroup("Cualquiera", "Inventada") == nil, "modelos nuevos: atributo Piece")

-- 6) El ARX-27 de verdad: cargador separado, palanca de carga, puntos y ribetes de skin
local model = WeaponModels.Build("ARX27", "Default")
local counts, trims = {}, {}
for _, part in model:GetChildren() do
	if part:IsA("BasePart") then
		local group = WeaponVisual.PieceGroup(part.Name, part:GetAttribute("Piece"))
		if group then
			counts[group] = (counts[group] or 0) + 1
		end
		if part:GetAttribute("Role") == "Trim" then
			table.insert(trims, part)
		end
	end
end
check((counts.Mag or 0) >= 4, "ARX-27: cargador separado (" .. tostring(counts.Mag) .. " piezas)")
check((counts.Charge or 0) == 1, "ARX-27: palanca de carga (se anima en la recarga vacía)")
check(counts.Bolt == nil and counts.Slide == nil, "ARX-27: sin cerrojo ni corredera (no se inventan)")
local handle = model.PrimaryPart
check(handle:FindFirstChild("Muzzle") and handle:FindFirstChild("AimPoint") and handle:FindFirstChild("Eject"), "ARX-27: boca, mira y expulsión")
check(#trims >= 4, "ARX-27: ribetes que toman el color de la skin (" .. #trims .. ")")
local factory = Weapons.Get("ARX27").Palette
check(trims[1].Color == (factory.Trim or factory.Dark), "de fábrica, los ribetes llevan el color de ribete de la paleta (o metal oscuro si no lo trae)")
local gold = WeaponModels.Build("ARX27", WeaponVisual.GoldSkin)
local goldTrim
for _, part in gold:GetChildren() do
	if part:IsA("BasePart") and part:GetAttribute("Role") == "Trim" then
		goldTrim = part
	end
end
check(goldTrim and goldTrim.Color == Skins.Get(WeaponVisual.GoldSkin).Accent, "con la skin de muestra (" .. WeaponVisual.GoldSkin .. "), los ribetes llevan su acento")
check(Skins.List[WeaponVisual.GoldSkin] ~= nil and Skins.List[WeaponVisual.GoldSkin].Collection == "RED OPS", "skin de muestra: RED OPS (existe en el juego)")

-- 7) Modelo externo: con los requisitos se usa; sin ellos, las piezas de siempre
local folder = mock.new("Folder"); folder.Name = "WeaponViewModels"; folder.Parent = game.ReplicatedStorage
local template = mock.new("Model"); template.Name = "ARX27Nuevo"; template.Parent = folder
local th = mock.new("Part"); th.Name = "Handle"; th.Parent = template
template.PrimaryPart = th
local body = mock.new("Part"); body.Name = "Receptor"; body:SetAttribute("Role", "Body"); body.Parent = template
local missing = WeaponVisual.ValidateModel(template)
check(#missing == 3, "modelo sin Attachments: faltan Muzzle, AimPoint y Eject (" .. table.concat(missing, ", ") .. ")")
WeaponVisual.Weapons.ARX27.Model = "ARX27Nuevo"
local warnings = 0
mock.onWarn = function()
	warnings += 1
end
local fallback = WeaponModels.Build("ARX27", "Default")
check(fallback:GetAttribute("External") ~= true and fallback:FindFirstChild("ChargingHandle") ~= nil and warnings == 1,
	"modelo incompleto: se usan las piezas de siempre y se avisa")
for _, name in { "Muzzle", "AimPoint", "Eject", "LeftHand" } do
	local a = mock.new("Attachment"); a.Name = name; a.Parent = th
end
check(#WeaponVisual.ValidateModel(template) == 0, "con sus Attachments, el modelo vale")
local external = WeaponModels.Build("ARX27", WeaponVisual.GoldSkin)
local receptor = external:FindFirstChild("Receptor")
check(external:GetAttribute("External") == true and receptor ~= nil and receptor.Color == Skins.Get(WeaponVisual.GoldSkin).Body,
	"modelo completo: se usa, pintado por papeles con la skin")
WeaponVisual.Weapons.ARX27.Model = nil
mock.onWarn = nil

-- 8) Audio: huecos del ARX-27 (vacíos: usan el sonido de siempre) y variación de tono pequeña
local slots = {}
for _, slot in Sounds.WeaponAudioSlots do
	slots[slot] = true
end
local needed = { "ShotClose", "ShotMechanical", "ShotTail", "Reload", "MagOut", "MagIn", "Bolt", "Empty", "Equip", "Unequip", "Inspect", "Melee" }
local absent = {}
for _, slot in needed do
	if not slots[slot] or Sounds.WeaponAudio.ARX27[slot] == nil then
		table.insert(absent, slot)
	end
end
check(#absent == 0, "ARX-27: todos los huecos de audio (" .. table.concat(absent, ", ") .. ")")
check(Sounds.WeaponSoundName("ARX27", "MagOut", "MagOut") == "W:ARX27:MagOut" and Sounds.WeaponSoundName("ARX27", "Inspect", nil) == "W:ARX27:Inspect"
	and Sounds.WeaponSoundName("ARX27", "Reload", nil) == nil, "ARX-27: sus huecos usan el audio de la familia Fusil (Reload, opcional, vacío)")
check(Sounds.GunPitchVariation == 0.02 and Sounds.PitchVariation >= Sounds.GunPitchVariation, "variación de tono de las armas: ±2 %")

-- 9) Presupuesto por calidad: en Baja sin luz del fogonazo (el resto de calidades, con luz)
check(WeaponFeel.Budget("Baja", false).MuzzleLight == false and WeaponFeel.Budget("Media", false).MuzzleLight == true
	and WeaponFeel.Budget("Alta", true).MuzzleLight == true, "luz del fogonazo: no en Baja; sí en Media y Alta")

-- 10) El ARX-27 no cambia de equilibrio (es una fase de presentación)
local d = Weapons.Get("ARX27")
check(d.Damage == 24 and d.MinDamage == 16 and d.FireRate == 10 and d.MagSize == 30 and d.ReloadTime == 1.9
	and d.Spread == 1.6 and d.AimSpread == 0.25 and d.Recoil == 0.8 and d.HeadshotMultiplier == 1.6 and d.Range == 600,
	"ARX-27: daño, cadencia, cargador, recarga, dispersión y retroceso de juego sin cambios")
print("PRESENTACION OK")
process.exit(0)
