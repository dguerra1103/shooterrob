-- Medir en modo Edit dónde queda la superficie del terreno según cómo se rellena (lejos del origen)
local T = workspace.Terrain
local out = {}
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { T }
local function measure(label, cf, size, x)
	T:FillBlock(cf + Vector3.new(x, 0, 5000), size, Enum.Material.Sand)
	task.wait(1.5)
	local r = workspace:Raycast(Vector3.new(x, 60, 5000), Vector3.new(0, -200, 0), params)
	table.insert(out, ("%s -> superficie y=%s"):format(label, r and ("%.2f"):format(r.Position.Y) or "nada"))
end
measure("bloque 6 de alto, tope en 0 (como DesertBase antes)", CFrame.new(0, -3, 0), Vector3.new(200, 6, 200), 0)
measure("bloque 6 de alto, tope en -0.3", CFrame.new(0, -3.3, 0), Vector3.new(200, 6, 200), 400)
measure("bloque 6 de alto, tope en -2", CFrame.new(0, -5, 0), Vector3.new(200, 6, 200), 800)
measure("bloque 8 de alto, tope en 0", CFrame.new(0, -4, 0), Vector3.new(200, 8, 200), 1200)
measure("bloque 4 de alto, tope en 0", CFrame.new(0, -2, 0), Vector3.new(200, 4, 200), 1600)
T:FillBlock(CFrame.new(800, 0, 5000), Vector3.new(2200, 40, 400), Enum.Material.Air)
return table.concat(out, "\n")
