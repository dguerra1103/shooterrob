// Empuja a Studio (modo Edit) el Source de los .luau de src/ cambiados desde la última sincronización.
// Uso: node sync.js [--all-changed]  -> escribe sync.json (pasos para run.js)
const fs = require("fs"), path = require("path"), cp = require("child_process");
const repo = path.resolve(__dirname, "../..");
const stampFile = path.join(__dirname, ".sync.stamp");
const last = fs.existsSync(stampFile) ? Number(fs.readFileSync(stampFile, "utf8")) : 0;
// node sync.js [ruta ...]: las rutas dadas (desde la raíz del repo) se empujan siempre, hayan cambiado o no
const forced = process.argv.slice(2).map(f => f.split("\\").join("/"));
const out = cp.execSync("git status --porcelain -uall -- src", { cwd: repo, encoding: "utf8" });
const files = out.split("\n").map(l => l.slice(3).trim().replace(/^"|"$/g, "")).filter(f => f.endsWith(".luau")).concat(forced);
const roots = [["src/shared/", ["ReplicatedStorage", "Shared"]], ["src/first/", ["ReplicatedFirst"]], ["src/server/", ["ServerScriptService", "Server"]], ["src/client/", ["StarterPlayer", "StarterPlayerScripts", "Client"]]];
const steps = [{ tool: "start_stop_play", args: { is_start: false } }, { sleep: 2500 }];
let n = 0;
for (const f of files) {
  const full = path.join(repo, f);
  if (!fs.existsSync(full) || (!forced.includes(f) && fs.statSync(full).mtimeMs <= last)) continue;
  const r = roots.find(r => f.startsWith(r[0])); if (!r) continue;
  let parts = f.slice(r[0].length).split("/");
  let leaf = parts.pop().replace(/\.luau$/, "").replace(/\.(client|server)$/, "");
  const segs = r[1].concat(parts); if (leaf !== "init") segs.push(leaf);
  const src = fs.readFileSync(full, "utf8");
  let eq = "====="; while (src.includes("]" + eq + "]")) eq += "=";
  const nav = segs.slice(1).map(s => `:FindFirstChild(${JSON.stringify(s)})`).join("");
  const code = `local parent = game:GetService(${JSON.stringify(segs[0])})
for _, seg in ${"{" + segs.slice(1, -1).map(x => JSON.stringify(x)).join(",") + "}"} do local nxt = parent:FindFirstChild(seg); if not nxt then nxt = Instance.new("Folder"); nxt.Name = seg; nxt.Parent = parent end; parent = nxt end
local leaf = ${JSON.stringify(segs[segs.length - 1])}
local inst = ${segs.length > 1 ? "parent:FindFirstChild(leaf)" : "parent"}
if not inst then inst = Instance.new("ModuleScript"); inst.Name = leaf; inst.Parent = parent end
inst.Source = [${eq}[
${src}]${eq}]
return "ok ${segs.join(".")} " .. #inst.Source`;
  steps.push({ tool: "execute_luau", args: { code, datamodel_type: "Edit" }, max: 200 });
  n++;
}
fs.writeFileSync(path.join(__dirname, "sync.json"), JSON.stringify(steps));
fs.writeFileSync(stampFile, String(Date.now()));
console.log("archivos a sincronizar:", n);
