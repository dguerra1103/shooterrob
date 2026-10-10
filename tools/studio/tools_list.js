// Lista las herramientas del MCP de Studio (nombre y descripción corta)
const { spawn } = require("child_process");
const child = spawn("cmd.exe", ["/c", process.env.LOCALAPPDATA + "/Roblox/mcp.bat"], { stdio: ["pipe", "pipe", "pipe"] });
let buf = "", id = 1; const pending = new Map();
child.stdout.on("data", d => { buf += d; let i; while ((i = buf.indexOf("\n")) >= 0) { const l = buf.slice(0, i).trim(); buf = buf.slice(i + 1); if (!l) continue; try { const m = JSON.parse(l); if (pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } } catch {} } });
const send = (method, params, n) => { const m = { jsonrpc: "2.0", method, params }; if (n) { child.stdin.write(JSON.stringify(m) + "\n"); return; } m.id = id++; return new Promise(r => { pending.set(m.id, r); child.stdin.write(JSON.stringify(m) + "\n"); }); };
(async () => {
  await send("initialize", { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "claude-manual", version: "0.1" } });
  send("notifications/initialized", {}, true);
  const r = await send("tools/list", {});
  for (const t of r.result.tools) console.log(t.name + " :: " + (t.description || "").replace(/\s+/g, " ").slice(0, process.argv[2] === t.name ? 3000 : 150) + (process.argv[2] === t.name ? "\n" + JSON.stringify(t.inputSchema) : ""));
  child.kill(); process.exit(0);
})();
