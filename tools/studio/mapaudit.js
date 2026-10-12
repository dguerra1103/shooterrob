// Auditoría de mapas en modo Edit: node mapaudit.js [Mapa ...] [--tag antes] && node run.js mapaudit.json
// Deja el informe en la salida y capturas map_<tag>_<Mapa>_<n>.png (vista aérea, base roja, centro).
const fs = require("fs");
const ALL = ["Construction", "Coastal", "Terminal", "MallRush", "RooftopDistrict", "MetroYard", "DesertBase", "Dockyard", "IndustrialYard"];
const args = process.argv.slice(2);
let tag = "a";
const i = args.indexOf("--tag");
if (i >= 0) { tag = args[i + 1]; args.splice(i, 2); }
// --nocheck: construye sin el repaso de MapCheck (para medir cómo estaba)
const k = args.indexOf("--nocheck"); const check = k < 0; if (k >= 0) args.splice(k, 1);
const maps = args.length ? args : ALL;
const src = fs.readFileSync(__dirname + "/mapaudit.luau", "utf8");
const cam = (code) => ({ tool: "execute_luau", args: { datamodel_type: "Edit", code }, max: 80 });
const steps = [];
for (const m of maps) {
  steps.push({ tool: "execute_luau", label: m, args: { datamodel_type: "Edit", code: src.replace("__MAP__", m).replace("__CHECK__", String(check)) }, max: 9000 });
  const views = [
    // aérea, base roja mirando al centro, centro mirando a un lado, esquina
    `local c = workspace.CurrentCamera c.CameraType = Enum.CameraType.Scriptable c.FieldOfView = 70 c.CFrame = CFrame.lookAt(Vector3.new(0, 210, 170), Vector3.new(0, 0, 10)) return "cam"`,
    `local c = workspace.CurrentCamera local s for _, d in workspace.Map:GetDescendants() do if d:IsA("SpawnLocation") and d.Position.X < 0 then s = d break end end local p = s and s.Position or Vector3.new(-120, 0, 0) c.CFrame = CFrame.lookAt(p + Vector3.new(-6, 7, 0), Vector3.new(0, 4, 0)) return "cam"`,
    `local c = workspace.CurrentCamera c.CFrame = CFrame.lookAt(Vector3.new(-30, 9, 34), Vector3.new(20, 3, -30)) return "cam"`,
    `local c = workspace.CurrentCamera c.CFrame = CFrame.lookAt(Vector3.new(60, 26, -70), Vector3.new(0, 2, 10)) return "cam"`,
  ];
  views.forEach((v, n) => {
    steps.push(cam(v));
    steps.push({ sleep: 900 });
    steps.push({ tool: "screen_capture", args: { capture_id: `m_${m}_${n}` }, img: `map_${tag}_${m}_${n + 1}.png` });
  });
}
fs.writeFileSync(__dirname + "/mapaudit.json", JSON.stringify(steps));
console.log(maps.length + " mapas, " + steps.length + " pasos");
