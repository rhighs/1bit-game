local color = require("color")
local util = require("util")

local player = {}

local PLAYER_BODY_DENSITY = 0.1
local PLAYER_BODY_RADIUS = 10

function draw(self, dt)
    local x, y = self.body.position.x, self.body.position.y
    rl.DrawCircle(x, y, 10, color.COLOR_PRIMARY)
end

function update(self, dt)
    local velocity = self.speed * dt
    local x_dir, y_dir = 0, 0
    if rl.IsKeyDown(rl.KEY_S) then y_dir = y_dir + 1 end
    if rl.IsKeyDown(rl.KEY_A) then x_dir = x_dir - 1 end
    if rl.IsKeyDown(rl.KEY_D) then x_dir = x_dir + 1 end
    local v = util.Vec2(x_dir * velocity, y_dir * velocity)

    local should_jump = rl.IsKeyDown(rl.KEY_W) or rl.IsKeyDown(rl.KEY_SPACE)
    if should_jump and self.body.isGrounded then
        rl.PhysicsAddForce(self.body, self.jump_force)
    end

    self.body.velocity.x = self.body.velocity.x + v.x
    self.body.velocity.y = math.min(self.body.velocity.y + v.y, 1)
end

function wrap_y(self, min_y, max_y)
    local y = self.body.position.y
    y = y < min_y and max_y or (y > max_y and min_y or y)
    self.body.position.y = y
end

function player.new(player_position)
    local obj = {
        speed = 1,
        position = player_position,
        body = rl.CreatePhysicsBodyCircle(player_position, PLAYER_BODY_RADIUS, PLAYER_BODY_DENSITY)
        
    }
    local mass = PLAYER_BODY_DENSITY * (math.pi * math.pow(PLAYER_BODY_RADIUS, 2))
    local down_force = mass * 1.0
    obj.draw = draw
    obj.update = update
    obj.wrap_y = wrap_y

    -- force is reset to (0, 0) each physics step, add just a little force to make the object jump
    -- here +20% is to be intended as the force required to counter gravity + 20% of that force
    obj.jump_force = util.Vec2(0, -(down_force*0.20))
    return obj
end

return player
