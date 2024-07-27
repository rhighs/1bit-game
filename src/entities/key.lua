local key = {}

local util = require "util"
local vec = require "vec"
local textures = require "textures"

function key.new(world, spawn_pos, ...)
    local entity = {
        pos = spawn_pos,
        world = world,
        keepalive = true
    }

    function entity:update(dt)
    end

    function entity:draw()
        rl.DrawTextureV(textures.key, self.pos, rl.WHITE)
    end

    function entity:get_draw_box()
        return util.RecV(self.pos, vec.v2(32, 32))
    end

    function entity:get_hitbox()
        return util.RecV(self.pos, vec.v2(32, 32))
    end

    function entity:player_collision(pos)
        self.world.entities_queue:send({
            type = "key-got"
        })
        self.world:despawn(self, true)
    end

    return entity
end

return key

