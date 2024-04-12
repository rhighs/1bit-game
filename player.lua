local color = require("color")
local util = require("util")
local vec = require("vec")
local physics = require("physics")

local player = {}

local PLAYER_SPEED = 2
local PLAYER_BODY_DENSITY = 1
local PLAYER_BODY_RADIUS = 10

function player.new(player_position)
    local obj = {
        speed = 300,
        body = physics.new_circle(player_position, PLAYER_BODY_RADIUS, PLAYER_BODY_DENSITY)
    }

    obj.draw = function (self, dt)
        local x, y = self.body.position.x, self.body.position.y
        rl.DrawCircle(x, y, PLAYER_BODY_RADIUS, color.COLOR_PRIMARY)
    end

    obj.handle_movement = function (self, dt)
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
            self.body:apply_force(self.jump_force)
        end
    end

    obj.update = function (self, dt)
        self:handle_movement(dt)
        self:collisions_update(dt)
    end

    obj.collisions_update = function (self)
        local n_colliding = #(self.body.colliders)
        if #(self.body.colliders) > 0 then
            print("n colliding = " .. n_colliding)
        end
    end

    obj.wrap_y = function (self, min_y, max_y)
        local y = self.body.position.y
        y = y < min_y and max_y or (y > max_y and min_y or y)
        self.body.position.y = y
    end

    obj.position = function (self)
        return self.body.position
    end

    local mass = PLAYER_BODY_DENSITY * (math.pi * math.pow(PLAYER_BODY_RADIUS, 2))
    local down_force = mass * 100 * 70

    -- force is reset to (0, 0) each physics step, add just a little force to make the object jump
    -- here +20% is to be intended as the force required to counter gravity + 20% of that force
    obj.jump_force = vec.v2(0, -(down_force * 2))
    return obj
end

return player
