-- Repaso de cada mapa nada más construirlo (lo llama MapBuilder.Build). Dos partes:
--
--   Finalize (inmediato): arregla lo que se puede arreglar solo y de forma segura.
--     * Sombras de contacto: se apoyan en el suelo que de verdad tienen debajo (una losa, no el
--       terreno) y las que se pisan entre sí van a alturas distintas. Antes iban todas a y = 0,02:
--       quedaban enterradas bajo las losas o coplanarias entre sí y con el suelo, y parpadeaban.
--     * Caras coplanarias de piezas con distinto aspecto (suelos montados, marcos enrasados con su
--       muro): la cara de la pieza pequeña se saca 1 cm. Sin eso, las dos se pelean por el mismo
--       píxel (z-fighting) y la superficie parpadea al moverse, sobre todo en móvil.
--     * Puntos de aparición libres y puestos de bots metidos dentro de un objeto o sin sitio para un
--       personaje: se llevan al hueco libre más cercano a la misma altura.
--
--   Verify (en segundo plano, cuando la malla de navegación ya existe): comprueba que desde la base
--   se llega a los objetivos, a los puntos de aparición y a los puestos de los bots, y deja escrito
--   lo que encuentre (warn en la consola y atributos en workspace.Map: MapCheck, MapCheckIssues,
--   NavReady). No cambia nada: es el aviso para la siguiente vez que algo se rompa.
local PathfindingService = game:GetService("PathfindingService")

local MapCheck = {}

MapCheck.Enabled = true
MapCheck.Report = {} -- (último mapa: lista de textos)
MapCheck.Stats = {}

local V = Vector3.new

local MARKERS = {
	FFASpawn = true, BotSpot = true, BombSite = true, HardpointZone = true, SiteLetter = true,
	Callout = true, Boundary = true, PlayerClip = true, RailCollider = true,
}

-- Piezas pintadas en el suelo: todas se apoyan en su suelo real y se separan entre sí
local GROUND = {
	ContactShadow = true, OilStain = true, Crack = true, TireMark = true, Puddle = true, Manhole = true, ManholeRim = true,
}

local SHADOW_BASE = 0.016 -- la sombra más baja, sobre su suelo
local SHADOW_STEP = 0.011 -- entre sombras que se pisan
local FACE_PUSH = 0.012 -- lo que sale la cara de la pieza pequeña

local function note(text)
	table.insert(MapCheck.Report, text)
end

---------------------------------------------------------------------------
-- Cajas de las piezas
---------------------------------------------------------------------------

local function entry(p)
	local cf, s = p.CFrame, p.Size
	local rx, ry, rz = cf.RightVector, cf.UpVector, cf.LookVector
	local hx = (math.abs(rx.X) * s.X + math.abs(ry.X) * s.Y + math.abs(rz.X) * s.Z) / 2
	local hy = (math.abs(rx.Y) * s.X + math.abs(ry.Y) * s.Y + math.abs(rz.Y) * s.Z) / 2
	local hz = (math.abs(rx.Z) * s.X + math.abs(ry.Z) * s.Y + math.abs(rz.Z) * s.Z) / 2
	local c = cf.Position
	local function axis(v)
		return math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z)) > 0.9999
	end
	return {
		p = p,
		x0 = c.X - hx, x1 = c.X + hx, y0 = c.Y - hy, y1 = c.Y + hy, z0 = c.Z - hz, z1 = c.Z + hz,
		aligned = axis(rx) and axis(ry) and axis(rz),
		block = p:IsA("Part") and p.Shape == Enum.PartType.Block,
	}
end

local function refresh(e)
	local fresh = entry(e.p)
	for k, v in fresh do
		e[k] = v
	end
end

