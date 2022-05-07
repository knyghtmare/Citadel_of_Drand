--<< leader_ability

local wesnoth = wesnoth
local citadel = citadel
local T = wesnoth.require("lua/helper.lua").set_wml_tag_metatable {}
local table = table

local function set_leader_ability(unit)
	local vars = unit.variables
	local arr = {}
	if vars.citadel_health_small > 0 then arr[#arr + 1] = vars.citadel_health_small .. " mini hp" end
	if vars.citadel_health_big > 0 then arr[#arr + 1] = vars.citadel_health_big .. " HP" end
	if vars.citadel_mp > 0 then arr[#arr + 1] = vars.citadel_mp .. " MP" end
	if vars.citadel_melee_damage > 0 then arr[#arr + 1] = vars.citadel_melee_damage .. " melee dmg" end
	if vars.citadel_melee_strikes > 0 then arr[#arr + 1] = vars.citadel_melee_strikes .. " melee strikes" end
	if vars.citadel_ranged_damage > 0 then arr[#arr + 1] = vars.citadel_ranged_damage .. " range dmg" end
	if vars.citadel_ranged_strikes > 0 then arr[#arr + 1] = vars.citadel_ranged_strikes .. " range strikes" end
	if vars.citadel_damage > 0 then arr[#arr + 1] = vars.citadel_damage .. " combo dmg" end
	if vars.citadel_strikes > 0 then arr[#arr + 1] = vars.citadel_strikes .. " combo strikes" end
	if vars.citadel_res_arcane > 0 then arr[#arr + 1] = "-" .. vars.citadel_respercent_arcane .. "% Arcane vuln" end
	if vars.citadel_res_blade > 0 then arr[#arr + 1] = "-" .. vars.citadel_respercent_blade .. "% Blade vuln" end
	if vars.citadel_res_cold > 0 then arr[#arr + 1] = "-" .. vars.citadel_respercent_cold .. "% Cold vuln" end
	if vars.citadel_res_fire > 0 then arr[#arr + 1] = "-" .. vars.citadel_respercent_fire .. "% Fire vuln" end
	if vars.citadel_res_impact > 0 then arr[#arr + 1] = "-" .. vars.citadel_respercent_impact .. "% Impact vuln" end
	if vars.citadel_res_pierce > 0 then arr[#arr + 1] = "-" .. vars.citadel_respercent_pierce .. "% Pierce vuln" end
	if unit.level < 1 then arr[#arr + 1] = "ZoC" end
	local ability = T.name_only {
		id = "citadel_leader",
		cumulative = false,
		name = "<b>leader</b>",
		description = "Upgrades: " .. table.concat(arr, ", ")
	}
	wesnoth.add_modification(unit, "object", {
		id = "citadel_leader_zoc",
		T.effect { apply_to = "zoc", value = true },
	})
	wesnoth.add_modification(unit, "object", {
		T.effect { apply_to = "remove_ability", T.abilities { ability } },
		T.effect { apply_to = "new_ability", T.abilities { ability } }
	})
end

citadel.set_leader_ability = set_leader_ability

-->>
