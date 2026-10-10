// Ejecuta una lista de pasos contra Roblox Studio por MCP, en una sola conexión.
//   node tools/studio/run.js pasos.json
// Cada paso: {tool, args, max, tail, img} (una herramienta del MCP de Studio; img = dónde guardar la
// captura), {sleep: ms} o {clickText: "JUGAR"} (busca un botón por su texto en el cliente y hace clic).
// Ver tools/studio/README.md.
const { spawn } = require("child_process");
const fs = require("fs");
// El lanzador que instala Roblox Studio (resuelve solo la versión actual de StudioMCP.exe)
const exe = process.env.LOCALAPPDATA + "/Roblox/mcp.bat";
const steps = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const child = spawn("cmd.exe", ["/c", exe], { stdio: ["pipe", "pipe", "pipe"] });
let buf = "", id = 1; const pending = new Map();
child.stderr.on("data", d => process.stderr.write("[stderr] " + d));
child.stdout.on("data", d => { buf += d; let i; while ((i = buf.indexOf("\n")) >= 0) { const l = buf.slice(0, i).trim(); buf = buf.slice(i + 1); if (!l) continue; try { const m = JSON.parse(l); if (pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } } catch {} } });
const send = (method, params, n) => { const m = { jsonrpc: "2.0", method, params }; if (n) { child.stdin.write(JSON.stringify(m) + "\n"); return; } m.id = id++; return new Promise(r => { pending.set(m.id, r); child.stdin.write(JSON.stringify(m) + "\n"); }); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const call = (name, args) => send("tools/call", { name, arguments: args });
(async () => {
  await send("initialize", { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "claude-manual", version: "0.1" } });
  send("notifications/initialized", {}, true);
  let sid;
  for (let k = 0; k < 15 && !sid; k++) {
    const r = await call("list_roblox_studios", {});
    const s = JSON.parse(r.result.content[0].text).studios;
    const want = process.env.SR_STUDIO; const pick = want ? s.find(x => x.name.includes(want)) : s[0]; if (pick) sid = pick.id; else await sleep(2000);
  }
  if (!sid) { console.log("SIN STUDIO"); child.kill(); process.exit(3); }
  for (const st of steps) {
    if (st.sleep) { await sleep(st.sleep); continue; }
    if (st.clickText) {
      // Busca en la interfaz del cliente un botón por su texto y hace clic en su centro
      const code = `local best
for _, d in game.Players.LocalPlayer.PlayerGui:GetDescendants() do
  if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text == ${JSON.stringify(st.clickText)} then
    local b = d:IsA("GuiButton") and d or d:FindFirstAncestorWhichIsA("GuiButton") or d
    local vis, n = true, b
    while n and n:IsA("GuiObject") do if not n.Visible then vis = false end n = n.Parent end
    if vis and b.AbsoluteSize.X > 0 then best = b break end
  end
end
if not best then return "NO" end
local p, s = best.AbsolutePosition, best.AbsoluteSize
return math.floor(p.X + s.X / 2) .. "," .. math.floor(p.Y + s.Y / 2)`;
      const r = await call("execute_luau", { studio_id: sid, code, datamodel_type: "Client" });
      const t = r.result ? r.result.content.map(c => c.text || "").join("") : "ERR";
      const m = t.match(/(\d+),(\d+)/);
      console.log("=== clickText " + st.clickText + " -> " + t.slice(0, 60));
      if (m) await call("user_mouse_input", { studio_id: sid, datamodel_type: "Client", actions: [{ action: "moveTo", x: Number(m[1]), y: Number(m[2]) }, { action: "mouseButtonClick", mouse_button: "left" }] });
      continue;
    }
    const r = await call(st.tool, Object.assign({ studio_id: sid }, st.args || {}));
    console.log("=== " + st.tool + (st.label ? " [" + st.label + "]" : ""));
    if (r.error) { console.log("ERROR " + JSON.stringify(r.error)); continue; }
    for (const c of r.result.content || []) {
      if (c.type === "text") { const max = st.max || 6000; console.log(c.text.length > max ? (st.tail ? "…" + c.text.slice(-max) : c.text.slice(0, max) + "…[" + c.text.length + " chars]") : c.text); }
      else if (c.type === "image") { const out = st.img || "shot.png"; fs.writeFileSync(out, Buffer.from(c.data, "base64")); console.log("[imagen: " + out + " " + c.mimeType + "]"); }
      else console.log(JSON.stringify(c).slice(0, 300));
    }
  }
  child.kill(); process.exit(0);
})();
