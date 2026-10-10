// Capturas de los mapas en modo Edit, a la altura de los ojos, siempre desde los mismos sitios (para
// comparar antes y después de un cambio visual).
//   node mapshots.js <tag> [Mapa[:Variante] ...]      p. ej. node mapshots.js v0 Dockyard Coastal:Noche
// Por mapa: vista aérea y cuatro vistas desde puntos de aparición libres mirando al centro.
// Salida: shot_<tag>_<Mapa>[_Variante]_<n>.png y la hoja sheet_<tag>_<Mapa>[_Variante].jpg
const { spawn, execSync } = require("child_process");
const fs = require("fs");
const ALL = ["Construction", "Coastal", "Terminal", "MallRush", "RooftopDistrict", "MetroYard", "DesertBase", "Dockyard", "IndustrialYard"];
const [tag, ...rest] = process.argv.slice(2);
const list = rest.length ? rest : ALL;
const child = spawn("cmd.exe", ["/c", process.env.LOCALAPPDATA + "/Roblox/mcp.bat"], { stdio: ["pipe", "pipe", "pipe"] });
let buf = "", id = 1; const pending = new Map();
child.stdout.on("data", d => { buf += d; let i; while ((i = buf.indexOf("\n")) >= 0) { const l = buf.slice(0, i).trim(); buf = buf.slice(i + 1); if (!l) continue; try { const m = JSON.parse(l); if (pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } } catch {} } });
const send = (method, params, n) => { const m = { jsonrpc: "2.0", method, params }; if (n) { child.stdin.write(JSON.stringify(m) + "\n"); return; } m.id = id++; return new Promise(r => { pending.set(m.id, r); child.stdin.write(JSON.stringify(m) + "\n"); }); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const build = (map, variant) => `
local server = game:GetService("ServerScriptService").Server
local old = server:FindFirstChild("_AuditModules") if old then old:Destroy() end
local clone = server.Modules:Clone() clone.Name = "_AuditModules" clone.Parent = server
pcall(function() settings().Studio["Show Navigation Mesh"] = false end)
local Kit = require(clone.MapKit)
local wanted = ${JSON.stringify(variant || "")}
-- (variante fija: la de día, o la que se pida, para que las capturas sean comparables)
Kit.pickLighting = function(map)
	Kit.Variant, Kit.Weather = nil, nil
	for _, v in map.LightingVariants or {} do
		if v.Name == wanted then
			local preset = table.clone(map.Lighting)
			for k, value in v do if k ~= "Name" and k ~= "Chance" and k ~= "Weather" then preset[k] = value end end
			Kit.Variant, Kit.Weather = v.Name, v.Weather
			return preset
		end
	end
	return map.Lighting
end
local MapBuilder = require(clone.MapBuilder)
MapBuilder.Build(${JSON.stringify(map)})
local names = {}
for _, v in MapBuilder.Defs[${JSON.stringify(map)}].LightingVariants or {} do table.insert(names, v.Name) end
-- Puntos de vista: apariciones libres del lado rojo, repartidas
local pts = {}
for _, d in workspace.Map:GetDescendants() do
	if d:IsA("BasePart") and d.Name == "FFASpawn" and d.Position.X < -4 then table.insert(pts, d.Position) end
end
table.sort(pts, function(a, b) if a.Z ~= b.Z then return a.Z < b.Z end return a.X < b.X end)
local pick = {}
for i = 1, 4 do
	local p = pts[math.max(1, math.floor((i - 0.5) / 4 * #pts + 0.5))]
	if p then table.insert(pick, string.format("%.1f,%.1f,%.1f", p.X, p.Y, p.Z)) end
end
return "VARIANTES=" .. table.concat(names, "|") .. ";PUNTOS=" .. table.concat(pick, ";")`;
(async () => {
  await send("initialize", { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "claude-manual", version: "0.1" } });
  send("notifications/initialized", {}, true);
  let sid;
  for (let k = 0; k < 15 && !sid; k++) { const r = await send("tools/call", { name: "list_roblox_studios", arguments: {} }); const s = JSON.parse(r.result.content[0].text).studios; const want = process.env.SR_STUDIO; const pick = want ? s.find(x => x.name.includes(want)) : s[0]; if (pick) sid = pick.id; else await sleep(2000); }
  if (!sid) { console.log("SIN STUDIO"); process.exit(3); }
  const call = (name, args) => send("tools/call", { name, arguments: Object.assign({ studio_id: sid }, args) });
  for (const item of list) {
    const [map, variant] = item.split(":");
    const name = map + (variant ? "_" + variant : "");
    const r = await call("execute_luau", { datamodel_type: "Edit", code: build(map, variant) });
    const text = (r.result ? r.result.content.map(c => c.text || "").join("") : JSON.stringify(r.error)) || "";
    const m = text.match(/VARIANTES=(.*);PUNTOS=(.*)/);
    if (!m) { console.log(name + ": " + text.slice(0, 300)); continue; }
    console.log(name + " · variantes: " + (m[1] || "ninguna"));
    await sleep(1500);
    const views = [{ cam: [0, 130, 150], at: [0, 0, 5] }];
    for (const p of m[2].split(";").filter(Boolean)) { const [x, y, z] = p.split(",").map(Number); views.push({ cam: [x, y + 4.5, z], at: [x * 0.25, y + 3, z * 0.25] }); }
    const files = [];
    for (let i = 0; i < views.length; i++) {
      const c = await call("screen_capture", { capture_id: `s_${name}_${i}`, camera_position: views[i].cam, look_at_position: views[i].at });
      const img = c.result && (c.result.content || []).find(x => x.type === "image");
      if (img) { const f = `${__dirname}/shot_${tag}_${name}_${i + 1}.png`; fs.writeFileSync(f, Buffer.from(img.data, "base64")); files.push(f); }
    }
    // Hoja: la aérea pequeña no hace falta; las cuatro a pie en 2x2
    const py = `
from PIL import Image
import sys
fs = sys.argv[2:]
ims = [Image.open(f).convert("RGB") for f in fs[1:5]] or [Image.open(fs[0]).convert("RGB")]
w, h = ims[0].size
sheet = Image.new("RGB", (w * 2, h * 2))
for i, im in enumerate(ims):
    sheet.paste(im, ((i % 2) * w, (i // 2) * h))
sheet.thumbnail((1700, 1000))
sheet.save(sys.argv[1], quality=86)`;
    fs.writeFileSync(__dirname + "/_sheet.py", py);
    try { execSync(`python "${__dirname}/_sheet.py" "${__dirname}/sheet_${tag}_${name}.jpg" ${files.map(f => `"${f}"`).join(" ")}`); } catch (e) { console.log("hoja: " + e.message.slice(0, 200)); }
  }
  child.kill(); process.exit(0);
})();
