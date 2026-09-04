--!strict

local Probability = require("../src/shared/Probability")

local function near(actual: number, expected: number, tolerance: number)
	assert(math.abs(actual - expected) <= tolerance, `expected {expected}, got {actual}`)
end

local order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
local base = { Common = 9, Rare = 1 }
local final = Probability.FinalRarityWeights(base, order, 0, 0.5)
near(final.Common, 4.5, 1e-6)
near(final.Uncommon, 4.5, 1e-6)
near(final.Rare, 0.5, 1e-6)
near(final.Epic, 0.5, 1e-6)

local first = Probability.FinalHatchWeights(
	"CommonEgg",
	{ CommonEgg = base },
	{ Common = 40, Uncommon = 40, Rare = 20 },
	order,
	10,
	0,
	nil,
	0,
	0
)
assert(first.Common == 40 and first.Uncommon == 40 and first.Rare == 20, "first hatch weights changed")

local pity = Probability.FinalHatchWeights(
	"CommonEgg",
	{ CommonEgg = base },
	{ Common = 40, Uncommon = 40, Rare = 20 },
	order,
	10,
	0,
	nil,
	3,
	9
)
local pityEntries = 0
for rarity in pity do
	pityEntries += 1
	assert(rarity == "Rare", "pity contains a non-rare outcome")
end
assert(pity.Rare == 100 and pityEntries == 1, "pity is not a rare-only outcome")

print("[PASS] probability engine: ascension, first hatch and pity")
