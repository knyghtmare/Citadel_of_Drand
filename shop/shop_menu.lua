-- << shop_menu

local wesnoth = wesnoth
local citadel = citadel
local T = wesnoth.require("lua/helper.lua").set_wml_tag_metatable {}
local ipairs = ipairs
local math = math
local string = string
local table = table
local tostring = tostring


local event_side
local event_unit

local unit_at_shop = function()
	local unit = wesnoth.get_unit(wml.variables.x1, wml.variables.y1)
	return unit
		and unit.canrecruit
		and unit.side == wesnoth.current.side
end

local function moveto_event()
	local x1 = wesnoth.get_variable("x1") or 0
	local y1 = wesnoth.get_variable("y1") or 0
	local unit = wesnoth.get_unit(x1, y1)
	if unit and is_ai_array[wesnoth.current.side] == false then
		if is_at_shop(unit.side, x1, y1) then
			full_heal(unit)
			creepwars.show_shop_menu()
		end
	end
end

citadel.moveto_event = moveto_event

citadel_unit_at_shop = unit_at_shop

local err = function(message)
	citadel.wesnoth_message { message = message, image = "misc/red-x.png" }
end

local function show_shop_dialog(conf)
	local options = {}
	for _, e in ipairs(conf.options) do
		local gold_msg = e.gold and "<span color='#FFE680'>cost " .. e.gold .. "</span>" or ""
		options[#options + 1] = {
			text = e.text .. gold_msg,
			image = e.image,
			func = e.func
		}
	end
	return citadel.show_dialog { label = conf.label, spacer = conf.spacer, options = options }
end


local function loop(label_orig)
	return function(options)
		return function()
			repeat
				local label = label_orig .. "\nYour gold: " .. event_side.gold
				local result = show_shop_dialog { label = label, options = options }
				if result.is_ok then options[result.index].func() end
			until not result.is_ok
		end
	end
end


local function give_effect(cost, id, effect)
	return function ()
		local effect_wml = effect[1] == "effect" and { effect } or effect
		if event_side.gold < cost then
			err("Not enough gold")
		else
			event_side.gold = event_side.gold - cost
			if id then
				event_unit.variables["citadel_" .. id] = event_unit.variables["citadel_" .. id] + 1
			end
			wesnoth.add_modification(event_unit, "object", effect_wml)
		end
	end
end

