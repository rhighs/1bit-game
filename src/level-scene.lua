local util = require "util"
local world = require "world"
local physics = require "physics"

local level_scene = {}

function level_scene.new(scene_queue)
    return {
        name = "level",
        world = nil,

        init = function (self, data)
            self.world = world.new(
                loader.load_level(require(data.level)),
                scene_queue,
                data.from_warp
            )
            self.world:set_palette(rl.BLACK, rl.WHITE)
        end,

        destroy = function (self) physics.clear() end,

        update = function(self, dt)
            self.world:update(dt)
        end,

        draw = function (self)
            self.world:draw()
        end,
    }
end

return level_scene
