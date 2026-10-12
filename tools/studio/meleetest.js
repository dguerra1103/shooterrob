// Prueba de armas cuerpo a cuerpo con el modo QA: node meleetest.js Katana ToyHammer Scythe && node run.js meleetest.json
const fs = require("fs");
const ids = process.argv.slice(2);
const give = id => ({ tool: "execute_luau", args: { datamodel_type: "Client", code: `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "sin remoto QA" end r:FireServer("Weapon", { Id = "${id}" }) return "arma ${id}"` }, max: 80 });
const steps = [{ tool: "start_stop_play", args: { is_start: true } }, { sleep: 25000 }, { clickText: "JUGAR" }, { sleep: 46000 }];
for (const id of ids) {
  steps.push(give(id), { sleep: 1800 },
    { tool: "user_keyboard_input", args: { datamodel_type: "Client", actions: [{ action: "keyPress", key_code: "Three" }] } }, { sleep: 1600 },
    { tool: "screen_capture", args: { capture_id: "ML_" + id + "_1" }, img: `ml_${id}_1.png` },
    { tool: "user_mouse_input", args: { datamodel_type: "Client", actions: [{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonClick", mouse_button: "left" }, { action: "wait", wait_time_ms: 140 }] } },
    { tool: "screen_capture", args: { capture_id: "ML_" + id + "_2" }, img: `ml_${id}_2.png` }, { sleep: 1200 });
}
steps.push({ tool: "get_console_output", max: 2500, tail: true }, { tool: "start_stop_play", args: { is_start: false } });
fs.writeFileSync("meleetest.json", JSON.stringify(steps));
