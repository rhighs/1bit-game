local color = require("color")
local util = require('util')
local vec = require("vec")
local physics = require("physics")

local ghost = {}

local GHOST_BODY_DENSITY = 1.0
local GHOST_RADIUS = 10

function ghost.new(spawn_position)
    local obj = {
        speed = 150,
        body = physics.new_circle(spawn_position, GHOST_RADIUS, GHOST_BODY_DENSITY),
        dir = 1,
        target = vec.v2(0, 0),
    }

    obj.draw = function (self, dt)
        local x, y = self.body.position.x, self.body.position.y
        rl.DrawCircle(x, y, GHOST_RADIUS, color.COLOR_POSITIVE)
    end

    obj.update = function (self, dt)
        local speed = self.speed
        local x_dir, y_dir = 0, 0
        local dir_vec = self:compute_direction(dt)
        local v = dir_vec * speed
        self.body.velocity.x = v.x
    end

    obj.set_target = function (self, target)
        self.target = target
    end

    obj.compute_direction = function (self, dt)
        local dir_vec = rl.Vector2Normalize(self.target - self.body.position)
        return vec.v2(dir_vec.x, 0)
    end

    return obj
end

return ghost
