for _, unit in ipairs(wesnoth.units.find_on_recall {}) do
    unit.recall_cost = unit.cost
end