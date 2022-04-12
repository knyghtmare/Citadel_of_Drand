-- original code credits to fluffbeast
-- modified by Lord-Knightmare to accomodate lvl 1 and lvl 2 units

local cost_lvl_zero = 15
local cost_lvl_one = 25
local cost_lvl_two = 35
local cost_lvl_three = 45
local cost_lvl_four = 55
local cost_lvl_five = 70

for _, unit in ipairs(wesnoth.units.find_on_recall {}) do
    if unit.level == 0 then
        unit.recall_cost = cost_lvl_zero
    end

    if unit.level == 1 then
        unit.recall_cost = cost_lvl_one
    end

    if unit.level == 2 then
        unit.recall_cost = cost_lvl_two
    end

    if unit.level == 3 then
        unit.recall_cost = cost_lvl_three
    end

    if unit.level == 4 then
        unit.recall_cost = cost_lvl_four
    end

    if unit.level == 5 then
        unit.recall_cost = cost_lvl_five
    end
end