// node probe.js Mapa "x,y,z" "x,y,z" ... -> probe.json
const fs = require("fs");
const [map, ...pts] = process.argv.slice(2);
const b = fs.readFileSync(__dirname + "/build.luau", "utf8").replace("__MAP__", map);
const p = fs.readFileSync(__dirname + "/probe.luau", "utf8").replace("__PTS__", pts.map(s => "{" + s + "}").join(", "));
fs.writeFileSync(__dirname + "/probe.json", JSON.stringify([{ tool: "execute_luau", args: { datamodel_type: "Edit", code: b }, max: 200 }, { tool: "execute_luau", args: { datamodel_type: "Edit", code: p }, max: 8000 }]));
