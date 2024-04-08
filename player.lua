local color = require("color")
local util = require("util")

local player = {}

function draw(self, dt)
    local x, y = self.body.position.x, self.body.position.y
    rl.DrawCircle(x, y, 10, color.COLOR_PRIMARY)
end

function update(self, dt)
    local velocity = self.speed * dt
    local x_dir, y_dir = 0, 0
    if rl.IsKeyDown(rl.KEY_W) then y_dir = y_dir - 1 end
    if rl.IsKeyDown(rl.KEY_S) then y_dir = y_dir + 1 end
    if rl.IsKeyDown(rl.KEY_A) then x_dir = x_dir - 1 end
    if rl.IsKeyDown(rl.KEY_D) then x_dir = x_dir + 1 end
    local v = util.Vec2(x_dir * velocity, y_dir * velocity)

    if rl.IsKeyDown(rl.KEY_SPACE) and self.body.isGrounded == true then
        rl.PhysicsAddForce(self.body, {0, -60.0})
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
        body = rl.CreatePhysicsBodyCircle(player_position, 10, 0.3)
    }
    obj.draw = draw
    obj.update = update
    obj.wrap_y = wrap_y
    return obj
end

return player