local hero_loop = function()
	repeat
		local label = "Hero Upgrade."
		label = label .. "\nYour gold: " .. event_side.gold
		local big_hp = math.floor(wesnoth.unit_types[event_unit.type].max_hitpoints * 70 / 100)
		local small_hp = math.floor(wesnoth.unit_types[event_unit.type].max_hitpoints * 28 / 100)
		local hex = "misc/blank-hex.png"
		local sword = "items/sword.png~CROP(20,24,32,32)"
		local bow = "items/bow-crystal.png~CROP(19,21,33,31)~ROTATE(90)"
		local options = {
			{
				text = "Large Hitpoint Boost +" .. big_hp .. " HP (70% unit type HP)\n",

				image = hex .. "~BLIT(icons/potion_red_medium.png,5,5)",
				gold = 50,
				func = give_effect(50, "health_big", T.effect {
					apply_to = "hitpoints",
					increase_total = big_hp,
					increase = big_hp,
					violate_maximum = true,
				})
			}, {
				text = "Small Hitpoint Boost +" .. small_hp .. " HP (28% unit type HP)\n",
				image = hex .. "~BLIT(icons/potion_red_small.png,5,5)",
				gold = 22,
				func = give_effect(22, "health_small", T.effect {
					apply_to = "hitpoints",
					increase_total = small_hp,
					increase = small_hp,
					violate_maximum = true,
				})
			}, {
				text = "Movement +1 \n",
				image = hex .. "~BLIT(icons/jewelry_butterfly_pin.png,5,5)",
				gold = event_unit.max_moves * 4 .. ", "
					.. (event_unit.max_moves * 4 + 4) .. ", "
					.. (event_unit.max_moves * 4 + 8) .. ", ...",
				func = give_effect(event_unit.max_moves * 4, "mp", T.effect {
					apply_to = "movement",
					increase = 1
				})
			}, {
				text = "Melee Damage +1 \n",
				image = string.format("%s~BLIT(%s~SCALE(64,64),5,5)", hex, sword),
				gold = 14,
				func = give_effect(14, "melee_damage", T.effect {
					apply_to = "attack",
					range = "melee",
					increase_damage = 1
				})
			}, {
				text = "Melee Strikes +1 \n",
				image = string.format("%s~BLIT(%s,10,18)~BLIT(%s,27,21)", hex, sword, sword),
				gold = 42,
				func = give_effect(42, "melee_strikes", T.effect {
					apply_to = "attack",
					range = "melee",
					increase_attacks = 1
				})
			}, {
				text = "Ranged Damage +1 \n",
				image = string.format("%s~BLIT(%s~SCALE(64,64))", hex, bow),
				gold = 14,
				func = give_effect(14, "ranged_damage", T.effect {
					apply_to = "attack",
					range = "ranged",
					increase_damage = 1
				})
			}, {
				text = "Ranged Strikes +1 \n",
				gold = 42,
				image = string.format("%s~BLIT(%s,8,26)~BLIT(%s,27,21)", hex, bow, bow),
				func = give_effect(42, "ranged_strikes", T.effect {
					apply_to = "attack",
					range = "ranged",
					increase_attacks = 1
				})
			}, {
				text = "Combo Damage +1 \n(discounts per buy)\n",
				gold = math.max(16, 23 - event_unit.variables.citadel_damage) .. ", "
					.. math.max(16, 22 - event_unit.variables.citadel_damage)
					.. ", ..., 16, 16, 16",
				image = string.format("%s~BLIT(%s~SCALE(64,64))~BLIT(%s~SCALE(64,64),5,5)", hex, bow, sword),
				func = give_effect(math.max(16, 23 - event_unit.variables.citadel_damage),
					"damage",
					T.effect {
						apply_to = "attack",
						increase_damage = 1
					})
			}, {
				text = "Combo Strikes +1 \n(discounts per buy)\n",
				gold = math.max(48, 66 - 6 * event_unit.variables.citadel_strikes) .. ", "
					.. math.max(48, 60 - 6 * event_unit.variables.citadel_strikes)
					.. ", ..., 48, 48, 48",
				image = string.format("%s~BLIT(%s~BLIT(%s,0,0)~BLIT(%s,36,0)~BLIT(%s,0,30)~BLIT(%s,36,30)~SCALE(50,50),10,20)",
					hex, hex, bow, sword, bow, sword),
				func = give_effect(math.max(48, 66 - 6 * event_unit.variables.citadel_strikes),
					"strikes",
					T.effect {
						apply_to = "attack",
						increase_attacks = 1
					})
			},
		}
		local result = show_shop_dialog { label = label, spacer = "", options = options }
		if result.is_ok then options[result.index].func() end
	until not result.is_ok
end


