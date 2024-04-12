local util = require('util')
local vec = require("vec")

local DEFAULT_GRAVITY = vec.v2(0.0, 9.8)
local AIR_RESISTANCE_COEFF = 1

local physics = {}
physics.GRAVITY = vec.v2(0, 1000)

function physics.new_circle(pos, r, density)
    local obj = {
        radius = r,
        position = pos,
        velocity = vec.zero(),
        acceleration = vec.zero(),
        gravity = DEFAULT_GRAVITY,
        force = vec.zero(),
        colliders = {},

        density = density,
        mass = density * (math.pi * math.pow(r, 2)),

        position_update = function (self, dt)
            if self.position.y >= 400 then
                self.position.y = 400
                self.acceleration.y = 0
                self.grounded = true
            else
                self.grounded = false
            end

            local speed = rl.Vector2Length(self.velocity)
            local air_resistance_force = -(AIR_RESISTANCE_COEFF * (math.pow(speed, 2) * rl.Vector2Normalize(self.velocity)))/2
            self:apply_force(air_resistance_force)

            -- apply forces
            local acceleration = self.acceleration + self.gravity + (self.force / self.mass)

            -- update positions
            self.velocity = self.velocity + (acceleration * dt)
            local position = self.position + (self.velocity * dt)
            self.position = position

            self.force = vec.zero()
        end,

        update = function (self, dt)
            self:position_update(dt)
        end,

        apply_force = function (self, force)  self.force = self.force + force end,
    }

    return obj
end

function physics.update_physics(bodies, dt)
    for _, body in ipairs(bodies) do
        body.gravity = physics.GRAVITY
        body:update(dt)
    end

    for i, first_body in ipairs(bodies) do
        first_body.colliders = {}
        for j=i+1,#bodies do
            local second_body = bodies[j]
            local colliding = rl.CheckCollisionCircles(
            first_body.position, first_body.radius,
            second_body.position, second_body.radius
            )

            if colliding then
                table.insert(first_body.colliders, second_body)
            end
        end
    end
end

return physics
