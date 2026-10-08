-- Fase 2 (gunplay): perfiles de sensación de las armas, presupuestos de efectos, audio por capas y
-- juego limpio (los cosméticos no cambian nada del combate). Solo lógica: la SENSACIÓN se prueba en Studio.
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local game, req = mock.buildGame(process.args[1])
local Shared = game.ReplicatedStorage.Shared
local Weapons = req(Shared.Weapons)
local WeaponFeel = req(Shared.WeaponFeel)
local Sounds = req(Shared.Sounds)
local GameConfig = req(Shared.GameConfig)
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end

-- 1) Todas las armas de fuego tienen un perfil completo y con valores razonables
local SECTIONS = { "Camera", "View", "Aim", "Sway", "Bob", "Sprint", "Equip", "Flash", "Shells", "Heat" }
local guns = {}
for name, def in Weapons.List do
	if def.Type == "Gun" then
		table.insert(guns, name)
	end
end
table.sort(guns)
check(#guns >= 15, "hay armas de fuego (" .. #guns .. ")")
for _, name in guns do
	local def = Weapons.List[name]
	local feel = WeaponFeel.Get(name, def)
	check(WeaponFeel.Profiles[feel.Class] ~= nil, name .. ": tipo conocido (" .. feel.Class .. ")")
	for _, section in SECTIONS do
		assert(type(feel[section]) == "table", name .. " sin sección " .. section)
	end
	local cam, view, flash = feel.Camera, feel.View, feel.Flash
	assert(cam.Punch >= 0 and cam.Punch <= 2, name .. ": golpe de cámara razonable (≤ 2°)")
	assert(cam.Impulse > 0, name .. ": impulso calculado")
	assert(cam.AimScale > 0 and cam.AimScale <= 1 and view.AimScale > 0 and view.AimScale <= 1, name .. ": apuntando se mueve menos")
	assert(feel.Aim.Speed >= 8 and feel.Aim.Speed <= 20, name .. ": rapidez de apuntado entre 8 y 20")
	assert(feel.Aim.Sway <= 0.5 and feel.Aim.Bob <= 0.2, name .. ": apuntando casi no hay inercia ni balanceo")
	assert(feel.Equip.Time >= 0.25 and feel.Equip.Time <= 0.6, name .. ": sacar el arma es rápido")
	assert(feel.Sprint.Fov >= 0 and feel.Sprint.Fov <= 10, name .. ": FOV al correr moderado")
	if flash.Scale > 0 then
		assert(flash.Duration >= 0.03 and flash.Duration <= 0.08, name .. ": fogonazo de 0,03-0,08 s")
	end
	-- El golpe de cámara llega a sus grados y vuelve a 0 (no deja la mira desplazada)
	local x, v, peak = 0, math.rad(cam.Punch) * cam.Impulse, 0
	for _ = 1, 60 do -- 1 s a 60 fps
		x, v = WeaponFeel.StepSpring(x, v, cam.Stiffness, cam.Damping, 1 / 60)
		peak = math.max(peak, x)
	end
	if cam.Punch > 0 then
		assert(math.abs(math.deg(peak) - cam.Punch) <= cam.Punch * 0.25, name .. ": el pico del golpe ≈ " .. cam.Punch .. "° (" .. math.deg(peak) .. ")")
	end
	assert(math.abs(math.deg(x)) < 0.01, name .. ": el golpe de cámara vuelve a 0 en 1 s (" .. math.deg(x) .. "°)")
end
check(true, "perfiles completos, golpe de cámara calibrado y que vuelve a 0 en todas las armas")
-- El golpe es igual a cualquier tasa de fotogramas (30 fps en un móvil o 240 en un PC)
do
	local cam = WeaponFeel.Get("ARX27").Camera
	local function after(fps, seconds)
		local x, v = 0, math.rad(cam.Punch) * cam.Impulse
		for _ = 1, math.floor(fps * seconds + 0.5) do
			x, v = WeaponFeel.StepSpring(x, v, cam.Stiffness, cam.Damping, 1 / fps)
		end
		return x
	end
	local a, b = after(30, 0.1), after(240, 0.1)
	check(math.abs(a - b) < 1e-6, string.format("mismo golpe a 30 y 240 fps (%.6f vs %.6f)", a, b))
end

-- 2) El arma de referencia es el fusil de asalto
check(WeaponFeel.ReferenceWeapon == "ARX27" and WeaponFeel.Get("ARX27").Class == "Rifle", "arma de referencia: ARX-27 (fusil)")

