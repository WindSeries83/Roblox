-- Shared assertion helpers used by both runners (in-Studio RunUnitTest and headless Lune runner).

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

return expect
