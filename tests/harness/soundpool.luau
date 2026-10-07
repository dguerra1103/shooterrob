-- Pool de sonidos 2D: los disparos y golpes reutilizan sus Sound (como mucho 5 por nombre)
local process = require("@lune/process")
local mock = require("./mock")
mock.taskImpl = require("@lune/task")
local game, req = mock.buildGame(process.args[1])
local function check(c, m) if not c then print("FALLO: " .. m) process.exit(1) end print("ok  " .. m) end
local Sounds = req(game.ReplicatedStorage.Shared.Sounds)
local cam = game.Workspace.CurrentCamera
local function count(id)
	local n = 0
	for _, c in cam:GetChildren() do
		if c.__className == "Sound" and c.SoundId == id then n += 1 end
	end
	return n
end
local seen = {}
for i = 1, 30 do
	local s = Sounds.PlayGun("Shot", nil, 1, 1)
	seen[s] = true
	s.IsPlaying = false -- (como si ya hubiera acabado)
end
local distinct = 0
for _ in seen do distinct += 1 end
check(distinct <= 6, "30 disparos usan como mucho 6 sonidos (" .. distinct .. ")")
check(count(Sounds.Shot.Id) <= 6, "y no se quedan instancias sueltas")
-- Si todos están sonando, no se corta ninguno: el nuevo va aparte
local busy = {}
for i = 1, 8 do busy[i] = Sounds.PlayGun("Mech", nil, 1, 1); busy[i].IsPlaying = true end
local extra = Sounds.PlayGun("Mech", nil, 1, 1)
local stolen = false
for i = 1, 8 do if busy[i] == extra then stolen = true end end
check(not stolen, "con todos sonando no se corta ninguno")
-- Un efecto puesto por un uso (la cola filtrada) no pasa al siguiente
local boom = Sounds.Play("Boom", nil, 1, 1)
local eq = Instance and nil
local fx = mock.new("EqualizerSoundEffect"); fx.Parent = boom
boom.IsPlaying = false
for i = 1, 6 do local b = Sounds.Play("Boom", nil, 1, 1); b.IsPlaying = false end
local leftovers = 0
for _, c in boom:GetChildren() do if c.__className == "EqualizerSoundEffect" then leftovers += 1 end end
check(leftovers == 0, "al reutilizarse se le quitan los efectos de antes")
-- Si alguien destruye uno, el pool lo olvida
boom:Destroy()
local again = Sounds.Play("Boom", nil, 1, 1)
check(again ~= boom and again.Parent ~= nil, "uno destruido se sustituye")
-- Los de otro tipo (pitido) no se reutilizan
local a, b = Sounds.Play("Tinnitus", nil, 1, 1), Sounds.Play("Tinnitus", nil, 1, 1)
check(a ~= b, "los raros siguen siendo nuevos cada vez")
print("POOL OK")
process.exit(0)