local function weapon_item(settings)
	local effect = settings.effect
	effect[#effect + 1] = T.specials(settings.specials)

	local specials_names = citadel.array_map(settings.specials or {},
		function(s) return tostring(s[2].name) end)
	local specials_string = table.concat(specials_names, ", ")
	local text = string.format("%s-%s %s\n%s %s <b>%s</b>\n",
		effect.damage,
		effect.number,
		effect.name,
		effect.range,
		effect.type,
		specials_string)

	effect.damage = effect.damage + event_unit.variables.citadel_damage
	effect.number = effect.number + event_unit.variables.citadel_strikes
	if effect.range == "melee" then
		effect.damage = effect.damage + event_unit.variables.citadel_melee_damage
		effect.number = effect.number + event_unit.variables.citadel_melee_strikes
	else
		effect.damage = effect.damage + event_unit.variables.citadel_ranged_damage
		effect.number = effect.number + event_unit.variables.citadel_ranged_strikes
	end
	return {
		text = text,
		image = effect.icon,
		gold = settings.gold,
		func = give_effect(settings.gold, nil, T.effect(effect))
	}
end

local weapon_loop = function()
	local attack_only_slow = {
		T.disable {
			active_on = "defense",
			id = "citadel_attack_only",
			name = wesnoth.textdomain("wesnoth-Ageless_Era")("attack only"),
			description = wesnoth.textdomain("wesnoth-Ageless_Era")("This weapon will never be used on defense."),
		},
		T.damage {
			multiply = "0.70",
			name = "weak70%",
			description = "This weapon only deals 70% of its maximum damage (including upgrades)",
		},
		citadel.weapon_specials.WEAPON_SPECIAL_SLOW,
	}
	repeat
		local label = "Weapon Upgrade."
		label = label .. "\nYour gold: " .. event_side.gold
		local options = {
			weapon_item {
				gold = 30,
				specials = { citadel.weapon_specials.WEAPON_SPECIAL_BACKSTAB },
				effect = {
					apply_to = "new_attack",
					name = "dagger",
					type = "blade",
					icon = "attacks/dagger-human.png",
					range = "melee",
					damage = 5,
					number = 3,
				}
			},
			weapon_item {
				gold = 40,
				specials = { citadel.weapon_specials.WEAPON_SPECIAL_FIRSTSTRIKE },
				effect = {
					apply_to = "new_attack",
					name = "pike",
					type = "pierce",
					icon = "attacks/pike.png",
					range = "melee",
					damage = 14,
					number = 1,
				}
			},
			weapon_item {
				gold = 40,
				effect = {
					apply_to = "new_attack",
					name = "holy sword",
					type = "arcane",
					icon = "attacks/sword-holy.png",
					range = "melee",
					damage = 6,
					number = 3,
				}
			},
			weapon_item {
				gold = 50,
				specials = attack_only_slow,
				effect = {
					apply_to = "new_attack",
					name = "whip",
					type = "impact",
					icon = "attacks/whip.png",
					range = "melee",
					damage = 10,
					number = 3,
				}
			},
			weapon_item {
				gold = 40,
				effect = {
					apply_to = "new_attack",
					name = "torch",
					type = "fire",
					icon = "attacks/torch.png",
					range = "melee",
					damage = 6,
					number = 3
				}
			},
			weapon_item {
				gold = 20,
				effect = {
					apply_to = "new_attack",
					name = "bow",
					type = "pierce",
					icon = "attacks/bow.png",
					range = "ranged",
					damage = 5,
					number = 3
				}
			},
			weapon_item {
				gold = 40,
				specials = { citadel.weapon_specials.WEAPON_SPECIAL_MARKSMAN },
				effect = {
					apply_to = "new_attack",
					name = "longbow",
					type = "pierce",
					icon = "attacks/bow-elven-magic.png",
					range = "ranged",
					damage = 14,
					number = 1,
				}
			},
			weapon_item {
				gold = 50,
				specials = attack_only_slow,
				effect = {
					apply_to = "new_attack",
					name = "net",
					type = "impact",
					icon = "attacks/net.png",
					range = "ranged",
					damage = 10,
					number = 3,
				}
			},
			weapon_item {
				gold = 40,
				specials = { citadel.weapon_specials.WEAPON_SPECIAL_POISON },
				effect = {
					apply_to = "new_attack",
					name = "poisoned knife",
					type = "blade",
					icon = "attacks/dagger-thrown-poison-human.png",
					range = "ranged",
					damage = 4,
					number = 2,
				}
			},
			weapon_item {
				gold = 40,
				specials = { citadel.weapon_specials.WEAPON_SPECIAL_MAGICAL },
				effect = {
					apply_to = "new_attack",
					name = "fireball",
					type = "fire",
					icon = "attacks/fireball.png",
					range = "ranged",
					damage = 6,
					number = 2,
				}
			},
			weapon_item {
				gold = 40,
				effect = {
					apply_to = "new_attack",
					name = "chill wave",
					type = "cold",
					icon = "attacks/iceball.png",
					range = "ranged",
					damage = 9,
					number = 2,
				}
			},
		}
		local result = show_shop_dialog { label = label, spacer = "", options = options }
		if result.is_ok then options[result.index].func() end
	until not result.is_ok
end


local function resistance_value(base, upgrade_count)
	return math.floor(base - base * math.pow(0.9, upgrade_count) + 0.5)
end

local function apply_resistances()
	for _, weap in ipairs { "arcane", "blade", "cold", "fire", "impact", "pierce" } do
		local key_percent = "citadel_respercent_" .. weap
		local old_resistance = event_unit.variables[key_percent] or 0
		wesnoth.add_modification(event_unit, "object", {
			T.effect { apply_to = "resistance", T.resistance { [weap] = old_resistance } },
		})

		local upgrade_count = event_unit.variables["citadel_res_" .. weap]
		local vulnerability = wesnoth.unit_resistance(event_unit, weap)
		local new_resistance = resistance_value(vulnerability, upgrade_count)
		event_unit.variables[key_percent] = new_resistance

		-- wesnoth.wml_actions.remove_object { object_id = key_number } -- doesn't work, wesnoth seems broken for res.
		wesnoth.add_modification(event_unit, "object", {
			T.effect { apply_to = "resistance", T.resistance { [weap] = -new_resistance } },
		})
	end
end

local function resistance_item(available, weap)
	local cost = 14
	local key_name = "citadel_res_" .. weap
	local have = event_unit.variables[key_name]
	local func = function()
		if available == 0 then
			err("Too many resistances bought")
		elseif wesnoth.sides[wesnoth.current.side].gold < cost then
			err("Not enough gold (need " .. cost .. ")")
		else
			event_side.gold = event_side.gold - cost
			event_unit.variables[key_name] = have + 1
		end
	end
	local have_string = have > 0 and "(" .. have .. ") " or ""
	local key_percent = "citadel_respercent_" .. weap
	local current_bonus = event_unit.variables[key_percent]
	local base_vuln = wesnoth.unit_resistance(event_unit, weap) + current_bonus
	local possible_increase = resistance_value(base_vuln, have + 1) - current_bonus
	return {
		text = "+" .. possible_increase .. "% "
			.. string.gsub(weap, "^%l", string.upper)
			.. " resistance " .. have_string .. " ",
		gold = cost,
		func = func
	}
end

local resistance_loop = function()
	repeat
		apply_resistances()
		local sum = event_unit.variables.citadel_res_arcane +
				event_unit.variables.citadel_res_blade +
				event_unit.variables.citadel_res_cold +
				event_unit.variables.citadel_res_fire +
				event_unit.variables.citadel_res_impact +
				event_unit.variables.citadel_res_pierce
		local maximum_allowed = 15
		local available = maximum_allowed - sum
		local label = "Resistance is <b>multiplicative</b>. \n"
		label = label .. "Available:" .. available .. "/" .. maximum_allowed .. "\n"
		label = label .. "(Wesnoths shows unit resistances by howering unit HP on the right panel)\n"
		label = label .. "\nYour gold: " .. event_side.gold
		local options = {
			resistance_item(available, "arcane"),
			resistance_item(available, "blade"),
			resistance_item(available, "cold"),
			resistance_item(available, "fire"),
			resistance_item(available, "impact"),
			resistance_item(available, "pierce"),
		}
		local result = show_shop_dialog { label = label, options = options }
		if result.is_ok then options[result.index].func() end
	until not result.is_ok
end

local shop_loop = loop("Shop.") {
	{
		text = "Upgrade Hero",
		image = "icons/potion_red_small.png",
		func = hero_loop
	}, {
		text = "Buy Weapons",
		image = "icons/crossed_sword_and_hammer.png",
		func = weapon_loop
	}, {
		text = "Buy Resistance",
		image = "icons/ring_gold.png",
		func = resistance_loop
	},
}

local function show_shop_menu()
	local x1 = wesnoth.get_variable("x1") or 0
	local y1 = wesnoth.get_variable("y1") or 0
	event_unit = wesnoth.get_unit(x1, y1) or wesnoth.get_units { side = 1 }[1]
	event_side = wesnoth.sides[wesnoth.current.side]

	local unit = event_unit
	unit.variables.citadel_res_arcane = unit.variables.citadel_res_arcane or 0
	unit.variables.citadel_res_blade = unit.variables.citadel_res_blade or 0
	unit.variables.citadel_res_cold = unit.variables.citadel_res_cold or 0
	unit.variables.citadel_res_fire = unit.variables.citadel_res_fire or 0
	unit.variables.citadel_res_impact = unit.variables.citadel_res_impact or 0
	unit.variables.citadel_res_pierce = unit.variables.citadel_res_pierce or 0
	unit.variables.citadel_base_hp = unit.variables.citadel_base_hp
		or wesnoth.unit_types[unit.type].max_hitpoints
	unit.variables.citadel_health_small = unit.variables.citadel_health_small or 0
	unit.variables.citadel_health_big = unit.variables.citadel_health_big or 0
	unit.variables.citadel_mp = unit.variables.citadel_mp or 0
	unit.variables.citadel_melee_damage = unit.variables.citadel_melee_damage or 0
	unit.variables.citadel_melee_strikes = unit.variables.citadel_melee_strikes or 0
	unit.variables.citadel_ranged_damage = unit.variables.citadel_ranged_damage or 0
	unit.variables.citadel_ranged_strikes = unit.variables.citadel_ranged_strikes or 0
	unit.variables.citadel_damage = unit.variables.citadel_damage or 0
	unit.variables.citadel_strikes = unit.variables.citadel_strikes or 0

	if rawget(_G, "lessrandom") then _G.lessrandom.remove_object(unit) end
	unit.hitpoints = math.max(unit.hitpoints, unit.max_hitpoints)
	shop_loop()
	if rawget(_G, "lessrandom") then
		_G.lessrandom.add_object(unit)
		unit.hitpoints = unit.max_hitpoints -- compensate for object removale scaling
	else
		unit.hitpoints = math.max(unit.hitpoints, unit.max_hitpoints)
	end
	apply_resistances() -- needs to be applied after each shop visit
	citadel.set_leader_ability(unit)
end

citadel.show_shop_menu = show_shop_menu

wesnoth.wml_actions.set_menu_item {
	id = "citadel_enter_shop_menu",
	description = "Enter Shop",
	T.show_if {
		T.lua {
			code = "return citadel_unit_at_shop()"
		},
	},
	T.command {
		T.lua {
			code = "citadel.show_shop_menu()"
		}
	}
}

-- >>