-- 3) Cada tipo se siente distinto, en el sentido esperado
local rifle, smg, lmg = WeaponFeel.Get("ARX27"), WeaponFeel.Get("Specter9"), WeaponFeel.Get("TitanLMG")
local pistol, shotgun, sniper = WeaponFeel.Get("Viper"), WeaponFeel.Get("HavocPump"), WeaponFeel.Get("Signal7")
check(smg.Aim.Speed > rifle.Aim.Speed and rifle.Aim.Speed > lmg.Aim.Speed, "apuntar: subfusil > fusil > ametralladora")
check(pistol.Equip.Time < rifle.Equip.Time and rifle.Equip.Time < lmg.Equip.Time, "sacar el arma: pistola < fusil < ametralladora")
check(sniper.Camera.Punch > rifle.Camera.Punch and rifle.Camera.Punch > smg.Camera.Punch, "golpe de cámara: francotirador > fusil > subfusil")
check(shotgun.View.Back > rifle.View.Back and lmg.View.Stiffness < smg.View.Stiffness, "arma en la mano: escopeta patea más; ametralladora más pesada")
check(lmg.Bob.Walk < rifle.Bob.Walk and smg.Bob.Walk > rifle.Bob.Walk, "balanceo: ametralladora menos, subfusil más")
check(sniper.Flash.Duration > smg.Flash.Duration and shotgun.Flash.Scale > rifle.Flash.Scale, "fogonazo: más grande y largo en francotirador y escopeta")
check(WeaponFeel.Get("GhostlineXR").Flash.Light == 0, "con supresor, sin golpe de luz")
check(not WeaponFeel.Get("Crossbow").Shells.Enabled and not WeaponFeel.Get("NovaLauncher").Shells.Enabled, "ballesta y lanzacohetes sin casquillos")
-- (los que antes sacudían la cámara siguen haciéndolo, con la misma fuerza: Recoil ≥ 3)
for _, name in guns do
	local def, feel = Weapons.List[name], WeaponFeel.Get(name)
	local shakes = feel.Camera.Shake > 0
	assert(shakes == (def.Recoil >= 3), name .. ": sacude la cámara igual que antes (Recoil " .. def.Recoil .. ")")
	if shakes then
		assert(feel.Camera.Shake == 0.05 and feel.Camera.FovKick == 0.22, name .. ": misma fuerza de sacudida que antes")
	end
	-- calor del cañón como antes (escopetas y francotiradores calientan más; ballesta y paintball nada)
	local before = (name == "Crossbow" or name == "SplatX" or def.Explosive) and 0 or ((def.Pellets > 1 or def.Damage >= 60) and 4 or 1)
	assert(feel.Heat.PerShot == before, name .. ": calor del cañón como antes (" .. before .. ")")
end
check(true, "sacudida, FOV y calor del cañón iguales que antes de la Fase 2")

-- 4) El retroceso de juego es uno solo (equilibrio): los perfiles no lo tocan ni tocan estadísticas
local STATS = { "Damage", "MinDamage", "FireRate", "Spread", "AimSpread", "Recoil", "MagSize", "HeadshotMultiplier", "Range", "ReloadTime", "Gameplay" }
for class, profile in WeaponFeel.Profiles do
	for _, key in STATS do
		assert(profile[key] == nil, class .. " no cambia " .. key)
	end
