// node mk.js out.json Client|Server|Edit file.luau  -> un paso execute_luau
const fs=require("fs");const [o,dm,f]=process.argv.slice(2);
fs.writeFileSync(o,JSON.stringify([{tool:"execute_luau",args:{code:fs.readFileSync(f,"utf8"),datamodel_type:dm},max:9000}]));
