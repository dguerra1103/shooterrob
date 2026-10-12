-- Auditoría de un mapa (modo Edit de Studio): lo construye con una copia fresca de los módulos del
-- servidor y mide geometría, colisiones, apariciones, superficies coplanarias (z-fighting), piezas
-- flotantes, huecos del suelo y rutas. Uso: node mapaudit.js [Mapa ...] && node run.js mapaudit.json
local MAP = "__MAP__"
local SSS = game:GetService("ServerScriptService")
local PathfindingService = game:GetService("PathfindingService")
local server = SSS:FindFirstChild("Server")
local old = server:FindFirstChild("_AuditModules")
if old then
	old:Destroy()
end
local clone = server.Modules:Clone()
clone.Name = "_AuditModules"
clone.Parent = server
local MapCheck = require(clone.MapCheck)
MapCheck.Enabled = __CHECK__
local MapBuilder = require(clone.MapBuilder)
local def = MapBuilder.Defs[MAP]
local t0 = os.clock()
local okBuild, errBuild = pcall(MapBuilder.Build, MAP)
local buildTime = os.clock() - t0
if not okBuild then
	return "BUILD ERROR " .. tostring(errBuild)
end

local map = workspace.Map
local out = {}
local function add(s)
	out[#out + 1] = s
end
local function fmt(v)
	return ("(%.1f, %.1f, %.1f)"):format(v.X, v.Y, v.Z)
end
local function top(counts, n)
	local list = {}
	for k, v in counts do
		list[#list + 1] = { k, v }
	end
	table.sort(list, function(a, b)
		return a[2] > b[2]
	end)
	local s = {}
	for i = 1, math.min(n, #list) do
		s[i] = list[i][1] .. "×" .. (math.floor(list[i][2] * 10) / 10)
	end
	return table.concat(s, ", ")
end

local boundary = map:FindFirstChild("Boundary")
local callouts = map:FindFirstChild("Callouts")
local function special(p)
	return (boundary and p:IsDescendantOf(boundary)) or (callouts and p:IsDescendantOf(callouts))
end
local MARKERS = { FFASpawn = true, BotSpot = true, BombSite = true, HardpointZone = true, SiteLetter = true, Callout = true, Boundary = true }

local parts, classes = {}, {}
local lights, shadowLights, emitters, guis, textures, unanchored = 0, 0, 0, 0, 0, {}
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") then
		parts[#parts + 1] = d
		classes[d.ClassName] = (classes[d.ClassName] or 0) + 1
		if not d.Anchored then
			unanchored[d.Name] = (unanchored[d.Name] or 0) + 1
		end
	elseif d:IsA("Light") then
		lights += 1
		if d.Shadows then
			shadowLights += 1
		end
	elseif d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") then
		emitters += 1
	elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
		guis += 1
	elseif d:IsA("Texture") or d:IsA("Decal") then
		textures += 1
	end
end
local castShadow = 0
for _, p in parts do
	if p.CastShadow and p.Transparency < 1 then
		castShadow += 1
	end
end
add(("== %s · build %.2fs · piezas %d (%s) · sombra %d · luces %d (con sombra %d) · emisores %d · guis %d · texturas %d"):format(MAP, buildTime, #parts, top(classes, 6), castShadow, lights, shadowLights, emitters, guis, textures))
add("variante=" .. tostring(map:GetAttribute("Variant")) .. " · repaso: " .. tostring(map:GetAttribute("MapCheck")))
if next(unanchored) then
	add("SIN ANCLAR: " .. top(unanchored, 12))
end

-- Colisiones raras
local invis, ghost = {}, {}
local ghostSample = {}
for _, p in parts do
	if not special(p) and not MARKERS[p.Name] then
		if p.Transparency >= 0.95 and p.CanCollide then
			invis[p.Name] = (invis[p.Name] or 0) + 1
		end
		local s = p.Size
		local dims = { s.X, s.Y, s.Z }
		table.sort(dims)
		if p.Transparency < 0.5 and not p.CanCollide and dims[2] >= 4 and dims[3] >= 6 and dims[1] >= 0.4 and p.Position.Y - s.Y / 2 < 6 and p.Position.Y + s.Y / 2 > 1.5 then
			ghost[p.Name] = (ghost[p.Name] or 0) + 1
			ghostSample[p.Name] = fmt(p.Position) .. " " .. fmt(s)
		end
	end
end
if next(invis) then
	add("INVISIBLE QUE CHOCA: " .. top(invis, 12))
end
if next(ghost) then
	local s = {}
	for k, v in ghost do
		s[#s + 1] = k .. "×" .. v .. " p.ej. " .. ghostSample[k]
	end
	add("VISIBLE GRANDE QUE SE ATRAVIESA (a la altura del jugador):\n   " .. table.concat(s, "\n   "))
end

-- Cajas alineadas con los ejes
local boxes = {}
for i, p in parts do
	local cf, s = p.CFrame, p.Size
	local rx, ry, rz = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = (math.abs(rx.X) * s.X + math.abs(ry.X) * s.Y + math.abs(rz.X) * s.Z) / 2
	local hy = (math.abs(rx.Y) * s.X + math.abs(ry.Y) * s.Y + math.abs(rz.Y) * s.Z) / 2
	local hz = (math.abs(rx.Z) * s.X + math.abs(ry.Z) * s.Y + math.abs(rz.Z) * s.Z) / 2
	local c = cf.Position
	local function ax(v)
		local m = math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
		return m > 0.9999
	end
	boxes[i] = {
		p = p, c = c,
		x0 = c.X - hx, x1 = c.X + hx, y0 = c.Y - hy, y1 = c.Y + hy, z0 = c.Z - hz, z1 = c.Z + hz,
		aligned = ax(rx) and ax(ry) and ax(rz),
		block = p:IsA("Part") and p.Shape == Enum.PartType.Block,
	}
end

-- Z-fighting: caras coplanarias que miran al mismo lado y se solapan
local buckets = {}
local function face(b, axis, sign, coord, a0, a1, b0, b1)
	for _, k in { math.floor(coord * 125), math.floor(coord * 125 + 0.5) + 100000000 } do
		local key = axis .. sign .. k
		local list = buckets[key]
		if not list then
			list = {}
			buckets[key] = list
		end
		list[#list + 1] = { b = b, coord = coord, a0 = a0, a1 = a1, b0 = b0, b1 = b1 }
	end
end
for _, b in boxes do
	local p = b.p
	if b.aligned and (b.block or p.Name == "ContactShadow") and p.Transparency < 0.98 and not special(p) and not MARKERS[p.Name] then
		face(b, "x", "+", b.x1, b.y0, b.y1, b.z0, b.z1)
		face(b, "x", "-", b.x0, b.y0, b.y1, b.z0, b.z1)
		face(b, "y", "+", b.y1, b.x0, b.x1, b.z0, b.z1)
		face(b, "y", "-", b.y0, b.x0, b.x1, b.z0, b.z1)
		face(b, "z", "+", b.z1, b.x0, b.x1, b.y0, b.y1)
		face(b, "z", "-", b.z0, b.x0, b.x1, b.y0, b.y1)
	end
end
local zPairs, zArea, zNames, zWorst, zSeen = 0, 0, {}, {}, {}
for key, list in buckets do
	if #list > 1 and #list < 400 then
		for i = 1, #list - 1 do
			local f = list[i]
			for j = i + 1, #list do
				local g = list[j]
				if f.b ~= g.b and math.abs(f.coord - g.coord) < 0.004 and not (string.sub(key, 1, 2) == "y-" and f.coord < 2) then
					local da = math.min(f.a1, g.a1) - math.max(f.a0, g.a0)
					local db = math.min(f.b1, g.b1) - math.max(f.b0, g.b0)
					if da > 0.15 and db > 0.15 then
						local p, q = f.b.p, g.b.p
						-- (mismo color y material: no se nota)
						local pairId = tostring(f.b) .. tostring(g.b) .. string.sub(key, 1, 2)
						if not zSeen[pairId] and (p.Color ~= q.Color or p.Material ~= q.Material or p.Transparency ~= q.Transparency) then
							zSeen[pairId] = true
							local area = da * db
							zPairs += 1
							zArea += area
							local name = p.Name < q.Name and (p.Name .. "/" .. q.Name) or (q.Name .. "/" .. p.Name)
							zNames[name] = (zNames[name] or 0) + area
							zWorst[#zWorst + 1] = { area, name, f.b.c, string.sub(key, 1, 2) }
						end
					end
				end
			end
		end
	end
end
table.sort(zWorst, function(a, b)
	return a[1] > b[1]
end)
add(("Z-FIGHTING: %d pares, %.0f studs²; por nombre (área): %s"):format(zPairs, zArea, top(zNames, 14)))
for i = 1, math.min(8, #zWorst) do
	local w = zWorst[i]
	add(("   %.0f st² %s cara %s en %s"):format(w[1], w[2], w[4], fmt(w[3])))
end

-- Piezas flotantes: nada las toca y el terreno no está debajo
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
local floating, floatSample, floatCount = {}, {}, 0
local nb = #boxes
for i = 1, nb do
	local a = boxes[i]
	local p = a.p
	local s = p.Size
	if p.Transparency < 0.98 and not special(p) and not MARKERS[p.Name] and s.X * s.Y * s.Z >= 1 and not p:FindFirstChildWhichIsA("Light") then
		local touched = false
		local e = 0.06
		for j = 1, nb do
			if j ~= i then
				local b = boxes[j]
				if a.x0 - e < b.x1 and a.x1 + e > b.x0 and a.y0 - e < b.y1 and a.y1 + e > b.y0 and a.z0 - e < b.z1 and a.z1 + e > b.z0 then
					local q = b.p
					if q.Transparency < 0.98 and not MARKERS[q.Name] and not special(q) then
						touched = true
						break
					end
				end
			end
		end
		if not touched then
			local hit = workspace:Raycast(Vector3.new(a.c.X, a.y0 + 0.5, a.c.Z), Vector3.new(0, -1.2, 0), terrainOnly)
			if not hit then
				floatCount += 1
				floating[p.Name] = (floating[p.Name] or 0) + 1
				floatSample[p.Name] = fmt(p.Position) .. " tam " .. fmt(s) .. (p.CanCollide and " CHOCA" or "")
			end
		end
	end
end
if floatCount > 0 then
	local s = {}
	for k, v in floating do
		s[#s + 1] = k .. "×" .. v .. " p.ej. " .. floatSample[k]
	end
	table.sort(s)
	add("FLOTANTES (" .. floatCount .. "):\n   " .. table.concat(s, "\n   "))
end

-- Fuera de sitio
local B = def.Bounds or Vector3.new(300, 70, 240)
local far = {}
for _, b in boxes do
	if not special(b.p) and (b.y1 < -12 or math.abs(b.c.X) > B.X / 2 + 150 or math.abs(b.c.Z) > B.Z / 2 + 150 or b.y0 > B.Y + 80) then
		far[b.p.Name] = (far[b.p.Name] or 0) + 1
	end
end
if next(far) then
	add("MUY LEJOS/ENTERRADAS: " .. top(far, 10))
end

-- Suelo: rejilla de rayos (solo lo que choca)
local solid = RaycastParams.new()
solid.FilterType = Enum.RaycastFilterType.Exclude
solid.FilterDescendantsInstances = { boundary, callouts }
solid.RespectCanCollide = true
local holes, pits, water, total = {}, {}, 0, 0
for x = -B.X / 2 + 3, B.X / 2 - 3, 6 do
	for z = -B.Z / 2 + 3, B.Z / 2 - 3, 6 do
		total += 1
		local hit = workspace:Raycast(Vector3.new(x, B.Y - 2, z), Vector3.new(0, -(B.Y + 60), 0), solid)
		if not hit then
			holes[#holes + 1] = ("(%d,%d)"):format(x, z)
		elseif hit.Material == Enum.Material.Water then
			water += 1
		elseif hit.Position.Y < -1.5 then
			pits[#pits + 1] = ("(%d,%d y=%.1f %s)"):format(x, z, hit.Position.Y, hit.Instance.Name)
		end
	end
end
add(("SUELO: %d puntos · sin suelo %d · hoyos %d · agua %d"):format(total, #holes, #pits, water))
if #holes > 0 then
	add("   sin suelo: " .. table.concat(holes, " ", 1, math.min(#holes, 14)))
end
if #pits > 0 then
	add("   hoyos: " .. table.concat(pits, " ", 1, math.min(#pits, 10)))
end

-- Apariciones y puntos de juego
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.RespectCanCollide = true
local spawns, objectives = {}, {}
local bad = {}
for _, p in parts do
	local isSpawn = p:IsA("SpawnLocation") or p.Name == "FFASpawn"
	if isSpawn or p.Name == "BotSpot" then
		local pos = p.Position + Vector3.new(0, p.Size.Y / 2, 0)
		if isSpawn then
			spawns[#spawns + 1] = p
		end
		overlap.FilterDescendantsInstances = { p, boundary, callouts }
		local inside = workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 3.1, 0)), Vector3.new(2.6, 5, 2.6), overlap)
		local real = {}
		for _, q in inside do
			if q ~= p and q.CanCollide then
				real[#real + 1] = q.Name
			end
		end
		local down = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), solid)
		local up = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, 7, 0), solid)
		local gap = down and (pos.Y - down.Position.Y) or 999
		if #real > 0 then
			bad[#bad + 1] = ("%s %s DENTRO DE %s"):format(p.Name, fmt(pos), table.concat(real, "+", 1, math.min(3, #real)))
		elseif gap > 2.5 then
			bad[#bad + 1] = ("%s %s SUELO A %.1f"):format(p.Name, fmt(pos), gap)
		elseif up and up.Position.Y - pos.Y < 5.6 and isSpawn then
			bad[#bad + 1] = ("%s %s TECHO A %.1f (%s)"):format(p.Name, fmt(pos), up.Position.Y - pos.Y, up.Instance.Name)
		end
	elseif p.Name == "FlagBase" or p.Name == "BombSite" or p.Name == "HardpointZone" or p:GetAttribute("DomPoint") or p.Name == "DomPoint" then
		objectives[#objectives + 1] = p
	end
end
add(("PUNTOS: apariciones %d · objetivos %d · problemas %d"):format(#spawns, #objectives, #bad))
for i = 1, math.min(#bad, 14) do
	add("   " .. bad[i])
end

-- Rutas: desde la primera aparición de cada equipo a todo lo demás
local origins = {}
for _, p in spawns do
	if p:IsA("SpawnLocation") then
		local key = p.TeamColor.Name
		origins[key] = origins[key] or p
	end
end
local function route(a, b)
	for _, radius in { 2, 1 } do
		local path = PathfindingService:CreatePath({ AgentRadius = radius, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 8 })
		local ok = pcall(function()
			path:ComputeAsync(a, b)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			local w = path:GetWaypoints()
			if math.abs(w[#w].Position.Y - (b.Y - 3)) < 6 then
				return radius
			end
		end
	end
	return nil
end
-- (la malla de navegación tarda: se espera a que haya ruta entre las dos bases)
local navStart, navReady = os.clock(), false
do
	local a, b
	for _, p in spawns do
		if p:IsA("SpawnLocation") then
			if p.Position.X < 0 then a = a or p else b = b or p end
		end
	end
	while a and b and os.clock() - navStart < 45 do
		if route(a.Position + Vector3.new(0, 3, 0), b.Position + Vector3.new(0, 3, 0)) then
			navReady = true
			break
		end
		task.wait(1)
	end
	task.wait(3)
end
add(("MALLA DE NAVEGACIÓN: %s a los %.0f s"):format(navReady and "lista" or "SIN RUTA ENTRE BASES", os.clock() - navStart - 3))
local fails, narrow, routes = {}, 0, 0
for _, origin in origins do
	local from = origin.Position + Vector3.new(0, 3, 0)
	local targets = {}
	for _, p in spawns do
		targets[#targets + 1] = p
	end
	for _, p in objectives do
		targets[#targets + 1] = p
	end
	for _, p in parts do
		if p.Name == "BotSpot" then
			targets[#targets + 1] = p
		end
	end
	for _, target in targets do
		if target ~= origin then
			routes += 1
			local r = route(from, target.Position + Vector3.new(0, 3, 0))
			if not r then
				fails[#fails + 1] = target.Name .. fmt(target.Position)
			elseif r == 1 then
				narrow += 1
			end
		end
	end
	break -- (el mapa es simétrico: con un equipo basta)
end
add(("RUTAS: %d · sin ruta %d · solo con radio 1: %d"):format(routes, #fails, narrow))
if #fails > 0 then
	add("   sin ruta: " .. table.concat(fails, " ", 1, math.min(#fails, 12)))
end
return table.concat(out, "\n")
