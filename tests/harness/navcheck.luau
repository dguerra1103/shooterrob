-- Navegación de un mapa: mapa de alturas (celdas de 0,5) con todos los suelos de cada celda que
-- tienen 5 studs libres encima; grafo andar (≤1,1), saltar (≤6,8), supersalto (≤16,5) y caer.
-- Desde las bases calcula qué se alcanza y avisa de: puntos de juego inalcanzables, sitios altos
-- alcanzables que no deberían, y trampas (se llega pero no se puede volver a la base).
-- Uso: lune run navcheck.luau <src> <MapId> [allowedHeights separadas por comas]
local process = require("@lune/process")
local mock = require("./mock")
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local game, req = mock.buildGame(process.args[1])
local GameConfig = req(game.ReplicatedStorage.Shared.GameConfig)
for _, cfg in GameConfig.Teams do
	local t = mock.new("Team"); t.Name = cfg.Name; t.TeamColor = cfg.Color; t.Parent = game:GetService("Teams")
end
local MapBuilder = req(game.ServerScriptService.Server.Modules.MapBuilder)
local id = process.args[2] or MapBuilder.Order[1]
MapBuilder.Build(id)
local map = game.Workspace.Map

local STEP = 0.5
local CLEAR = 5.0
local WALK, JUMP, SUPER = 1.1, 6.8, 16.5

-- Piezas sólidas
local solids = {}
local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") and d.CanCollide ~= false then
		local cf, size = d.CFrame, d.Size
		local h = size / 2
		local r = cf.RightVector * h.X
		local u = cf.UpVector * h.Y
		local l = cf.LookVector * h.Z
		local ex = math.abs(r.X) + math.abs(u.X) + math.abs(l.X)
		local ez = math.abs(r.Z) + math.abs(u.Z) + math.abs(l.Z)
		local p = cf.Position
		table.insert(solids, { cf = cf, inv = cf:Inverse(), h = h, x0 = p.X - ex, x1 = p.X + ex, z0 = p.Z - ez, z1 = p.Z + ez, name = d.Name })
		if d.Name == "Boundary" and size.Y > 4 then
			minX = math.min(minX, p.X - ex); maxX = math.max(maxX, p.X + ex)
			minZ = math.min(minZ, p.Z - ez); maxZ = math.max(maxZ, p.Z + ez)
		end
	end
end
if minX == math.huge then
	minX, maxX, minZ, maxZ = -200, 200, -200, 200
end
local NX = math.floor((maxX - minX) / STEP)
local NZ = math.floor((maxZ - minZ) / STEP)
-- Cubos de piezas por columna de celdas (en X) para no recorrer todas
local buckets = {}
for _, s in solids do
	local i0 = math.max(0, math.floor((s.x0 - minX) / STEP))
	local i1 = math.min(NX - 1, math.ceil((s.x1 - minX) / STEP))
	for i = i0, i1 do
		buckets[i] = buckets[i] or {}
		table.insert(buckets[i], s)
	end
end

-- Intervalo vertical que ocupa una pieza en la línea (x, z)
local function interval(s, x, z)
	local inv = s.inv
	local o = inv * Vector3.new(x, 0, z)
	local d = inv:VectorToWorldSpace(Vector3.new(0, 1, 0))
	local t0, t1 = -math.huge, math.huge
	for _, axis in { "X", "Y", "Z" } do
		local oa, da, ha = o[axis], d[axis], s.h[axis]
		if math.abs(da) < 1e-6 then
			if math.abs(oa) > ha then
				return nil
			end
		else
			local a, b = (-ha - oa) / da, (ha - oa) / da
			if a > b then a, b = b, a end
			t0, t1 = math.max(t0, a), math.min(t1, b)
			if t0 > t1 then
				return nil
			end
		end
	end
	return t0, t1
end

