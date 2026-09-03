-- Headless unit-test runner (Lune) for pure-logic cases.
-- Runs the same Cases as the in-Studio RunUnitTest; skips cases that need live
-- services (ServerScriptService / StarterPlayer / non-ReplicatedStorage GetService).
-- Usage, from repo root: lune run tests/run_tests.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local CASES_DIR = "src/tests/unit/Cases"
local EXPECT_PATH = "../src/tests/unit/Expect.luau"
local SHARED_DIR = "src/shared"

-- Lune has no `warn`; route failures through print.
local warn = print

local Vector3Shim
local vector3Mt = {
	__add = function(a, b)
		return Vector3Shim.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
	end,
	__sub = function(a, b)
		return Vector3Shim.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
	end,
	__mul = function(a, b)
		if type(a) == "number" then
			a, b = b, a
		end
		return Vector3Shim.new(a.X * b, a.Y * b, a.Z * b)
	end,
	__index = function(v, key)
		if key == "Magnitude" then
			return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		end
		return nil
	end,
}
Vector3Shim = {
	new = function(x, y, z)
		return setmetatable({ X = x, Y = y, Z = z }, vector3Mt)
	end,
}
local CFrameShim = {
	new = function(position)
		return { Position = position }
	end,
	lookAt = function(position)
		return { Position = position }
	end,
}
local colors = {}
local Color3Shim = {
	fromRGB = function(r, g, b)
		local key = string.format("%d,%d,%d", r, g, b)
		colors[key] = colors[key] or { R = r / 255, G = g / 255, B = b / 255 }
		return colors[key]
	end,
}
local randomSeedCounter = 0
local RandomShim = {
	new = function(seed)
		if seed == nil then
			randomSeedCounter += 1
		end
		local seedValue = seed or randomSeedCounter
		local state = (seedValue * 1103515245 + 12345) % 2147483647
		return {
			NextNumber = function(_, min, max)
				state = (state * 48271) % 2147483647
				local value = state / 2147483647
				return min and min + (max - min) * value or value
			end,
			NextInteger = function(self, min, max)
				return math.floor(self:NextNumber(min, max + 1))
			end,
		}
	end,
}
local guid = 0
local httpService = {
	GenerateGUID = function()
		guid += 1
		return string.format("headless-%d", guid)
	end,
}

----- game shim: only ReplicatedStorage.Shared is mapped onto the filesystem -----
local function dirNode(dirPath, parent)
	local node = { Name = dirPath:match("[^/]+$"), Parent = parent }
	for _, entry in fs.readDir(dirPath) do
		local childPath = dirPath .. "/" .. entry
		if fs.isDir(childPath) then
			node[entry] = dirNode(childPath, node)
		elseif fs.isFile(childPath) then
			local name = entry:gsub("%.luau$", "")
			node[name] = { __filePath = childPath, Name = name, Parent = node }
		end
	end
	return node
end

local replicatedStorage = { Shared = dirNode(SHARED_DIR) }

local gameStub = setmetatable({}, {
	__index = function(_, key)
		if key == "GetService" then
			return function(_, serviceName)
				if serviceName == "ReplicatedStorage" then
					return replicatedStorage
				end
				if serviceName == "HttpService" then
					return httpService
				end
				error(string.format("headless shim: GetService(%q) is not available", serviceName), 2)
			end
		end
		if key == "ReplicatedStorage" then
			return replicatedStorage
		end
		return nil
	end,
})

local moduleCache = {}
local function stubRequire(target)
	local path = type(target) == "table" and target.__filePath or target
	if type(path) ~= "string" then
		error("headless require: unsupported require target", 2)
	end
	path = path:gsub("^%.%./", "")
	path = path:gsub("%.luau$", "")
	if moduleCache[path] ~= nil then
		return moduleCache[path]
	end
	local source = fs.readFile(path .. ".luau")
	local moduleNode = target
	-- selene: allow(global_usage)
	local env = setmetatable({
		game = gameStub,
		require = stubRequire,
		script = moduleNode,
		warn = print,
		Vector3 = Vector3Shim,
		CFrame = CFrameShim,
		Color3 = Color3Shim,
		Random = RandomShim,
	}, { __index = _G })
	local chunk, loadError = luau.load(source, { environment = env, chunkname = path })
	if type(chunk) ~= "function" then
		error(loadError, 2)
	end
	local result = chunk()
	moduleCache[path] = result
	return result
end

local function needsLiveServices(source)
	if source:find("ServerScriptService", 1, true) or source:find("StarterPlayer", 1, true) then
		return true
	end
	for serviceName in source:gmatch('GetService%("([^"]+)"%)') do
		if serviceName ~= "ReplicatedStorage" then
			return true
		end
	end
	return false
end

----- Main -----
local totals = { run = 0, passed = 0, failed = 0, skipped = 0 }
local sessionStart = os.clock()

for _, entry in fs.readDir(CASES_DIR) do
	if not fs.isDir(CASES_DIR .. "/" .. entry) and entry:match("%.luau$") then
		local source = fs.readFile(CASES_DIR .. "/" .. entry)
		if needsLiveServices(source) then
			totals.skipped += 1
			print(string.format("[SKIP] %s | needs live services", entry))
		else
			local envBase = {
				game = gameStub,
				require = stubRequire,
				warn = print,
				Vector3 = Vector3Shim,
				CFrame = CFrameShim,
				Color3 = Color3Shim,
				Random = RandomShim,
			}
			-- selene: allow(global_usage)
			local env = setmetatable(envBase, { __index = _G })
			local okLoad, chunk = pcall(luau.load, source, { environment = env, chunkname = entry })
			if not okLoad or type(chunk) ~= "function" then
				totals.run += 1
				totals.failed += 1
				warn(string.format("[FAIL] %s | could not load case: %s", entry, tostring(chunk)))
			else
				local t = { expect = stubRequire(EXPECT_PATH) }
				function t.test(name, fn)
					totals.run += 1
					local okCase, err = pcall(fn)
					if okCase then
						totals.passed += 1
						print(string.format("[PASS] %s > %s", entry, name))
					else
						totals.failed += 1
						warn(string.format("[FAIL] %s > %s | %s", entry, name, tostring(err)))
					end
				end
				local okFactory, caseFn = pcall(chunk)
				local okRun, runErr
				if not okFactory or type(caseFn) ~= "function" then
					okRun, runErr = false, caseFn
				else
					okRun, runErr = pcall(caseFn, t)
				end
				if not okRun then
					totals.run += 1
					totals.failed += 1
					warn(string.format("[FAIL] %s | error while building cases: %s", entry, tostring(runErr)))
				end
			end
		end
	end
end

print(
	string.format(
		"[SUMMARY] %d run, %d passed, %d failed, %d skipped, %.3fs",
		totals.run,
		totals.passed,
		totals.failed,
		totals.skipped,
		os.clock() - sessionStart
	)
)

if totals.failed > 0 then
	process.exit(1)
end
