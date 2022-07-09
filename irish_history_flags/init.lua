----------------------------------------------------------
-- Minetest :: irish_history Flags Mod (irish_history_flags)
--
-- See README.txt for licensing and other information
-- Code adapted from "pride_flags" mod by Leslie E. Krause
-- Copyright (c) 2022, BubbaFrog
--
-- ./games/minetest_game/mods/irish_history_flags/init.lua
----------------------------------------------------------

local wind_noise = PerlinNoise( 204, 1, 0, 500 )
local active_flags = { }

local pi = math.pi
local rad_180 = pi
local rad_90 = pi / 2

local flag_list = {"ireland", "oldireland", "ira", "officialira", "ulsterdefence", "ireland3", "ira2", "british", "ireland2", "british2", "ira3", "ulsterdefence2", "ira4"}

minetest.register_entity( "irish_history_flags:wavingflag", {
	initial_properties = {
		physical = false,
		visual = "mesh",
		visual_size = { x = 8.5, y = 8.5 },
		collisionbox = { -0.1, -0.85, -0.1, 0.1, 0.85, 0.1 },
		backface_culling = false,
		pointable = false,
		mesh = "wavingflag.b3d",
		textures = { string.format( "irish_history_flags_%s.png", flag_list[1] ) },
		use_texture_alpha = false,
	},

	on_activate = function ( self, staticdata, dtime )
		self:reset_animation( math.random( 1, 50 ) )  -- random starting frame to desynchronize multiple flags
		self.object:set_armor_groups( { immortal = 1 } )

		if staticdata ~= "" then
			local data = minetest.deserialize( staticdata )
			self.flag_idx = data.flag_idx
			self.node_idx = data.node_idx

			if not self.flag_idx or not self.node_idx then
				self.object:remove( )
				return
			end
			self:reset_texture( self.flag_idx )

			active_flags[ self.node_idx ] = self.object
		else
			self.flag_idx = 1
		end
	end,

	on_deactivate = function ( self )
		if self.sound_id then
			minetest.sound_stop( self.sound_id )
		end
	end,

	on_step = function ( self, dtime )
		self.anim_timer = self.anim_timer - dtime

		if self.anim_timer <= 0 then
			minetest.sound_stop( self.sound_id )
			self:reset_animation( 1 )
		end
	end,

	reset_animation = function ( self, start_frame )
		local cur_wind = wind_noise:get2d( { x = os.time( ) % 65535, y = 0 } ) * 30 + 30
print( cur_wind )
		local anim_speed
		local wave_sound

		if cur_wind < 10 then
			anim_speed = 10	-- 2 cycle
			wave_sound = "flagwave1"
		elseif cur_wind < 20 then
			anim_speed = 20  -- 4 cycles
			wave_sound = "flagwave1"
		elseif cur_wind < 40 then
			anim_speed = 40  -- 8 cycles
			wave_sound = "flagwave2"
		else
			anim_speed = 80  -- 16 cycles
			wave_sound = "flagwave3"
		end

		if self.object then
			self.object:set_animation( { x = start_frame, y = 575 }, anim_speed, 0, true )
			self.sound_id = minetest.sound_play( wave_sound, { object = self.object, gain = 1.0, loop = true } )
		end

		self.anim_timer = ( 576 - start_frame ) / 5  -- default to 115 seconds to reset animation
	end,

	reset_texture = function ( self, flag_idx )
		if not flag_idx then
			self.flag_idx = self.flag_idx % #flag_list + 1	-- this automatically increments
		else
			self.flag_idx = flag_idx
		end

		local texture = string.format( "irish_history_flags_%s.png", flag_list[ self.flag_idx ] )
		self.object:set_properties( { textures = { texture } } )
	end,

	get_staticdata = function ( self )
		return minetest.serialize( {
			node_idx = self.node_idx,
			flag_idx = self.flag_idx,
		} )
	end,
} )

minetest.register_node( "irish_history_flags:lower_mast", {
        description = "Flag Pole",
        drawtype = "mesh",
        paramtype = "light",
        mesh = "mast_lower.obj",
        paramtype2 = "facedir",
        groups = { cracky = 2, post = 1 },
        tiles = { "default_baremetal.png", "default_baremetal.png" },
	groups = { cracky = 1, level = 2 },
	--sounds = default.node_sound_metal_defaults( ),

        selection_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },
} )

minetest.register_node( "irish_history_flags:upper_mast", {
	description = "Flag Pole",
	drawtype = "mesh",
	paramtype = "light",
	mesh = "mast_upper.obj",
	paramtype2 = "facedir",
	groups = { cracky = 2 },
	tiles = { "default_baremetal.png", "default_baremetal.png" },
	groups = { cracky = 1, level = 2 },
	--sounds = default.node_sound_metal_defaults( ),

        selection_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 27/16, 3/32 } },
        },
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 27/16, 3/32 } },
        },

	on_rightclick = function ( pos, node, player )
		local node_idx = minetest.hash_node_position( pos )

		if minetest.check_player_privs( player:get_player_name( ), "server" ) then
			active_flags[ node_idx ]:get_luaentity( ):reset_texture( )
		end
	end,

	on_construct = function ( pos )
		local node_idx = minetest.hash_node_position( pos )
		local param2 = minetest.get_node( pos ).param2
		local facedir_to_pos = {
			[0] = { x = 0, y = 0.6, z = -0.1 },
			[1] = { x = -0.1, y = 0.6, z = 0 },
			[2] = { x = 0, y = 0.6, z = 0.1 },
			[3] = { x = 0.1, y = 0.6, z = 0 },
		}

		local facedir_to_yaw = {
			[0] = rad_90,
			[1] = 0,
			[2] = -rad_90,
			[3] = rad_180,
		}
		local flag_pos = vector.add( pos, vector.multiply( facedir_to_pos[ param2 ], 1 ) )
		local obj = minetest.add_entity( flag_pos, "irish_history_flags:wavingflag" )

		obj:get_luaentity( ).node_idx = node_idx
		obj:set_yaw( facedir_to_yaw[ param2 ] - rad_180 )

		active_flags[ node_idx ] = obj
	end,

	on_destruct = function ( pos )
		local node_idx = minetest.hash_node_position( pos )
		if active_flags[ node_idx ] then
			active_flags[ node_idx ]:remove( )
		end
	end,
} )
