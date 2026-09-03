local ServerStorage = game:GetService("ServerStorage")

local expect = require(script.Parent.Expect)

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
