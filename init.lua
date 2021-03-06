local load_time_start = os.clock()

-- Freeminer Compatibility
if rawget(_G, "freeminer") then
	minetest = freeminer
end

landrush = {}

local path = minetest.get_modpath("landrush")

dofile(path.."/config.lua")
dofile(path.."/functions.lua")
dofile(path.."/claims.lua")
dofile(path.."/protection.lua")
dofile(path.."/shared_door.lua")
dofile(path.."/chest.lua")
dofile(path.."/sign.lua")
dofile(path..'/shared_inbox.lua')

if ( landrush.config:get_bool("enableHud") ) then
	dofile(path.."/hud.lua")
end

minetest.register_privilege(
	"landrush",
	"Allows player to dig and build anywhere, " ..
	"and use the landrush chat commands."
)

landrush.load_claims()

minetest.register_node("landrush:landclaim", {
		description = "Land Rush Land Claim",
		tiles = {"landrush_landclaim.png"},
		groups = {oddly_breakable_by_hand=2},
		on_place = function(itemstack, placer, pointed_thing)
			local owner = landrush.get_owner(pointed_thing.above)
			local player = placer:get_player_name()

			if player:find("[gG]uest") then
				minetest.chat_send_player(player,"Guests cannot claim land")
				return itemstack
			end
		
			if ( pointed_thing.above.y < -200 ) then
				minetest.chat_send_player(player,"You cannot claim below -200")
				return itemstack
			end
		
			if owner then
				minetest.chat_send_player(player, "This area is already owned by "..owner)
			else
				minetest.env:remove_node(pointed_thing.above)
				local chunk = landrush.get_chunk(pointed_thing.above)
				landrush.claims[chunk] = {owner=placer:get_player_name(),shared={},claimtype="landclaim"}
				landrush.save_claims()
				if stats then stats.increase_stat(placer:get_player_name(), 'land_claims', 1) end

				-- showarea
				local entpos = landrush.get_chunk_center(pointed_thing.above)
				entpos.y = (pointed_thing.above.y-1)
				minetest.env:add_entity(entpos, "landrush:showarea")

				minetest.chat_send_player(landrush.claims[chunk].owner, "You now own this area.")
				minetest.log("action", "landrush chunk (" .. chunk .. ") claimed by " .. player)
				itemstack:take_item()
				return itemstack
			end
		end,
})

minetest.register_craft({
		output = 'landrush:landclaim',
		recipe = {
			{'default:stone','default:steel_ingot','default:stone'},
			{'default:steel_ingot','default:mese_crystal','default:steel_ingot'},
			{'default:stone','default:steel_ingot','default:stone'}
		}
})

minetest.register_alias("landclaim", "landrush:landclaim")
minetest.register_alias("landrush:landclaim_b","landrush:landclaim")

minetest.register_entity("landrush:showarea",{
	on_activate = function(self, staticdata, dtime_s)
		minetest.after(16,function()
			self.object:remove()
		end)
	end,
	initial_properties = {
		hp_max = 1,
		physical = true,
		weight = 0,
		collisionbox = {
			landrush.config:get("chunkSize")/-2,
			landrush.config:get("chunkSize")/-2,
			landrush.config:get("chunkSize")/-2,
			landrush.config:get("chunkSize")/2,
			landrush.config:get("chunkSize")/2,
			landrush.config:get("chunkSize")/2,
		},
		visual = "mesh",
		visual_size = {
        	x=landrush.config:get("chunkSize")+0.1,
        	y=landrush.config:get("chunkSize")+0.1
		},
		mesh = "landrush_showarea.x",
		textures = {nil, nil, "landrush_showarea.png", "landrush_showarea.png", "landrush_showarea.png", "landrush_showarea.png"}, -- number of required textures depends on visual
		colors = {}, -- number of required colors depends on visual
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = true,
		makes_footstep_sound = false,
		automatic_rotate = false,
	}
})

if ( minetest.get_modpath("money2") ) then
	minetest.log('action','Loading Landrush Land Sale')
	dofile(path.."/landsale.lua")
end

if ( minetest.get_modpath('fire') ) then
	minetest.log('action','[landrush] adding fire protection to claimed areas')
	dofile(path..'/fire.lua')
end

if ( minetest.get_modpath('bucket') ) then
	minetest.log('action','[landrush] adding liquids placement protection')
  dofile(path..'/bucket.lua')
end

if minetest.get_modpath("stats") then
	stats.register_stat({
		name = "land_claims",
		description = function(value)
			return " - Land claims: "..value
		end,
	})

	stats.register_stat({
		name = "land_shares",
		description = function(value)
			return " - Land shares: "..value
		end,
	})
end

minetest.after(0, function ()

dofile(path.."/default.lua")
--dofile(path.."/doors.lua")
dofile(path.."/chatcommands.lua")
--dofile(path.."/screwdriver.lua")
dofile(path.."/snow.lua")

end )

minetest.log(
	'action',
	string.format(
		'['..minetest.get_current_modname()..'] loaded in %.3fs',
		os.clock() - load_time_start
	)
)
