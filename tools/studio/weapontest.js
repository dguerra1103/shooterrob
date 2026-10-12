// Genera los pasos para probar armas en partida con el modo QA: node weapontest.js HavocPump Signal7 ...
// (antes: node mk.js qa_on.json Edit qa_on.luau && node run.js qa_on.json)
const fs = require("fs");
const ids = process.argv.slice(2);
const give = id => ({ tool: "execute_luau", args: { datamodel_type: "Client", code: `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "sin remoto QA" end r:FireServer("Weapon", { Id = "${id}" }) r:FireServer("Ammo") return "arma ${id}"` }, max: 80 });
const mouse = actions => ({ tool: "user_mouse_input", args: { datamodel_type: "Client", actions } });
const steps = [{ tool: "start_stop_play", args: { is_start: true } }, { sleep: 25000 }, { clickText: "JUGAR" }, { sleep: 46000 }];
for (const id of ids) {
  steps.push(give(id), { sleep: 2200 },
    { tool: "screen_capture", args: { capture_id: "SC_" + id + "_1" }, img: `wt_${id}_1.png` },
    mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonClick", mouse_button: "left" }, { action: "wait", wait_time_ms: 220 }]),
    { tool: "screen_capture", args: { capture_id: "SC_" + id + "_2" }, img: `wt_${id}_2.png` },
    { sleep: 900 },
    mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonDown", mouse_button: "right" }, { action: "wait", wait_time_ms: 900 }]),
    { tool: "screen_capture", args: { capture_id: "SC_" + id + "_3" }, img: `wt_${id}_3.png` },
    mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonUp", mouse_button: "right" }, { action: "wait", wait_time_ms: 400 }]),
    { tool: "user_keyboard_input", args: { datamodel_type: "Client", actions: [{ action: "keyPress", key_code: "R" }, { action: "wait", wait_time_ms: 700 }] } },
    { tool: "screen_capture", args: { capture_id: "SC_" + id + "_4" }, img: `wt_${id}_4.png` },
    { sleep: 2500 });
}
steps.push({ tool: "get_console_output", max: 2500, tail: true }, { tool: "start_stop_play", args: { is_start: false } });
fs.writeFileSync("weapontest.json", JSON.stringify(steps));
console.log("pasos:", steps.length);
