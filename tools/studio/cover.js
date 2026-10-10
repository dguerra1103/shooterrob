// Zonas sin cobertura de cada mapa (modo Edit): node cover.js [Mapa ...] && node run.js cover.json
const fs = require("fs");
const B = { Construction: [300, 60, 260], Coastal: [300, 60, 260], Terminal: [300, 60, 260], MallRush: [300, 40, 180], RooftopDistrict: [300, 70, 200], MetroYard: [300, 70, 220], DesertBase: [300, 70, 240], Dockyard: [300, 70, 244], IndustrialYard: [300, 70, 240] };
const list = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(B);
const src = fs.readFileSync(__dirname + "/cover.luau", "utf8");
const steps = [];
for (const m of list) {
  steps.push({ tool: "execute_luau", args: { datamodel_type: "Edit", code: `local server = game:GetService("ServerScriptService").Server local old = server:FindFirstChild("_AuditModules") if old then old:Destroy() end local clone = server.Modules:Clone() clone.Name = "_AuditModules" clone.Parent = server require(clone.MapKit).pickLighting = function(m) return m.Lighting end require(clone.MapBuilder).Build("${m}") return "ok"` }, max: 60 });
  steps.push({ tool: "execute_luau", label: m, args: { datamodel_type: "Edit", code: src.replace("__BOUNDS__", `Vector3.new(${B[m].join(",")})`).replace("__MAXY__", m === "RooftopDistrict" ? "8" : "1.2") }, max: 3000 });
}
fs.writeFileSync(__dirname + "/cover.json", JSON.stringify(steps));