end
for name, override in WeaponFeel.Overrides do
	for _, key in STATS do
		assert(override[key] == nil, name .. " no cambia " .. key)
	end
end
local GP = WeaponFeel.Gameplay
check(GP.Recover == 0.65 and GP.ClimbBase == 0.75 and GP.ClimbGrowth == 0.5 and GP.AimReduction == 0.35 and GP.BloomPerRecoil == 0.4 and GP.BloomMax == 6,
	"retroceso de juego con los valores de antes (sin cambiar el equilibrio)")

-- 5) Juego limpio: las skins no cambian nada del combate
local Loadout = req(game.ServerScriptService.Server.Modules.Loadout)
local Skins = req(Shared.Skins)
local skinIds = {}
for id in Skins.List do table.insert(skinIds, id) end
table.sort(skinIds)
check(#skinIds >= 2, "hay skins para comparar")
for _, name in { "ARX27", "Specter9", "Signal7" } do
	local a = Loadout.MakeTool(name, skinIds[1])
	local b = Loadout.MakeTool(name, skinIds[#skinIds])
	assert(a:GetAttribute("Weapon") == b:GetAttribute("Weapon"), "misma arma con cualquier skin")
	assert(Weapons.Get(a:GetAttribute("Weapon")) == Weapons.Get(b:GetAttribute("Weapon")), "mismas estadísticas con cualquier skin")
	assert(a:GetAttribute("Ammo") == b:GetAttribute("Ammo") and a:GetAttribute("Reserve") == b:GetAttribute("Reserve"), "misma munición con cualquier skin")
	assert(WeaponFeel.Get(name) == WeaponFeel.Get(name), "la sensación solo depende del arma")
end
check(true, "las skins no cambian daño, cadencia, retroceso, munición ni sensación")

-- 6) Presupuesto de efectos por calidad (y móvil)
for _, level in GameConfig.QualityLevels do
	if level ~= "Auto" then
		local desk, mobile = WeaponFeel.Budget(level, false), WeaponFeel.Budget(level, true)
		assert(desk.BulletMarks <= 50 and desk.BulletMarks >= 0, level .. ": marcas de bala con límite (≤ 50)")
		assert(mobile.BulletMarks <= desk.BulletMarks and mobile.ImpactParticles <= desk.ImpactParticles and (not mobile.Shells or desk.Shells),
			level .. ": en móvil nunca más efectos que en PC")
		assert(not mobile.Shells, level .. ": sin casquillos en móvil")
	end
end
local low = WeaponFeel.Budget("Baja", false)
check(not low.Shells and low.BulletMarks == 0 and not low.MuzzleSmoke and low.ImpactParticles < 1, "calidad Baja: sin casquillos ni marcas, impactos mínimos")
local high = WeaponFeel.Budget("Alta", false)
check(high.Shells and high.BulletMarks > 0 and high.ImpactParticles == 1, "calidad Alta: casquillos, marcas e impactos completos")
check(WeaponFeel.Budget("NoExiste", false).BulletMarks == WeaponFeel.Budget("Media", false).BulletMarks, "calidad desconocida = Media")

-- 7) Audio por capas: huecos de cada arma (vacíos = el sonido genérico de siempre)
for _, name in guns do
	local entry = Sounds.WeaponAudio[name]
	assert(entry ~= nil, name .. ": tiene huecos de audio")
	for _, slot in Sounds.WeaponAudioSlots do
		assert(type(entry[slot]) == "string" or type(entry[slot]) == "table", name .. ": hueco " .. slot)
	end
end
-- (Fase 9: a los 9 huecos de la Fase 2 se suman Unequip, Inspect y Melee)
local slotSet = {}
for _, slot in Sounds.WeaponAudioSlots do slotSet[slot] = true end
local allSlots = true
for _, slot in { "ShotClose", "ShotMechanical", "ShotTail", "Reload", "MagIn", "MagOut", "Bolt", "Empty", "Equip", "Unequip", "Inspect", "Melee" } do
	allSlots = allSlots and slotSet[slot] == true
end
check(#Sounds.WeaponAudioSlots == 12 and allSlots, "12 huecos por arma (los 9 de la Fase 2 + Unequip, Inspect y Melee)")
-- (Fase 11: cada arma de fuego usa el audio de su familia; el hueco propio del arma manda sobre él)
local rifleMagIn = Sounds.FamilyAudio.Rifle.MagIn
local familyKey = Sounds.WeaponSoundName("ARX27", "MagIn", "MagIn")
check(familyKey == "W:ARX27:MagIn" and Sounds[familyKey].Id == rifleMagIn.Id and Sounds[familyKey].Region ~= nil,
	"sin audio propio: el de su familia (con su trozo del archivo)")
check(Sounds.WeaponSoundName("SplatX", "MagIn", "MagIn") == "MagIn", "arma sin familia de audio: el genérico de siempre")
check(Sounds.WeaponSoundName("ARX27", "Reload", nil) == nil, "hueco vacío sin genérico: no suena nada")
check(Sounds.SlotDisabled("ARX27", "ShotMechanical") and not Sounds.SlotDisabled("SplatX", "ShotMechanical"),
	"la grabación ya lleva el mecanismo: esa capa se apaga (solo en las armas con familia)")
Sounds.WeaponAudio.ARX27.MagIn = "rbxassetid://1"
local custom = Sounds.WeaponSoundName("ARX27", "MagIn", "MagIn")
check(custom == "W:ARX27:MagIn" and Sounds[custom].Id == "rbxassetid://1", "con audio propio se usa el suyo")
Sounds.WeaponAudio.ARX27.MagIn = { Id = "rbxassetid://2", Volume = 0.5 }
local custom2 = Sounds.WeaponSoundName("ARX27", "MagIn", "MagIn")
check(Sounds[custom2].Id == "rbxassetid://2" and Sounds[custom2].Volume == 0.5, "audio propio con volumen")
Sounds.WeaponAudio.ARX27.MagIn = ""
check(Sounds[Sounds.WeaponSoundName("ARX27", "MagIn", "MagIn")].Id == rifleMagIn.Id, "al quitarlo vuelve el de su familia")
-- Variantes: con varias tomas, dos disparos seguidos nunca usan la misma
local rifleShot = Sounds[Sounds.WeaponSoundName("ARX27", "ShotClose", nil)]
check(rifleShot.Variants ~= nil and #rifleShot.Variants >= 2, "el disparo del fusil tiene varias tomas")
local lastId, repeated = nil, false
for _ = 1, 12 do
	local sound = Sounds.Play("W:ARX27:ShotClose", nil, 1, 1, "gun")
	if sound then
		repeated = repeated or sound.SoundId == lastId
		lastId = sound.SoundId
		sound.IsPlaying = false
	end
end
check(lastId ~= nil and not repeated, "las tomas se alternan sin repetir")
-- Todas las familias con disparo, recarga y manejo; y todo id es un rbxassetid real (no vacío)
for familyName, preset in Sounds.FamilyAudio do
	for _, slot in { "ShotClose", "MagOut", "MagIn", "Bolt", "Empty", "Equip" } do
		local value = preset[slot]
		assert(type(value) == "table" and (value.Id or value.Variants), familyName .. ": falta " .. slot)
	end
end
for weaponName, familyName in Sounds.WeaponAudioFamily do
	assert(Sounds.FamilyAudio[familyName] ~= nil and Sounds.WeaponAudio[weaponName] ~= nil, weaponName .. ": familia de audio " .. familyName)
end
check(true, "familias de audio completas (disparo, cargador, cerrojo, vacío, sacar)")

-- 8) La instrumentación de impactos viene apagada (no cambia nada en producción)
check(GameConfig.HitTelemetry ~= nil and GameConfig.HitTelemetry.Enabled == false, "instrumentación de impactos apagada por defecto")
print("SENSACION ARMAS OK")
process.exit(0)
