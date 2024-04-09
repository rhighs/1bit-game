local color = require("color")
local util = require('util')

local ghost = {}

local GHOST_BODY_DENSITY = 0.1
local GHOST_WIDTH, GHOST_HEIGHT = 20, 20

function ghost.new(spawn_position)
    local obj = {
        velocity = 10,
        dir = 1,
        target = util.Vec2(0, 0),
        body = rl.CreatePhysicsBodyRectangle(spawn_position, GHOST_WIDTH, GHOST_HEIGHT, GHOST_BODY_DENSITY)
    }

    obj.draw = function (self, dt)
        local x, y = self.body.position.x, self.body.position.y
        rl.DrawRectangle(x-(GHOST_WIDTH/2), y-(GHOST_HEIGHT/2), GHOST_WIDTH, GHOST_HEIGHT, color.COLOR_PRIMARY)
    end

    obj.update = function (self, dt)
        local velocity = self.velocity * dt
        local x_dir, y_dir = 0, 0
        local dir_vec = self:compute_direction(dt)
        local v = dir_vec * velocity

        self.body.velocity.x = v.x
        self.body.velocity.y = math.min(self.body.velocity.y, 1)
    end

    obj.set_target = function (self, target)
        self.target = target
    end

    obj.compute_direction = function (self, dt)
        local dir_vec = rl.Vector2Normalize(self.target - self.body.position)
        return util.Vec2(dir_vec.x, 0)
    end

    return obj
end

return ghost
