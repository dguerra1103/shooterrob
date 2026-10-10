// Prueba de un arma que arde (Weapons.<arma>.Blaze) en partida con el modo QA: node blazetest.js InfernoAR
// y luego node run.js blazetest.json. Deja bz_<Arma>_1.png (primera persona), _2 (apuntando) y _3 (el arma
// del mundo vista desde fuera, como la ven los demás), y escribe cuántas llamas hay en cada una.
const fs = require("fs");
const id = process.argv[2] || "InfernoAR";
const client = (code, max) => ({ tool: "execute_luau", args: { datamodel_type: "Client", code }, max: max || 300 });
const mouse = actions => ({ tool: "user_mouse_input", args: { datamodel_type: "Client", actions } });
const shot = n => ({ tool: "screen_capture", args: { capture_id: `BZ_${id}_${n}` }, img: `bz_${id}_${n}.png` });
const give = `local r for _, d in game:GetService("ReplicatedStorage"):GetDescendants() do if d.Name == "QACommand" and d:IsA("RemoteEvent") then r = d end end if not r then return "sin remoto QA" end r:FireServer("Bots", { Set = 1 }) r:FireServer("Weapon", { Id = "${id}" }) r:FireServer("Ammo") return "arma ${id}"`;
const count = `local function n(root) local c, on = 0, 0 for _, d in root and root:GetDescendants() or {} do if d:IsA("ParticleEmitter") and (d.Name == "FXBlaze" or d.Name == "FXEmbers") then c += 1 if d.Enabled and d.Rate > 0 then on += 1 end end end return c .. " (" .. on .. " encendidas)" end
local cam = workspace.CurrentCamera
return "viewmodel: " .. n(cam:FindFirstChild("Viewmodel")) .. " · arma del mundo: " .. n(game.Players.LocalPlayer.Character)`;
const outside = `local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local vm = cam:FindFirstChild("Viewmodel") if vm then vm.Parent = nil end
game:GetService("RunService"):BindToRenderStep("BZ", 2000, function()
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, d in char:GetDescendants() do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end
	-- (Studio devuelve la cámara a Custom al acabar el execute_luau: se vuelve a poner cada fotograma)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt((root.CFrame * CFrame.new(4.2, 1.6, -1.6)).Position, (root.CFrame * CFrame.new(0.5, 0.6, -1.4)).Position)
	cam.Focus = root.CFrame
end)
return "camara fuera"`;
const steps = [
  { tool: "start_stop_play", args: { is_start: true } }, { sleep: 25000 }, { clickText: "JUGAR" }, { sleep: 64000 },
  client(give, 80), { sleep: 4500 }, client(count), shot(1),
  mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonDown", mouse_button: "right" }, { action: "wait", wait_time_ms: 1200 }]),
  shot(2),
  mouse([{ action: "moveTo", x: 600, y: 300 }, { action: "mouseButtonUp", mouse_button: "right" }, { action: "wait", wait_time_ms: 400 }]),
  client(outside), { sleep: 1500 }, client(count), shot(3),
  { tool: "get_console_output", max: 1500, tail: true }, { tool: "start_stop_play", args: { is_start: false } },
];
fs.writeFileSync("blazetest.json", JSON.stringify(steps));
console.log("pasos:", steps.length);
