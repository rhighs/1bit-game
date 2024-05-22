local util = require "util"
local world = require "world"
local physics = require "physics"

local level_scene = {}

function level_scene.new(scene_queue)
    return {
        name = "level",
        -- bg_color = rl.BLACK,
        -- do_game_over = false,
        -- do_level_completed = false,
        world = nil,

        init = function (self, data)
            -- self.do_game_over = false
            -- self.do_level_completed = false
            self.world = world.new(loader.load_level(require(data.level)), scene_queue)
        end,

        destroy = function (self) physics.clear() end,

        -- color_swap = cooldown.make_cooled(function (self)
        --     self.bg_color = self.bg_color == rl.WHITE and rl.BLACK or rl.WHITE
        -- end, 0.2),

        update = function(self, dt)
            self.world:update(dt)
        end,

        draw = function (self)
            self.world:draw()
        end,

        -- should_change = function (self)
        --     if self.do_game_over then
        --         return { name = "gameover" }
        --     elseif self.do_level_completed then
        --         return { name = "levelcompleted" }
        --     end
        --     return nil
        -- end
    }
end

return level_scene
