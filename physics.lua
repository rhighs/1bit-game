local util = require('util')
local vec = require("vec")

local DEFAULT_GRAVITY = vec.v2(0.0, 9.8)
local AIR_RESISTANCE_COEFF = 1

local physics = {}

-- function physics.new_rectangle(pos, w, h, density)
--     local obj = {
--         width = width, 
--         height = height,
--         position = pos,
--         velocity = vec.zero(),
--         acceleration = vec.zero(),
--         gravity = DEFAULT_GRAVITY,
-- 
--         density = density,
--         mass = density * ((width * height)),
-- 
--         update = function (self, dt)
--             self.position = self:new_pos(dt)
--         end,
-- 
--         new_pos = function (self, dt)
--             local pos = self.position + (self.velocity * dt)
--             self.velocity = self.velocity + ((self.acceleration + self.gravity) * dt)
--             return pos
--         end,
-- 
--         apply_force = function (self, force) self.acceleration = self.acceleration + (force / self.mass) end,
--     }
-- 
--     return obj
-- end

function physics.new_circle(pos, r, density)
    local obj = {
        radius = r,
        position = pos,
        velocity = vec.zero(),
        acceleration = vec.zero(),
        gravity = DEFAULT_GRAVITY,
        force = vec.zero(),

        density = density,
        mass = density * (math.pi * math.pow(r, 2)),

        update = function (self, dt)
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

            print(acceleration)

            -- update positions
            self.velocity = self.velocity + (acceleration * dt)
            local position = self.position + (self.velocity * dt)
            self.position = position

            self.force = vec.zero()
        end,

        apply_force = function (self, force)  self.force = self.force + force end,
    }

    return obj
end

function physics.new(gravity)
    local obj = {
        bodies = {},
        gravity = gravity or DEFAULT_GRAVITY,

        update = function (self, dt)
            for _, body in ipairs(self.bodies) do
                body:update(dt)
            end
        end,

        add = function (self, body)
            body.gravity = self.gravity
            self.bodies[#self.bodies + 1] = body
        end,
    }

    return obj
end

return physics
