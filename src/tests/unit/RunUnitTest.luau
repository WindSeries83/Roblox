local ServerStorage = game:GetService("ServerStorage")

local function fmt(v)
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

local expect = {}
function expect.equal(actual, expected)
	if actual ~= expected then
		error(string.format("expected %s, got %s", fmt(expected), fmt(actual)), 2)
	end
end
function expect.truthy(value)
	if not value then
		error(string.format("expected truthy, got %s", fmt(value)), 2)
	end
end
function expect.falsy(value)
	if value then
		error(string.format("expected falsy, got %s", fmt(value)), 2)
	end
end
function expect.near(actual, expected, tolerance)
	tolerance = tolerance or 1e-6
	if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
		error(string.format("expected %s within %s of %s", fmt(actual), fmt(tolerance), fmt(expected)), 2)
	end
end
function expect.throws(fn)
	local ok, err = pcall(fn)
	if ok then
		error("expected the function to throw, but it returned normally", 2)
	end
	return err
end
function expect.deepEqual(actual, expected)
	local function eq(a, b)
		if a == b then
			return true
		end
		if type(a) ~= "table" or type(b) ~= "table" then
			return false
		end
		for k, v in pairs(a) do
			if not eq(v, b[k]) then
				return false
			end
		end
		for k in pairs(b) do
			if a[k] == nil then
				return false
			end
		end
		return true
	end
	if not eq(actual, expected) then
		error("tables are not deeply equal", 2)
	end
end

local function runOne(fn)
	local cpuStart = os.clock()
	local ok, err = pcall(fn)
	local elapsed = os.clock() - cpuStart
	if ok then
		return "pass", elapsed, nil
	end
	return "fail", elapsed, tostring(err)
end

return function()
	local totals = { run = 0, passed = 0, failed = 0 }
	local sessionStart = os.clock()

	for _, module in ipairs(ServerStorage.UnitTest.Cases:GetDescendants()) do
		if module:IsA("ModuleScript") then
			local okRequire, caseFn = pcall(require, module)
			if not okRequire or type(caseFn) ~= "function" then
				totals.run += 1
				totals.failed += 1
				warn(string.format("[FAIL] %s | case did not return a function: %s", module.Name, tostring(caseFn)))
			else
				local t = { expect = expect }
				function t.test(name, fn)
					totals.run += 1
					local status, elapsed, message = runOne(fn)
					if status == "pass" then
						totals.passed += 1
						print(string.format("[PASS] %s > %s (%.3fs)", module.Name, name, elapsed))
					else
						totals.failed += 1
						warn(
							string.format(
								"[%s] %s > %s (%.3fs) | %s",
								string.upper(status),
								module.Name,
								name,
								elapsed,
								message
							)
						)
					end
				end
				local okRun, runErr = pcall(caseFn, t)
				if not okRun then
					totals.run += 1
					totals.failed += 1
					warn(string.format("[FAIL] %s | error while building cases: %s", module.Name, tostring(runErr)))
				end
			end
		end
	end

	print(
		string.format(
			"[SUMMARY] %d run, %d passed, %d failed, %.3fs",
			totals.run,
			totals.passed,
			totals.failed,
			os.clock() - sessionStart
		)
	)
	return totals
end
