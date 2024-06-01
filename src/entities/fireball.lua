local physics = require "physics"
local textures = require "textures"
local vec = require "vec"
local util = require "util"

local fireball = {}

function fireball.new(world, spawn_pos, _w, _h, data)
    local fireball = {
        world = world,
        body = physics.new_circle(vec.zero(), 16, 1/10000),
    }

    fireball.body.position = spawn_pos
    fireball.body.velocity = vec.zero()
    fireball.body.air_resistance_enabled = false
    fireball.body.static_collision_resolver = function () return false end
    fireball.body.dynamic_collision_resolver = nil

    fireball.body:apply_force(data.init_force)

    function fireball:update(dt)
        self.body:update(dt)
    end

    function fireball:draw()
        rl.DrawTextureRec(
            textures.fireball,
            util.Rec(0, 0, 32, 32),
            self.body.position,
            rl.WHITE
        )
    end

    function fireball:get_draw_box()
        return util.RecV(self.body.position, vec.v2(32, 32))
    end

    function fireball:get_hitbox()
        return util.RecV(self.body.position, vec.v2(32, 32))
    end

    function fireball:player_collision(pos)
        self.world:send_scene_event("gameover")
    end

    return fireball
end

return fireball

