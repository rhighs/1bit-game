local ffi = require "ffi"
local consts = require "consts"
local event_queue = require "event_queue"
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
local textures = require "textures"
local shader = require "shader"

local world_lib = {}

world_lib.DRAW_PHYSICS = false

function world_lib.new(data, scene_queue, from_warp, player_init_state)
    local shader = shader.create_fragment_shader()

    function find_warp(name)
        local warp = table.find(data.entities, function (e)
            return e.props.warp_name == name
        end)
        if warp == nil then
            GAME_LOG("WARNING: no warp found: " .. name)
            return nil
        end
        GAME_LOG("warping to ", warp.pos)
        return vec.v2(
            warp.pos.x + warp.width/2,
            warp.pos.y + warp.height
        )
    end

    local world = {
        entities = {},
        entity_data = data.entities,
        entities_queue = event_queue.new(),
        entities_despawned_forever = {},
        id_count = #data.entities + 1,

        signal_queue = event_queue.new(),
        cam = camera.new(consts.VP, vec.v2(-math.huge, -math.huge)),
        bounds = data.level_bounds,
        ground = data.ground,
        decor = data.decor,
        tile_data = data.tiles,
        scene_queue = scene_queue,
        deferred = {},
        mode = 'enter',
        warp = {
            pos = nil,
            fade_light = 0.0,
            step = 0.05
        }
    }

    local start_pos = from_warp ~= nil and find_warp(from_warp) or data.level_start
    local player = player_lib.new(start_pos, world)
    world.player = player
    if player_init_state ~= nil then
        world.player.powerup = player_init_state.powerup
        world.player.num_keys = player_init_state.num_keys
    end

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

        for i = 0, #self.deferred do
            if self.deferred[i] ~= nil then
                if self.deferred[i].timeout_secs >= 0 then
                    self.deferred[i].timeout_secs = self.deferred[i].timeout_secs - dt
                else
                    self.deferred[i].callback()
                    self.deferred[i] = nil
                end
            end
        end

        -- despawn entities when they stay off-screen for too much time
        -- or if they've fallen inside pits
        local to_despawn = table.filter(self.entities, function (e)
            local p = e:get_draw_box()
            return not e.keepalive
               and (e.offscreen_count >= 400 or p.y > self.bounds.y + self.bounds.height)
        end)
        for _, e in pairs(to_despawn) do
            self:despawn(e)
        end

        -- spawn new entities when they come inside the camera
        local new_entities = table.filter(
            self.entity_data,
            function (e)
                return self.entities[e.id] == nil
                   and self.cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
                   and not old_cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
                   and self.entities_despawned_forever[e.id] == nil
            end
        )
        for _, e in ipairs(new_entities) do
            self:spawn(e)
        end

        -- update entities: first their update function, then the offscreen
        -- frame count, then their collisions (player and other entities)
        for _, e in pairs(self.entities) do
            e:update(dt)
            e.offscreen_count = self.cam:is_inside(e:get_draw_box()) and -1 or e.offscreen_count + 1
            if self:check_player_bounds(e:get_hitbox()) then
                e:player_collision(self.player:position())
            end

            for _, ee in pairs(self.entities) do
                if e.id ~= ee.id and rl.CheckCollisionRecs(e:get_hitbox(), ee:get_hitbox()) and e.entity_collision ~= nil then
                    e:entity_collision(ee.position or ee.pos or nil, ee.id)
                end
            end
        end

        self.player:update(dt)
        physics.check_collisions(self.ground, physics.bodies, dt)

        -- listen for entities events
        for ev in self.entities_queue:recv_all() do
            if ev ~= nil then
                if ev.type == "powerup-pickup" then
                    self.player.powerup = ev.powerup_tag
                elseif ev.type == "key-got" then
                    self.player.num_keys = self.player.num_keys + 1
                elseif ev.type == "key-used" then
                    self.player.num_keys = self.player.num_keys - 1
                end
            end
        end

        for ev in self.signal_queue:recv_all() do
            self:dispatch_signal(ev)
        end
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
                        from_warp = self.warp.data.name,
                        player_state = {
                            powerup = self.player.powerup,
                            num_keys = self.player.num_keys
                        }
                    }
                })
            else
                local warp = find_warp(self.warp.data.name)
                if warp == nil then
                    return
                end
                self.player:set_position(warp - vec.v2(0, player_lib.BODY_RADIUS))
                GAME_LOG(self.player:position())
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
        local text_height = 16
        local text_width = rl.MeasureText(text, text_height)
        rl.DrawText(text, 10, 10, text_height, rl.WHITE)
        local bar_x = 20 + text_width
        rl.DrawRectangleLines(bar_x, 10, torch_bar_length, text_height, rl.WHITE)
        rl.DrawRectangle(bar_x, 10, torch_bar_length * (self.player.torch_battery / 100.0), text_height, rl.WHITE)

        -- draw number of keys
        local key_text_start = bar_x + torch_bar_length + 16
        local key_text_height = 20
        rl.DrawTextureV(textures.key_small, vec.v2(key_text_start, 10), rl.WHITE)
        local key_text = "x " .. tostring(self.player.num_keys)
        local key_text_length = rl.MeasureText(key_text, key_text_height)
        rl.DrawText(key_text, key_text_start + textures.key_small.width + 8, 10, key_text_height, rl.WHITE)

        -- draw current powerup icon
        if self.player.powerup ~= nil then
            local icon_pos = vec.v2(consts.VP_WIDTH - 42, 10)
            local icon_dims = vec.v2(32, 32)
            local border_dims = vec.v2(36, 36)
            local icon_center = icon_pos + (icon_dims / 2)
            local border_pos = icon_center - (border_dims / 2)

            rl.DrawRectangleLinesEx(util.RecV(border_pos, border_dims), 2, rl.WHITE)

            rl.DrawTexturePro(
                textures.powerups,
                util.RecV(vec.zero(), vec.v2(32, 32)),
                util.RecV(icon_pos, icon_dims),
                vec.zero(),
                0,
                rl.WHITE
            )
        end
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

    function world:dispatch_signal(ev)
        function dispatch_signal(entity)
            local func = entity["on_signal_" .. ev.signal]
            if func then
                func(entity, ev.data)
            end
        end

        if ev.entity_id then
            dispatch_signal(self.entities[ev.entity_id])
        else
            for _, e in pairs(self.entities) do dispatch_signal(e) end
        end
    end

    function world:spawn(data)
        if data.id == nil then
            data.id = self:get_new_id()
        end
        GAME_LOG("spawning new entity with id =", data.id)
        local entt = entity.create_new(self, data)
        self.entities[data.id] = entt
        if entt.body ~= nil then
            physics.register_body(entt.body)
        end
        entt.offscreen_count = -1
    end

    function world:despawn(entity, never_respawn)
        GAME_LOG("despawning entity with id =", entity.id)
        if self.entities[entity.id].on_despawn ~= nil then
            self.entities[entity.id]:on_despawn()
        end
        if self.entities[entity.id].body ~= nil then
            physics.unregister_body(self.entities[entity.id].body)
        end
        self.entities[entity.id] = nil
        if never_respawn then
            self.entities_despawned_forever[entity.id] = true
        end
    end

    function world:defer_run(func, timeout_secs)
        table.insert(self.deferred, {
            callback = func,
            timeout_secs = timeout_secs
        })
    end

    function world:send_scene_event(name)
        self.scene_queue:send({ name = name })
    end

    function world:warp_to(name, level_name)
        self.warp.data = { name = name, level_name = level_name }
        self.mode = 'warp'
    end

    function world:emit_signal(signal, data, entity_id)
        self.signal_queue:send({
            signal = signal,
            data = data,
            entity_id = entity_id
        })
    end

    return world
end

return world_lib

