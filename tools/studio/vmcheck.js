// Comprueba por dentro el arma en primera persona (sin depender de la imagen): node vmcheck.js Signal7
// y luego node run.js vmcheck.json. Escribe piezas por papel, puntos del Handle y tamaño del modelo.
const fs = require("fs");
const id = process.argv[2] || "ARX27";
const client = (code, max) => ({ tool: "execute_luau", args: { datamodel_type: "Client", code }, max: max || 900 });
const give = `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "sin remoto QA" end r:FireServer("Weapon", { Id = "${id}" }) return "arma ${id}"`;
const check = `local vm = workspace.CurrentCamera:FindFirstChild("Viewmodel")
if not vm then return "SIN VIEWMODEL" end
local roles, n, unions = {}, 0, 0
for _, d in vm:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
		if d:IsA("UnionOperation") then unions += 1 end
		local role = d:GetAttribute("Role")
		if role then roles[role] = (roles[role] or 0) + 1 end
	end
end
local list = {}
for role, c in roles do table.insert(list, role .. "=" .. c) end
table.sort(list)
local points = {}
for _, a in vm.PrimaryPart:GetChildren() do if a:IsA("Attachment") then table.insert(points, a.Name) end end
table.sort(points)
local _, size = vm:GetBoundingBox()
return string.format("arma %s · externo %s · piezas %d (uniones %d) · %s · puntos: %s · tamaño %.2f x %.2f x %.2f · ventana %s", tostring(vm:GetAttribute("Weapon")), tostring(vm:GetAttribute("External")), n, unions, table.concat(list, " "), table.concat(points, ","), size.X, size.Y, size.Z, tostring(workspace.CurrentCamera.ViewportSize))`;
fs.writeFileSync("vmcheck.json", JSON.stringify([
  { tool: "start_stop_play", args: { is_start: true } }, { sleep: 25000 }, { clickText: "JUGAR" }, { sleep: 64000 },
  client(give, 80), { sleep: 3000 }, client(check),
  { tool: "get_console_output", max: 700, tail: true }, { tool: "start_stop_play", args: { is_start: false } },
]));
console.log("ok");
