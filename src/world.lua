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

local world_lib = {}

world_lib.DRAW_PHYSICS = false

function world_lib.new(data, scene_queue)
    local world = {
        player = player_lib.new(data.level_start),
        entities = {},
        cam = camera.new(consts.VP, vec.v2(0, 0)),
        bounds = data.level_bounds,
        ground = data.ground,
        decor = data.decor,
        scene_queue = scene_queue
    }

    physics.register_body(world.player.body)

    function world:check_player_bounds(bounds)
        return rl.CheckCollisionCircleRec(self.player:position(), self.player.body.radius, bounds)
    end

    function world:update(dt)
        if not self:check_player_bounds(self.bounds) then
            self.scene_queue:send({ name = "gameover" })
            return
        end
        
        local old_cam = self.cam:clone()
        local level_size = vec.v2(self.bounds.width, self.bounds.height)
        self.cam:retarget(vec.clamp(
            self.player:position(),
            self.bounds + consts.VP/2,
            self.bounds + level_size - consts.VP/2
        ))

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
            data.entities,
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
        local texture = data.textures[tile_info.gid]
        if texture == nil then
            error(util.pystr("trying to draw tex id =", tile_info.gid, "at pos = (", x, y, ")"))
        end

        local rotation = 0.0
        local origin = vec.v2(texture.width, texture.height)/2
        local source_rec = util.Rec(0, 0, texture.width, texture.height)
        local y_offset = texture.height/32 - 1
        local dest_rec = util.Rec(
            x           *32 + origin.x,
            (y-y_offset)*32 + origin.y,
            texture.width, texture.height
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
            texture,
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
    end

    -- public api functions:
    function world:spawn(data)
        local new_id = #self.entities + 1
        data.id = new_id
        local entt = entity.create_new(self, data)
        self.entities[new_id] = entt
        if entt.body ~= nil then
            physics.register_body(entt.body)
        end
    end

    function world:send_scene_event(name)
        self.scene_queue:send({ name = name })
    end

    return world
end

return world_lib
