// Prueba en partida de cada mapa con el modo QA: node maptest.js [Mapa:MODO ...] && node run.js maptest.json
// (antes: node mk.js qa_on.json Edit qa_on.luau && node run.js qa_on.json). Capturas play_<Mapa>.png
const fs = require("fs");
const DEF = ["Construction:GUN", "Coastal:FFA", "Terminal:CTF", "MallRush:DOM", "RooftopDistrict:KOTH", "MetroYard:SND", "DesertBase:TDM", "Dockyard:INF", "IndustrialYard:ELIM"];
const list = process.argv.slice(2).length ? process.argv.slice(2) : DEF;
const server = fs.readFileSync(__dirname + "/maptest_server.luau", "utf8");
const steps = [{ tool: "start_stop_play", args: { is_start: true } }, { sleep: 16000 }];
list.forEach((item, i) => {
  const [map, mode] = item.split(":");
  steps.push({ tool: "execute_luau", args: { datamodel_type: "Client", code: `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "SIN REMOTO QA" end r:FireServer("NextMatch", { Map = "${map}", Mode = "${mode || "TDM"}", Now = false }) task.wait(0.5) r:FireServer("EndMatch", {}) return "pedido ${map} ${mode}"` }, max: 60 });
  if (i === 0) { steps.push({ sleep: 45000 }); steps.push({ clickText: "JUGAR" }); steps.push({ sleep: 40000 }); }
  else { steps.push({ sleep: 30000 }); steps.push({ tool: "screen_capture", args: { capture_id: "end_" + map }, img: "end_" + map + ".png" }); steps.push({ sleep: 30000 }); steps.push({ clickText: "JUGAR" }); steps.push({ sleep: 40000 }); }
  steps.push({ tool: "screen_capture", args: { capture_id: "play_" + map }, img: "play_" + map + ".png" });
  steps.push({ tool: "execute_luau", label: map, args: { datamodel_type: "Server", code: server }, max: 3000 });
});
steps.push({ tool: "get_console_output", args: {}, max: 6000, tail: true });
steps.push({ tool: "start_stop_play", args: { is_start: false } });
fs.writeFileSync(__dirname + "/maptest.json", JSON.stringify(steps));
console.log(list.length + " partidas");
