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

local level_scene = {}

function level_scene.new()
    return {
        name = "level",
        player = nil,
        data = {},
        cam = camera.new(consts.VP, vec.v2(0, 0)),
        bg_color = rl.BLACK,
        level_bounds = nil,
        do_game_over = false,
        do_level_completed = false,
        entities = {},

        init = function (self, data)
            self.do_game_over = false
            self.do_level_completed = false
            self.data = loader.load_level(require(data.level))
            self.level_bounds = self.data.level_bounds

            self.player = player_lib.new(self.data.level_start)
            physics.register_body(self.player.body)

            self.entities = {}
            -- for _, e in ipairs(self.data.entities) do
            --     local entt = entity.create_entity(e)
            --     table.insert(self.entities, entt)
            --     if entt.body ~= nil then
            --         physics.register_body(entt.body)
            --     end
            -- end
        end,

        destroy = function (self) physics.clear() end,

        color_swap = cooldown.make_cooled(function (self)
            self.bg_color = self.bg_color == rl.WHITE and rl.BLACK or rl.WHITE
        end, 0.2),

        update = function(self, dt)
            self:check_game_over()

            self.player:update(dt)

            local level_size = vec.v2(self.level_bounds.width, self.level_bounds.height)
            self.cam:retarget(vec.clamp(
                self.player:position(),
                self.level_bounds + consts.VP/2,
                self.level_bounds + level_size - consts.VP/2
            ))

            -- despawn entities when they stay off-screen for too much time
            local to_despawn = table.map(
                table.filter(self.entities, function (e)
                    return e.offscreen_start >= 400
                end),
                function (e) return e.id end
            )
            for _, id in ipairs(to_despawn) do
                self.entities[id] = nil
            end

            -- spawn new entities when they come inside the camera
            local new_entities = table.filter(
                self.data.entities,
                function (e)
                    return self.entities[e.id] == nil
                       and self.cam:is_inside(util.RecV(e.pos, vec.v2(e.width, e.height)))
                end
            )
            for _, e in ipairs(new_entities) do
                local entt = entity.create_entity(e)
                self.entities[e.id] = entt
                if entt.body ~= nil then
                    physics.register_body(entt.body)
                end
            end

            for _, e in pairs(self.entities) do
                e:update(dt)
                if self:check_player_bounds(e:get_hitbox()) then
                    local res = e:player_collision(self.player:position())
                    if res == "game-over" then
                        self.do_game_over = true
                    elseif res == "level-completed" then
                        self.do_level_completed = true
                    end
                end
                if self.cam:is_inside(e:get_draw_box()) then
                    e.offscreen_start = -1
                else
                    e.offscreen_start = e.offscreen_start + 1
                end
            end

            physics.check_collisions(self.data.ground, physics.bodies, dt)
        end,

        check_game_over = function (self)
            if not self:check_player_bounds(self.level_bounds) then
                self.do_game_over = true
                return
            end
        end,

        check_player_bounds = function (self, bounds)
            return rl.CheckCollisionCircleRec(self.player:position(), self.player.body.radius, bounds)
        end,

        draw_at = function (self, grid, x, y)
            local tile_info = grid[y][x]
            if tile_info == nil then
                return
            end
            local texture = self.data.textures[tile_info.gid]
            if texture == nil then
                error(util.pystr("trying to draw tex id =", tile_info.gid, "at pos = (", x, y, ")"))
            end
            local y_offset = texture.height / 32 - 1
            rl.DrawTextureRec(
                texture,
                util.Rec(0, 0, texture.width  * tile_info.flip_horz,
                               texture.height * tile_info.flip_vert),
                vec.v2(x, y - y_offset) * 32,
                rl.WHITE
            )
        end,

        draw_hud = function (self, dt)
           rl.DrawRectangle(0, 0, consts.VP_WIDTH, 50, rl.BLACK)

           -- player torch status
           local torch_bar_length = consts.VP_WIDTH / 3
           local text = "TORCH [T] "
           local text_height = 18
           local text_width = rl.MeasureText(text, text_height)
           rl.DrawText(text,
               10,
               10,
               text_height,
               rl.WHITE
           )
           local bar_x = 20 + text_width
           rl.DrawRectangleLines(bar_x, 10, torch_bar_length, text_height, rl.WHITE)
           rl.DrawRectangle(bar_x, 10, torch_bar_length * (self.player.torch_battery/100.0), text_height, rl.WHITE)
        end,

        draw_simple_grid = function (self, grid)
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
        end,

        draw = function (self)
            rl.ClearBackground(self.bg_color)

            rl.BeginMode2D(self.cam:get())
            self:draw_simple_grid(self.data.decor)
            self.player:draw(dt)
            self:draw_simple_grid(self.data.ground)

            for _, e in pairs(self.entities) do
                if self.cam:is_inside(e:get_draw_box()) then
                    e:draw()
                    if self.debug_mode then
                        e:draw_debug()
                    end
                end
            end
            rl.EndMode2D()

            self:draw_hud(dt)
        end,

        should_change = function (self)
            if self.do_game_over then
                return { name = "gameover" }
            elseif self.do_level_completed then
                return { name = "levelcompleted" }
            end
            return nil
        end
    }
end

return level_scene
