// Prueba de efectos de las armas (WeaponFX) con el modo QA: captura disparando y en mitad de la recarga.
//   node fxtest.js ARX27 TitanLMG ... && node run.js fxtest.json
const fs = require("fs");
const ids = process.argv.slice(2);
const give = id => ({ tool: "execute_luau", args: { datamodel_type: "Client", code: `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "sin remoto QA" end r:FireServer("Weapon", { Id = "${id}" }) r:FireServer("Ammo") return "arma ${id}"` }, max: 80 });
const mouse = actions => ({ tool: "user_mouse_input", args: { datamodel_type: "Client", actions } });
const steps = [{ tool: "start_stop_play", args: { is_start: true } }, { sleep: 25000 }, { clickText: "JUGAR" }, { sleep: 46000 }];
for (const id of ids) {
  steps.push(give(id), { sleep: 2200 },
    { tool: "screen_capture", args: { capture_id: "FX_" + id + "_0" }, img: `fx_${id}_0.png` },
    mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonDown", mouse_button: "left" }, { action: "wait", wait_time_ms: 60 }]),
    { tool: "screen_capture", args: { capture_id: "FX_" + id + "_1" }, img: `fx_${id}_1.png` },
    { tool: "screen_capture", args: { capture_id: "FX_" + id + "_2" }, img: `fx_${id}_2.png` },
    mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonUp", mouse_button: "left" }, { action: "wait", wait_time_ms: 300 }]),
    { tool: "user_keyboard_input", args: { datamodel_type: "Client", actions: [{ action: "keyPress", key_code: "R" }, { action: "wait", wait_time_ms: 800 }] } },
    { tool: "screen_capture", args: { capture_id: "FX_" + id + "_3" }, img: `fx_${id}_3.png` },
    { sleep: 2600 });
}
steps.push({ tool: "get_console_output", max: 2500, tail: true }, { tool: "start_stop_play", args: { is_start: false } });
fs.writeFileSync("fxtest.json", JSON.stringify(steps));
console.log("pasos:", steps.length);
