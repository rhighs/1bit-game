local ffi = require "ffi"
local consts = require "consts"
local util = require "util"
local player_lib = require "player"
local loader = require "loader"
local camera = require "camera"
local color = require "color"
local vec = require "vec"
local physics = require "physics"
local start_screen = require "start-screen-controller"
local cooldown = require "cooldown"
local entity = require "entity"
local shader = require "shader"

local world_lib = {}

world_lib.DRAW_PHYSICS = false

function world_lib.new(data, scene_queue, from_warp)
    local shader = shader.create_fragment_shader()

    function find_warp(name)
        local warp = table.find(data.entities, function (e) return e.data.warp_name == name end)
        if warp == nil then
            GAME_LOG("WARNING: no warp found: " .. name)
            return nil
        end
        return vec.v2(warp.pos.x + warp.width/2, warp.pos.y + warp.height)
    end

    local world = {
        player = player_lib.new(from_warp ~= nil and find_warp(from_warp) or data.level_start),
        entities = {},
        entity_data = data.entities,
        id_count = #data.entities + 1,
        cam = camera.new(consts.VP, vec.v2(-math.huge, -math.huge)),
        bounds = data.level_bounds,
        ground = data.ground,
        decor = data.decor,
        tile_data = data.tiles,
        scene_queue = scene_queue,
        mode = 'enter',
        warp = {
            pos = nil,
            fade_light = 0.0,
            step = 0.05
        }
    }

    physics.register_body(world.player.body)

    function world:check_player_bounds(bounds)
        return rl.CheckCollisionCircleRec(self.player:position(), self.player.body.radius, bounds)
    end

    function world:set_palette(black, white)
        black = rl.ColorNormalize(black)
        white = rl.ColorNormalize(white)
        local b = ffi.new "float [3]"
        local w = ffi.new "float [3]"
        b[0], b[1], b[2] = black.x, black.y, black.z
        w[0], w[1], w[2] = white.x, white.y, white.z
        shader.on_black_color = { b, rl.SHADER_UNIFORM_VEC3 }
        shader.on_white_color = { w, rl.SHADER_UNIFORM_VEC3 }
    end

    function world:set_lightness(value)
        local lightness = ffi.new "float [1]"
        lightness[0] = value
        shader.lightness = { lightness, rl.SHADER_UNIFORM_FLOAT }
    end

    function world:normal_update(dt, old_cam)
        if not self:check_player_bounds(self.bounds) then
            self.scene_queue:send({ name = "gameover" })
            return
        end

        -- despawn entities when they stay off-screen for too much time
        -- or if they've fallen inside pits
        local to_despawn = table.map(
            table.filter(self.entities, function (e)
                local p = e:get_draw_box()
                return not e.keepalive and (e.offscreen_start >= 400
                    or p.y > self.bounds.y + self.bounds.height)
            end),
            function (e) return e.id end
        )
        for _, id in ipairs(to_despawn) do
            GAME_LOG("despawning entity with id =", id)
            if self.entities[id].on_despawn ~= nil then
                self.entities[id]:on_despawn()
            end
            if self.entities[id].body ~= nil then
                physics.unregister_body(self.entities[id].body)
            end
            self.entities[id] = nil
        end

        -- spawn new entities when they come inside the camera
        local new_entities = table.filter(
            self.entity_data,
            function (e)
                return self.entities[e.id] == nil
                   and self.cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
                   and not old_cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
            end
        )
        for _, e in ipairs(new_entities) do
            GAME_LOG("spawning new entity with id =", e.id)
            local entt = entity.create_new(self, e)
            self.entities[e.id] = entt
            if entt.body ~= nil then
                physics.register_body(entt.body)
            end
        end

        for _, e in pairs(self.entities) do
            e:update(dt)
            e.offscreen_start = self.cam:is_inside(e:get_draw_box()) and -1 or e.offscreen_start + 1
            if self:check_player_bounds(e:get_hitbox()) then
                e:player_collision(self.player:position())
            end
        end

        self.player:update(dt)
        physics.check_collisions(self.ground, physics.bodies, dt)
    end

    function world:warp_mode_update(dt, old_cam)
        self.warp.fade_light = self.warp.fade_light + self.warp.step
        if self.warp.fade_light < 0 and self.warp.step < 0 then
            self.warp.step = -self.warp.step
            self:set_lightness(0)
            if self.warp.data.level_name ~= nil and self.warp.data.level_name ~= "" then
                self.scene_queue:send({
                    name = "level",
                    data = {
                        level = "leveldata/" .. self.warp.data.level_name,
                        from_warp = self.warp.data.name
                    }
                })
            else
                local warp = find_warp(self.warp.data.name)
                if warp == nil then
                    return
                end
                self.player:set_position(warp)
                self:normal_update(dt, old_cam)
                self.warp.data = nil
            end
        elseif self.warp.fade_light > 1.0 and self.warp.step > 0 then
            self.warp.step = -self.warp.step
            self.mode = 'normal'
        else
            self:set_lightness(self.warp.fade_light)
        end
    end

    function world:enter_mode_update(dt, old_cam)
        if self.warp.fade_light == 0.0 then
            self:normal_update(dt, old_cam)
        end
        self.warp.fade_light = self.warp.fade_light + self.warp.step
        if self.warp.fade_light > 1.0 and self.warp.step > 0 then
            self.warp.step = -self.warp.step
            self.mode = 'normal'
        end
        self:set_lightness(self.warp.fade_light)
    end

    function world:update(dt)
        local old_cam = self.cam:clone()
        local level_size = vec.v2(self.bounds.width, self.bounds.height)
        self.cam:retarget(vec.clamp(
            self.player:position(),
            self.bounds + consts.VP/2,
            self.bounds + level_size - consts.VP/2
        ))

            if self.mode == 'warp'   then self:warp_mode_update(dt, old_cam)
        elseif self.mode == 'normal' then self:normal_update(dt, old_cam)
        elseif self.mode == 'enter'  then self:enter_mode_update(dt, old_cam)
        else error('invalid mode: ' .. self.mode) end
    end

    function world:draw_hud(dt)
        rl.DrawRectangle(0, 0, consts.VP_WIDTH, 50, rl.BLACK)
        -- player torch status
        local torch_bar_length = consts.VP_WIDTH / 3
        local text = "TORCH [T] "
        local text_height = 18
        local text_width = rl.MeasureText(text, text_height)
        rl.DrawText(text, 10, 10, text_height, rl.WHITE)
        local bar_x = 20 + text_width
        rl.DrawRectangleLines(bar_x, 10, torch_bar_length, text_height, rl.WHITE)
        rl.DrawRectangle(bar_x, 10, torch_bar_length * (self.player.torch_battery/100.0), text_height, rl.WHITE)
    end

    function world:draw_at(grid, x, y)
        local tile_info = grid[y][x]
        if tile_info == nil then
            return
        end

        -- rob: hide platform paths
        if tile_info.properties ~= nil and
        (tile_info.properties.ppath_point or tile_info.properties.ppath_decor) then
            return
        end

        local tile = self.tile_data[tile_info.gid]
        if tile == nil then
            error(util.pystr("trying to draw tile id =", tile_info.gid, "at pos = (", x, y, ")"))
        end

        local rotation = 0.0
        local origin = tile.size / 2
        local source_rec = util.RecV(tile.pos, tile.size)
        local y_offset = tile.size.y/32 - 1
        local dest_rec = util.Rec(
                       x*32 + origin.x,
            (y-y_offset)*32 + origin.y,
            tile.size.x, tile.size.y
        )

        local flip_diag, flip_vert, flip_horz =
            tile_info.flip_diag, tile_info.flip_vert, tile_info.flip_horz

        if flip_diag and flip_vert and flip_horz then
            source_rec.width = -source_rec.width
            rotation = 90.0
        elseif flip_diag and flip_vert then
            rotation = -90.0
        elseif flip_diag and flip_horz then
            rotation = 90.0
        elseif flip_vert and flip_horz then
            rotation = 180.0
        elseif flip_diag then
            source_rec.height = -source_rec.height
            rotation = 90.0
        elseif flip_vert then
            source_rec.height = -source_rec.height
        elseif flip_horz then
            source_rec.width = -source_rec.width
        end

        rl.DrawTexturePro(
            tile.texture,
            source_rec,
            dest_rec,
            origin,
            rotation,
            rl.WHITE
        )
    end

    function world:draw_grid(grid)
        -- draw two tiles over the screen bounds to permit 96x96 tiles
        local tl = vec.floor(self.cam:top_left_world_pos() / 32) - vec.v2(2, 2)
        local br = vec.floor(self.cam:bottom_right_world_pos() / 32) + vec.v2(2, 2)
        for y = tl.y, br.y do
            if grid[y] ~= nil then
                for x = tl.x, br.x do
                    self:draw_at(grid, x, y)
                end
            end
        end
    end

    function world:draw()
        rl.BeginShaderMode(shader:get())
        rl.ClearBackground(rl.BLACK)

        rl.BeginMode2D(self.cam:get())
        self:draw_grid(self.decor)
        self.player:draw(dt)
        self:draw_grid(self.ground)

        for _, e in pairs(self.entities) do
            if self.cam:is_inside(e:get_draw_box()) then
                e:draw()
                if self.debug_mode then
                    e:draw_debug()
                end
            end
        end

        if world_lib.DRAW_PHYSICS then
            for _, b in pairs(physics.bodies) do
                if b.__shape == "circle" then
                    rl.DrawCircleLines(b.position.x, b.position.y, b.radius, rl.RED)
                elseif b.__shape == "rectangle" then
                    rl.DrawRectangleLines(b.position.x, b.position.y, b.width, b.height, rl.RED)
                end

                vec.draw(b.velocity, b.position)
                if b.platform_velocity then
                    vec.draw(b.platform_velocity, b.position, rl.BLUE)
                end
            end
        end
        rl.EndMode2D()

        self:draw_hud(dt)
        rl.EndShaderMode()
    end

    function world:destroy()
        shader:unload()
    end

    function world:get_new_id()
        local id = self.id_count
        self.id_count = self.id_count + 1
        return id
    end

    -- public api functions:
    function world:spawn(data)
        local new_id = self:get_new_id()
        data.id = new_id
        GAME_LOG("spawning new entity with id =", new_id)
        local entt = entity.create_new(self, data)
        self.entities[new_id] = entt
        if entt.body ~= nil then
            physics.register_body(entt.body)
        end
    end

    function world:send_scene_event(name)
        self.scene_queue:send({ name = name })
    end

    function world:warp_to(name, level_name)
        self.warp.data = { name = name, level_name = level_name }
        self.mode = 'warp'
    end

    return world
end

return world_lib

