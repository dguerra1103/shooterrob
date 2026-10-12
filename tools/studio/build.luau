local MAP = "__MAP__"
local server = game:GetService("ServerScriptService").Server
local old = server:FindFirstChild("_AuditModules") if old then old:Destroy() end
local clone = server.Modules:Clone() clone.Name = "_AuditModules" clone.Parent = server
require(clone.MapDefs[MAP]).Build()
task.wait(3)
return "ok " .. MAP
