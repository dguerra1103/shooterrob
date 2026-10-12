// Prueba en partida de cada mapa con el modo QA: node maptest.js [Mapa:MODO ...] && node run.js maptest.json
// (antes: node mk.js qa_on.json Edit qa_on.luau && node run.js qa_on.json). Capturas play_<Mapa>.png
const fs = require("fs");
const DEF = ["Construction:GUN", "Coastal:FFA", "Terminal:CTF", "MallRush:DOM", "RooftopDistrict:KOTH", "MetroYard:SND", "DesertBase:TDM", "Dockyard:INF", "IndustrialYard:ELIM"];
const list = process.argv.slice(2).length ? process.argv.slice(2) : DEF;
const server = fs.readFileSync(__dirname + "/maptest_server.luau", "utf8");
const client = `local S = game:GetService("Stats") local out = {}
for _, k in { "SceneDrawcallCount", "SceneTriangleCount", "ShadowsDrawcallCount", "ShadowsTriangleCount", "UI2DDrawcallCount", "UI2DTriangleCount", "InstanceCount", "PrimitivesCount", "MovingPrimitivesCount" } do
  local ok, v = pcall(function() return S[k] end) if ok then out[#out + 1] = k .. "=" .. tostring(v) end
end
local ok, mem = pcall(function() return S:GetTotalMemoryUsageMb() end) if ok then out[#out + 1] = ("memoria=%.0f MB"):format(mem) end
local n, t = 0, 0 local c = game:GetService("RunService").RenderStepped:Connect(function(dt) n += 1 t += dt end) task.wait(3) c:Disconnect()
out[#out + 1] = ("fps(Studio)=%.0f"):format(n / math.max(t, 0.001))
local pg = game.Players.LocalPlayer.PlayerGui local hud = 0 for _, d in pg:GetDescendants() do if d:IsA("GuiObject") then hud += 1 end end
out[#out + 1] = "gui=" .. hud
return table.concat(out, " · ")`;
const steps = [{ tool: "start_stop_play", args: { is_start: true } }, { sleep: 16000 }];
list.forEach((item, i) => {
  const [map, mode] = item.split(":");
  steps.push({ tool: "execute_luau", args: { datamodel_type: "Client", code: `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "SIN REMOTO QA" end r:FireServer("NextMatch", { Map = "${map}", Mode = "${mode || "TDM"}", Now = false }) task.wait(0.5) r:FireServer("EndMatch", {}) return "pedido ${map} ${mode}"` }, max: 60 });
  if (i === 0) { steps.push({ sleep: 45000 }); steps.push({ clickText: "JUGAR" }); steps.push({ sleep: 40000 }); }
  else {
    // (pantalla final de la partida anterior: dos capturas)
    steps.push({ sleep: 6000 }); steps.push({ tool: "screen_capture", args: { capture_id: "end1_" + map }, img: "end1_" + map + ".png" });
    steps.push({ sleep: 9000 }); steps.push({ tool: "screen_capture", args: { capture_id: "end2_" + map }, img: "end2_" + map + ".png" });
    steps.push({ sleep: 45000 }); steps.push({ clickText: "JUGAR" }); steps.push({ sleep: 40000 });
  }
  steps.push({ tool: "screen_capture", args: { capture_id: "play_" + map }, img: "play_" + map + ".png" });
  steps.push({ tool: "execute_luau", label: map, args: { datamodel_type: "Server", code: server }, max: 3000 });
  steps.push({ tool: "execute_luau", label: map + " cliente", args: { datamodel_type: "Client", code: client }, max: 600 });
});
steps.push({ tool: "get_console_output", args: {}, max: 6000, tail: true });
steps.push({ tool: "start_stop_play", args: { is_start: false } });
fs.writeFileSync(__dirname + "/maptest.json", JSON.stringify(steps));
console.log(list.length + " partidas");
