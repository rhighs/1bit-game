local util = require "util"
local vec = require "vec"
local physics = require "physics"

local player = {}

local PLAYER_SPEED = 2
local PLAYER_BODY_DENSITY = 1
local PLAYER_BODY_RADIUS = 10
local PLAYER_JUMP_HEIGHT = physics.METER_UNIT * 3

function player.new(player_position)
    local obj = {
        speed = physics.METER_UNIT * 10,
        body = physics.new_circle(player_position, PLAYER_BODY_RADIUS, PLAYER_BODY_DENSITY)
    }

    obj.draw = function(self, dt)
        local x, y = self.body.position.x, self.body.position.y
        rl.DrawCircle(x, y, PLAYER_BODY_RADIUS, rl.WHITE)
    end

    obj.handle_movement = function(self, dt)
        local x_dir, y_dir = 0, 0
        -- if rl.IsKeyDown(rl.KEY_W) then y_dir = y_dir - 1 end
        if rl.IsKeyDown(rl.KEY_S) then y_dir = y_dir + 1 end
        if rl.IsKeyDown(rl.KEY_A) then x_dir = x_dir - 1 end
        if rl.IsKeyDown(rl.KEY_D) then x_dir = x_dir + 1 end
        if x_dir ~= 0 or y_dir ~= 0 then
            local v = vec.v2(x_dir * self.speed, y_dir * self.speed)
            self.body.velocity.x = v.x
        end

        local should_jump = rl.IsKeyDown(rl.KEY_W) or rl.IsKeyDown(rl.KEY_SPACE)
        if should_jump and self.body.grounded then
            self:jump()
        end
    end

    obj.jump = function(self)
        self.body.velocity.y = -math.sqrt(self.body.gravity.y * 2 * PLAYER_JUMP_HEIGHT)
    end

    obj.update = function(self, dt)
        self:handle_movement(dt)
        self:collisions_update(dt)
    end

    obj.collisions_update = function(self)
        local n_colliding = #(self.body.colliders)
        if #(self.body.colliders) > 0 then
        end
    end

    obj.position = function(self)
        return self.body.position
    end

    return obj
end

return player