-- Suelos de cada celda: { y, name }
local floors = {}
local function key(i, j) return i * 100000 + j end
for i = 0, NX - 1 do
	local list = buckets[i]
	if list then
		local x = minX + (i + 0.5) * STEP
		for j = 0, NZ - 1 do
			local z = minZ + (j + 0.5) * STEP
			local ivs = {}
			for _, s in list do
				if z >= s.z0 and z <= s.z1 then
					local a, b = interval(s, x, z)
					if a then
						table.insert(ivs, { a, b, s.name })
					end
				end
			end
			if #ivs > 0 then
				table.sort(ivs, function(p, q) return p[1] < q[1] end)
				-- unir solapes
				local merged = {}
				for _, iv in ivs do
					local last = merged[#merged]
					if last and iv[1] <= last[2] + 0.05 then
						if iv[2] > last[2] then last[2] = iv[2]; last[3] = iv[3] end
					else
						table.insert(merged, { iv[1], iv[2], iv[3] })
					end
				end
				local fl = {}
				for n, iv in merged do
					local nextBottom = merged[n + 1] and merged[n + 1][1] or math.huge
					if nextBottom - iv[2] >= CLEAR and iv[2] > -6 and iv[2] < 58 then
						table.insert(fl, { iv[2], iv[3] })
					end
				end
				if #fl > 0 then
					floors[key(i, j)] = fl
				end
			end
		end
	end
end

local function cellOf(p)
	return math.floor((p.X - minX) / STEP), math.floor((p.Z - minZ) / STEP)
end

-- Nodo = celda + índice de suelo
local function nodeKey(i, j, n) return key(i, j) * 8 + n end

local function bfs(starts, limitUp, reverse)
	local seen = {}
	local queue, head = {}, 1
	for _, s in starts do
		seen[s] = true
		table.insert(queue, s)
	end
	while head <= #queue do
		local nk = queue[head]; head += 1
		local n = nk % 8
		local ck = (nk - n) // 8
		local i, j = ck // 100000, ck % 100000
		local y = floors[ck][n][1]
		for _, dd in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local ni, nj = i + dd[1], j + dd[2]
			local fl = floors[key(ni, nj)]
			if fl then
				for m, f in fl do
					local dy = f[1] - y
					local ok
					if reverse then
						-- (camino inverso: de f a y tiene que poder hacerse)
						ok = (y - f[1]) <= limitUp
					else
						ok = dy <= limitUp
					end
					-- (no se atraviesan techos: al subir/bajar hace falta hueco; el suelo destino ya
					-- tiene 5 libres encima y el de origen también)
					if ok then
						local mk = nodeKey(ni, nj, m)
						if not seen[mk] then
							seen[mk] = true
							table.insert(queue, mk)
						end
					end
				end
			end
		end
	end
	return seen
end

local function nodeAt(p, tolerance)
	local i, j = cellOf(p)
	local best, bestD = nil, tolerance or 1.5
	for di = -1, 1 do
		for dj = -1, 1 do
			local fl = floors[key(i + di, j + dj)]
			if fl then
				for n, f in fl do
					local d = math.abs(f[1] - p.Y)
					if d < bestD then best, bestD = nodeKey(i + di, j + dj, n), d end
				end
			end
		end
	end
	return best
end

-- Salidas: SpawnLocations de cada equipo
local starts = {}
local points = {}
for _, d in map:GetDescendants() do
	if d:IsA("SpawnLocation") then
		local n = nodeAt(d.Position + Vector3.new(0, d.Size.Y / 2, 0), 1)
		if n then table.insert(starts, n) end
	elseif d:IsA("BasePart") and (d.Name == "FFASpawn" or d.Name == "BotSpot" or d.Name == "BombSite" or d.Name == "HardpointZone" or d.Name == "FlagBase") then
		table.insert(points, d)
	end
end
print(id, "celdas con suelo:", (function() local c = 0 for _ in floors do c += 1 end return c end)(), "salidas:", #starts)

local walkJump = bfs(starts, JUMP)
local super = bfs(starts, SUPER)
local back = bfs(starts, SUPER, true)

local bad = 0
for _, p in points do
	local base = (p.Name == "FlagBase" or p.Name == "HardpointZone") and p.Position or (p.Position - Vector3.new(0, p.Size.Y / 2, 0))
	local n = nodeAt(base, 1.6)
	if not n or not walkJump[n] then
		bad += 1
		print(string.format("  INALCANZABLE: %s en (%.1f, %.1f, %.1f)%s", p.Name, base.X, base.Y, base.Z, n and "" or " (sin suelo)"))
	end
end

-- Alturas permitidas (suelos de diseño); el resto alcanzable se lista por grupos
local allowed = { 0, 10, 20 }
if process.args[3] then
	allowed = {}
	for v in string.gmatch(process.args[3], "[^,]+") do table.insert(allowed, tonumber(v)) end
end
local function isAllowed(y)
	for _, a in allowed do
		if math.abs(y - a) <= 1.3 then return true end
	end
	return false
end
local function report(set, label, except)
	local groups = {}
	for nk in set do
		if except and except[nk] then
			continue
		end
		local n = nk % 8
		local ck = (nk - n) // 8
		local f = floors[ck][n]
		if not isAllowed(f[1]) and f[1] > 8.2 then
			local i, j = ck // 100000, ck % 100000
			local x, z = minX + (i + 0.5) * STEP, minZ + (j + 0.5) * STEP
			local g = string.format("%s@%d@%d@%d", f[2], math.floor(f[1] + 0.5), math.floor(x / 25), math.floor(z / 25))
			local e = groups[g]
			if not e then
				e = { n = 0, x = 0, z = 0, y = f[1], name = f[2] }
				groups[g] = e
			end
			e.n += 1; e.x += x; e.z += z
		end
	end
	local list = {}
	for _, e in groups do
		if e.n >= 8 then table.insert(list, e) end
	end
	table.sort(list, function(a, b) return a.y > b.y end)
	print(label .. ": " .. #list .. " grupos fuera de las alturas de diseño")
	for _, e in list do
		print(string.format("   %-16s y=%5.1f  %4d celdas  centro (%.0f, %.0f)", e.name, e.y, e.n, e.x / e.n, e.z / e.n))
	end
end
report(walkJump, "ANDANDO Y SALTANDO")
report(super, "CON SUPERSALTO (solo lo nuevo)", walkJump)

-- Tiempos de ruta (Dijkstra, 8 vecinos, andando y saltando): base → sitios y rotación
local function dijkstra(startNodes, goals)
	local dist = {}
	local heap = {}
	local function push(k, d)
		table.insert(heap, { k, d })
		local i = #heap
		while i > 1 do
			local parent = i // 2
			if heap[parent][2] <= heap[i][2] then break end
			heap[parent], heap[i] = heap[i], heap[parent]
			i = parent
		end
	end
	local function pop()
		local top = heap[1]
		local last = table.remove(heap)
		if #heap > 0 then
			heap[1] = last
			local i = 1
			while true do
				local l, r, m = i * 2, i * 2 + 1, i
				if l <= #heap and heap[l][2] < heap[m][2] then m = l end
				if r <= #heap and heap[r][2] < heap[m][2] then m = r end
				if m == i then break end
				heap[m], heap[i] = heap[i], heap[m]
				i = m
			end
		end
		return top
	end
	for _, s0 in startNodes do
		dist[s0] = 0
		push(s0, 0)
	end
	local remaining = {}
	for name, g in goals do remaining[g] = name end
	local found = {}
	while #heap > 0 do
		local item = pop()
		local nk, d = item[1], item[2]
		if d <= (dist[nk] or math.huge) then
			if remaining[nk] then
				found[remaining[nk]] = d
				remaining[nk] = nil
				if next(remaining) == nil then break end
			end
			local n = nk % 8
			local ck = (nk - n) // 8
			local i, j = ck // 100000, ck % 100000
			local y = floors[ck][n][1]
			for _, dd in { { 1, 0, 1 }, { -1, 0, 1 }, { 0, 1, 1 }, { 0, -1, 1 }, { 1, 1, 1.414 }, { 1, -1, 1.414 }, { -1, 1, 1.414 }, { -1, -1, 1.414 } } do
				local fl = floors[key(i + dd[1], j + dd[2])]
				if fl then
					for m, f in fl do
						local dy = f[1] - y
						if dy <= JUMP then
							local mk = nodeKey(i + dd[1], j + dd[2], m)
							local nd = d + dd[3] * STEP + (dy > WALK and 1.5 or 0)
							if nd < (dist[mk] or math.huge) then
								dist[mk] = nd
								push(mk, nd)
							end
						end
					end
				end
			end
		end
	end
	return found
end
local siteNodes, teamStarts = {}, { {}, {} }
for _, p in points do
	if p.Name == "BombSite" and not siteNodes[p:GetAttribute("Letter")] then
		siteNodes[p:GetAttribute("Letter")] = nodeAt(p.Position - Vector3.new(0, 0.5, 0), 1.6)
	end
end
for _, d in map:GetDescendants() do
	if d:IsA("SpawnLocation") then
		local team = d.TeamColor == GameConfig.Teams[1].Color and 1 or 2
		local n = nodeAt(d.Position + Vector3.new(0, d.Size.Y / 2, 0), 1)
		if n then table.insert(teamStarts[team], n) end
	end
end
local function secs(d) return string.format("%.0f studs (%.1f s corriendo, %.1f s andando)", d, d / 26, d / 18) end
for team = 1, 2 do
	local found = dijkstra(teamStarts[team], siteNodes)
	for letter, d in found do
		print(string.format("  equipo %d → sitio %s: %s", team, letter, secs(d)))
	end
end
if siteNodes.A and siteNodes.B then
	local rot = dijkstra({ siteNodes.A }, { B = siteNodes.B })
	if rot.B then print("  rotación A → B: " .. secs(rot.B)) end
end
local spawnToSpawn = dijkstra(teamStarts[1], { enemy = teamStarts[2][1] })
if spawnToSpawn.enemy then print("  base → base: " .. secs(spawnToSpawn.enemy)) end

-- Trampas: alcanzables pero sin vuelta
local traps = {}
for nk in super do
	if not back[nk] then
		local n = nk % 8
		local ck = (nk - n) // 8
		local f = floors[ck][n]
		local i, j = ck // 100000, ck % 100000
		local g = string.format("%s@%d", f[2], math.floor(f[1] + 0.5))
		local e = traps[g]
		if not e then e = { n = 0, x = minX + (i + 0.5) * STEP, z = minZ + (j + 0.5) * STEP, y = f[1] } traps[g] = e end
		e.n += 1
	end
end
local tcount = 0
for g, e in traps do
	if e.n >= 4 then
		tcount += 1
		print(string.format("  TRAMPA %s (%d celdas) cerca de (%.0f, %.0f, %.0f)", g, e.n, e.x, e.y, e.z))
	end
end
print(bad == 0 and tcount == 0 and "NAVEGACION OK" or ("FALLO: " .. bad .. " puntos inalcanzables, " .. tcount .. " trampas"))
process.exit((bad == 0 and tcount == 0) and 0 or 1)
