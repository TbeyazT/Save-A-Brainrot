-- Assets/Modules/WeightedRandom.lua
-- Universal Weighted Random Utility

local WeightedRandom = {}

--[[
  Entry format:
  {
    {Item = "Common", Weight = 70},
    {Item = "Rare", Weight = 25},
    {Item = "Mythic", Weight = 5},
  }

  NOTES:
  - Weight can be ANY positive number (not just 0–1).
  - Items can be anything (string, number, table, etc).
--]]

-- Get the total weight of a list
local function getTotalWeight(weightedList)
	local total = 0
	for _, entry in ipairs(weightedList) do
		total += entry.Weight
	end
	return total
end

-- Choose one item (with replacement)
function WeightedRandom.choose(weightedList, rng)
	assert(#weightedList > 0, "Weighted list cannot be empty")

	local totalWeight = getTotalWeight(weightedList)
	local randomValue = (rng or math.random)() * totalWeight
	local cumulative = 0

	for _, entry in ipairs(weightedList) do
		cumulative += entry.Weight
		if randomValue <= cumulative then
			return entry
		end
	end

	return weightedList[#weightedList] -- fallback
end

-- Choose multiple items (with replacement)
function WeightedRandom.chooseMultiple(weightedList, amount, rng)
	local results = {}
	for i = 1, amount do
		table.insert(results, WeightedRandom.choose(weightedList, rng))
	end
	return results
end

-- Choose one item (without replacement)
function WeightedRandom.chooseUnique(weightedList, rng)
	assert(#weightedList > 0, "Weighted list cannot be empty")

	local totalWeight = getTotalWeight(weightedList)
	local randomValue = (rng or math.random)() * totalWeight
	local cumulative = 0

	for i, entry in ipairs(weightedList) do
		cumulative += entry.Weight
		if randomValue <= cumulative then
			-- remove from the list (mutates it!)
			table.remove(weightedList, i)
			return entry.Item
		end
	end

	local last = table.remove(weightedList) -- fallback
	return last.Item
end

-- Choose multiple items (without replacement)
function WeightedRandom.chooseMultipleUnique(weightedList, amount, rng)
	local copy = table.clone(weightedList) -- don’t mutate original
	local results = {}
	for i = 1, math.min(amount, #copy) do
		table.insert(results, WeightedRandom.chooseUnique(copy, rng))
	end
	return results
end

-- Shuffle a list randomly (Fisher–Yates)
function WeightedRandom.shuffle(list, rng)
	local copy = table.clone(list)
	local rand = rng or math.random
	for i = #copy, 2, -1 do
		local j = rand(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

-- Normalize weights (useful for debug or UI)
function WeightedRandom.normalize(weightedList)
	local total = getTotalWeight(weightedList)
	local normalized = {}
	for _, entry in ipairs(weightedList) do
		table.insert(normalized, {
			Item = entry.Item,
			Weight = entry.Weight / total,
		})
	end
	return normalized
end

-- Pick guaranteed at least one of each rarity after X rolls
function WeightedRandom.guaranteedPull(weightedList, pulls, rng)
	local results = {}
	local seen = {}

	for i = 1, pulls do
		local pick = WeightedRandom.choose(weightedList, rng)
		table.insert(results, pick)
		seen[pick] = true
	end

	-- ensure every type appears at least once
	for _, entry in ipairs(weightedList) do
		if not seen[entry.Item] then
			table.insert(results, entry.Item)
		end
	end

	return results
end

return WeightedRandom