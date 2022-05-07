-- to make code shorter. Yes, it's global.
wml_actions = wesnoth.wml_actions

function wml_actions.loot( cfg )
	local gold_amount = tonumber( cfg.amount ) or wml.error( "Missing or wrong amount= value in [loot]" )
	local sides = wesnoth.sides.find( cfg )
	for index, side in ipairs( sides ) do
        -- no sound no nothing
        -- too annoying since this happens frequently
		side.gold = side.gold + gold_amount
	end
end