local function collect(map)
	local boundary = map:FindFirstChild("Boundary")
	local callouts = map:FindFirstChild("Callouts")
	local list, shadows = {}, {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and not (boundary and d:IsDescendantOf(boundary)) and not (callouts and d:IsDescendantOf(callouts)) then
			if GROUND[d.Name] then
				table.insert(shadows, entry(d))
			elseif not MARKERS[d.Name] and d.Transparency < 0.98 then
				table.insert(list, entry(d))
			end
		end
	end
	return list, shadows
end

---------------------------------------------------------------------------
-- Sombras de contacto
---------------------------------------------------------------------------

local CELL = 16

local function cells(e, fn)
	for cx = math.floor(e.x0 / CELL), math.floor(e.x1 / CELL) do
		for cz = math.floor(e.z0 / CELL), math.floor(e.z1 / CELL) do
			fn(cx * 4096 + cz)
		end
	end
end

local function fixShadows(list, shadows)
	if #shadows == 0 then
		return 0
	end
	-- Suelos posibles: piezas rectas y a ras de suelo, visibles (losas, aceras, zonas pintadas)
	local floors = {}
	for _, e in list do
		if e.aligned and e.block and e.y1 > -0.6 and e.y1 < 0.75 and (e.x1 - e.x0) * (e.z1 - e.z0) >= 4 and not e.p:IsA("SpawnLocation") then
			cells(e, function(key)
				local bucket = floors[key]
				if not bucket then
					bucket = {}
					floors[key] = bucket
				end
				table.insert(bucket, e)
			end)
		end
	end
	local function floorAt(x, z)
		local best = 0 -- (el terreno)
		local bucket = floors[math.floor(x / CELL) * 4096 + math.floor(z / CELL)]
		if bucket then
			for _, e in bucket do
				if x > e.x0 and x < e.x1 and z > e.z0 and z < e.z1 and e.y1 > best then
					best = e.y1
				end
			end
		end
		return best
	end
	for _, s in shadows do
		local inset = 0.12
		s.base = math.max(
			floorAt(s.x0 + inset, s.z0 + inset), floorAt(s.x1 - inset, s.z0 + inset),
			floorAt(s.x0 + inset, s.z1 - inset), floorAt(s.x1 - inset, s.z1 - inset)
		)
		s.area = (s.x1 - s.x0) * (s.z1 - s.z0)
	end
	-- Las grandes (y claras) abajo; las pequeñas (y oscuras) encima
	table.sort(shadows, function(a, b)
		return a.area > b.area
	end)
	local placed = {}
	local moved = 0
	for _, s in shadows do
		local near = {}
		cells(s, function(key)
			for _, o in placed[key] or {} do
				if s.x0 < o.x1 and s.x1 > o.x0 and s.z0 < o.z1 and s.z1 > o.z0 then
					near[o] = true
				end
			end
		end)
		local top = s.base + SHADOW_BASE
		local clear = false
		while not clear do
			clear = true
			for o in near do
				if math.abs(o.top - top) < SHADOW_STEP * 0.8 then
					top += SHADOW_STEP
					clear = false
					break
				end
			end
		end
		s.top = top
		if math.abs(top - s.y1) > 0.0005 then
			s.p.CFrame += V(0, top - s.y1, 0)
			moved += 1
		end
		s.y0, s.y1 = top - (s.y1 - s.y0), top
		cells(s, function(key)
			local bucket = placed[key]
			if not bucket then
				bucket = {}
				placed[key] = bucket
			end
			table.insert(bucket, s)
		end)
	end
	return moved
end

---------------------------------------------------------------------------
-- Caras coplanarias
---------------------------------------------------------------------------

local WORLD = { x = V(1, 0, 0), y = V(0, 1, 0), z = V(0, 0, 1) }

-- Saca la cara (eje, signo) de una pieza recta sin mover la contraria
local function pushFace(e, axis, sign, push)
	local p = e.p
	local cf, size = p.CFrame, p.Size
	local world = WORLD[axis]
	local sx, sy, sz = size.X, size.Y, size.Z
	if math.abs(cf.RightVector:Dot(world)) > 0.99 then
		sx += push
	elseif math.abs(cf.UpVector:Dot(world)) > 0.99 then
		sy += push
	else
		sz += push
	end
	p.Size = V(sx, sy, sz)
	p.CFrame = cf + world * (sign * push / 2)
	refresh(e)
end

local function sameLook(p, q)
	return p.Color == q.Color and p.Material == q.Material and p.Transparency == q.Transparency
end

local function fixFaces(list, shadows)
	local all = table.clone(list)
	for _, s in shadows do
		table.insert(all, s)
	end
	local fixed = 0
	-- (varias pasadas: al sacar una cara puede quedar enrasada con otra. Cada pasada saca un poco
	-- menos, para que dos piezas que salieron a la vez no vuelvan a coincidir)
	for pass = 1, 6 do
		local push = FACE_PUSH - (pass - 1) * 0.0015
		local buckets = {}
		local function face(e, axis, sign, coord, a0, a1, b0, b1)
			-- (dos cubos por cara: así dos caras a menos de 4 mm coinciden siempre en alguno)
			for _, key in { math.floor(coord * 125), math.floor(coord * 125 + 0.5) + 100000000 } do
				local id = axis .. sign .. key
				local bucket = buckets[id]
				if not bucket then
					bucket = {}
					buckets[id] = bucket
				end
				table.insert(bucket, { e = e, axis = axis, sign = sign, coord = coord, a0 = a0, a1 = a1, b0 = b0, b1 = b1 })
			end
		end
		for _, e in all do
			if e.aligned and (e.block or GROUND[e.p.Name]) then
				if e.block then
					face(e, "x", 1, e.x1, e.y0, e.y1, e.z0, e.z1)
					face(e, "x", -1, e.x0, e.y0, e.y1, e.z0, e.z1)
					face(e, "z", 1, e.z1, e.x0, e.x1, e.y0, e.y1)
					face(e, "z", -1, e.z0, e.x0, e.x1, e.y0, e.y1)
					if e.y0 > 2 then
						face(e, "y", -1, e.y0, e.x0, e.x1, e.z0, e.z1) -- (techos: solo se ven desde abajo)
					end
				end
				face(e, "y", 1, e.y1, e.x0, e.x1, e.z0, e.z1)
			end
		end
		local done = {}
		local round = 0
		for _, bucket in buckets do
			local n = #bucket
			if n > 1 and n < 600 then
				for i = 1, n - 1 do
					local f = bucket[i]
					for j = i + 1, n do
						local g = bucket[j]
						if f.e ~= g.e and math.abs(f.coord - g.coord) < 0.004 then
							local da = math.min(f.a1, g.a1) - math.max(f.a0, g.a0)
							local db = math.min(f.b1, g.b1) - math.max(f.b0, g.b0)
							if da > 0.15 and db > 0.15 and not sameLook(f.e.p, g.e.p) then
								-- La pequeña sale (la sombra nunca: es la que se queda debajo)
								local fa = (f.a1 - f.a0) * (f.b1 - f.b0)
								local ga = (g.a1 - g.a0) * (g.b1 - g.b0)
								local small = fa <= ga and f or g
								local other = small == f and g or f
								if GROUND[small.e.p.Name] or small.e.p:IsA("SpawnLocation") or not small.e.block then
									small = other
								end
								local id = tostring(small.e) .. small.axis .. small.sign
								if small.e.block and not small.e.p:IsA("SpawnLocation") and not GROUND[small.e.p.Name] and not done[id] then
									done[id] = true
									pushFace(small.e, small.axis, small.sign, push)
									round += 1
								end
							end
						end
					end
				end
			end
		end
		fixed += round
		if round == 0 then
			break
		end
	end
	return fixed
end

---------------------------------------------------------------------------
-- Puntos de aparición y puestos de bots
---------------------------------------------------------------------------

local function spotParams(map, ignore)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { ignore, map:FindFirstChild("Callouts") }
	overlap.RespectCanCollide = true
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { ignore, map:FindFirstChild("Callouts"), map:FindFirstChild("Boundary") }
	ray.RespectCanCollide = true
	return overlap, ray
end

-- ¿Cabe un personaje de pie en floor (punto del suelo)? Devuelve el nombre de lo que estorba
local function blocked(floor, overlap, ray)
	local hits = workspace:GetPartBoundsInBox(CFrame.new(floor + V(0, 3.2, 0)), V(2.7, 5, 2.7), overlap)
	local map = workspace:FindFirstChild("Map")
	for _, q in hits do
		-- (solo piezas del mapa: un personaje que esté ahí en ese momento no cuenta)
		if q.CanCollide and map and q:IsDescendantOf(map) then
			return q.Name
		end
	end
	local down = workspace:Raycast(floor + V(0, 2.5, 0), V(0, -6, 0), ray)
	if down and map and not down.Instance:IsA("Terrain") and not down.Instance:IsDescendantOf(map) then
		return nil -- (el rayo dio en un personaje que estaba encima: no dice nada del suelo)
	end
	if not down then
		return "sin suelo"
	elseif math.abs(down.Position.Y - floor.Y) > 1.6 then
		return "suelo a otra altura"
	end
	return nil
end

local function freeSpot(floor, overlap, ray)
	for _, radius in { 2.5, 4, 6, 8, 11 } do
		for i = 0, 11 do
			local angle = i * math.pi / 6
			local candidate = floor + V(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			local down = workspace:Raycast(candidate + V(0, 2.5, 0), V(0, -5, 0), ray)
			if down and math.abs(down.Position.Y - floor.Y) < 1 then
				local point = V(candidate.X, down.Position.Y, candidate.Z)
				-- (sin pared de por medio: que no cambie de habitación)
				local between = workspace:Raycast(floor + V(0, 3, 0), point - floor, ray)
				if not between and not blocked(point, overlap, ray) then
					return point
				end
			end
		end
	end
	return nil
end

local function fixSpots(map)
	local moved, broken = 0, 0
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") and (p.Name == "FFASpawn" or p.Name == "BotSpot" or p:IsA("SpawnLocation")) then
			local overlap, ray = spotParams(map, p)
			local floor = p.Position - V(0, p:IsA("SpawnLocation") and -p.Size.Y / 2 or 0.5, 0)
			local why = blocked(floor, overlap, ray)
			if why and p:IsA("SpawnLocation") then
				broken += 1
				note(("aparición de equipo %s en (%.0f, %.0f, %.0f): %s"):format(p.Name, floor.X, floor.Y, floor.Z, why))
			elseif why then
				local spot = freeSpot(floor, overlap, ray)
				if spot then
					p.Position = spot + V(0, 0.5, 0)
					p:SetAttribute("MovedFrom", floor)
					moved += 1
				else
					broken += 1
					p:SetAttribute("Blocked", true)
					if p.Name == "FFASpawn" then
						p.Name = "FFASpawnBlocked" -- (nadie aparece aquí)
					end
					note(("%s en (%.0f, %.0f, %.0f): %s y sin hueco libre cerca"):format(p.Name, floor.X, floor.Y, floor.Z, why))
				end
			end
		end
	end
	return moved, broken
end

---------------------------------------------------------------------------
-- Entrada
---------------------------------------------------------------------------

function MapCheck.Finalize(map)
	MapCheck.Report = {}
	MapCheck.Stats = {}
	if not MapCheck.Enabled or not map then
		return
	end
	local started = os.clock()
	local list, shadows = collect(map)
	local stats = MapCheck.Stats
	stats.Parts = #list + #shadows
	stats.Shadows = fixShadows(list, shadows)
	stats.Faces = fixFaces(list, shadows)
	stats.SpotsMoved, stats.SpotsBroken = fixSpots(map)
	stats.Time = os.clock() - started
	map:SetAttribute("MapCheck", ("sombras %d · caras %d · puntos movidos %d · puntos sin arreglo %d · %.0f ms"):format(stats.Shadows, stats.Faces, stats.SpotsMoved, stats.SpotsBroken, stats.Time * 1000))
end

local function route(from, to)
	local path = PathfindingService:CreatePath({ AgentRadius = 1, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 8 })
	local ok = pcall(function()
		path:ComputeAsync(from, to)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		return false
	end
	-- (una ruta que acaba a otra altura no llega: es otra planta de la malla de navegación)
	local waypoints = path:GetWaypoints()
	local last = waypoints[#waypoints]
	return last ~= nil and math.abs(last.Position.Y - (to.Y - 3)) < 6
end

-- Rutas desde la base de cada equipo. Espera a que exista la malla de navegación (tarda unos
-- segundos después de construir el mapa). wait = false: sin esperar (para las pruebas)
function MapCheck.Verify(map, onDone)
	if not MapCheck.Enabled or not map then
		return
	end
	task.spawn(function()
		local origins, targets = {}, {}
		for _, p in map:GetDescendants() do
			if p:IsA("SpawnLocation") then
				local key = p.TeamColor.Name
				origins[key] = origins[key] or p
			end
			if p:IsA("BasePart") and (p:IsA("SpawnLocation") or p.Name == "FFASpawn" or p.Name == "BotSpot" or p.Name == "FlagBase" or p.Name == "BombSite" or p.Name == "HardpointZone") then
				table.insert(targets, p)
			end
		end
		local list = {}
		for _, origin in origins do
			table.insert(list, origin)
		end
		if #list == 0 then
			return
		end
		-- La malla: lista cuando hay ruta entre las dos bases (o a cualquier otro punto)
		local started = os.clock()
		local probe = list[2] or targets[1]
		local ready = false
		while os.clock() - started < 40 and map.Parent do
			if route(list[1].Position + V(0, 3, 0), probe.Position + V(0, 3, 0)) then
				ready = true
				break
			end
			task.wait(1)
		end
		if not map.Parent then
			return
		end
		map:SetAttribute("NavReady", ready and math.floor((os.clock() - started) * 10) / 10 or -1)
		if not ready then
			note("sin ruta entre las bases a los 40 s: los bots no pueden cruzar el mapa")
		end
		local unreachable, retired = 0, 0
		for _, target in targets do
			local reached = false
			for _, origin in list do
				if origin == target or route(origin.Position + V(0, 3, 0), target.Position + V(0, 3, 0)) then
					reached = true
					break
				end
			end
			if not reached then
				unreachable += 1
				target:SetAttribute("Unreachable", true)
				if target.Name == "FFASpawn" then
					-- (nadie aparece donde no se puede salir a pie: puede ser un hueco cerrado)
					target.Name = "FFASpawnBlocked"
					retired += 1
				end
				note(("sin ruta a pie hasta %s en (%.0f, %.0f, %.0f)"):format(target.Name, target.Position.X, target.Position.Y, target.Position.Z))
			end
			if not map.Parent then
				return
			end
		end
		MapCheck.Stats.Unreachable = unreachable
		if retired > 0 then
			map:SetAttribute("SpawnsVersion", (map:GetAttribute("SpawnsVersion") or 0) + 1)
		end
		map:SetAttribute("MapCheckIssues", #MapCheck.Report)
		map:SetAttribute("MapCheckText", table.concat(MapCheck.Report, "\n", 1, math.min(#MapCheck.Report, 20)))
		if #MapCheck.Report > 0 then
			warn(("[MapCheck] %s: %d avisos\n  %s"):format(tostring(map:GetAttribute("MapName")), #MapCheck.Report, table.concat(MapCheck.Report, "\n  ", 1, math.min(#MapCheck.Report, 20))))
		end
		if onDone then
			onDone(MapCheck.Report)
		end
	end)
end

return MapCheck
