local util = require('util')
local vec = require("vec")
local table_utils = require("table_utils")

local AIR_RESISTANCE_COEFF = 1

local physics = {}
physics.METER_UNIT = 32
physics.GRAVITY = vec.v2(0, 2 * 9.8 * physics.METER_UNIT)

function physics.new_circle(pos, r, density)
    local obj = {
        radius = r,
        position = pos,
        velocity = vec.zero(),
        gravity = physics.GRAVITY,
        acceleration = vec.zero(),
        force = vec.zero(),
        grounded = false,
        colliders = {},

        density = density,
        mass = density * (math.pi * math.pow(r, 2)),

        position_update = function(self, dt)
            -- apply air resistance force
            local speed = vec.length(self.velocity)
            local opposing_vector = -(math.pow(speed, 2) * vec.normalize(self.velocity))
            local air_resistance_force = (AIR_RESISTANCE_COEFF * opposing_vector) / 2
            air_resistance_force.y = 0
            self:apply_force(air_resistance_force * 10)

            local acceleration_from_force = (self.force / self.mass)
            -- update positions
            self.velocity = self.velocity + (self.acceleration * dt) + (self.gravity * dt) + (acceleration_from_force * dt)
            local position = self.position + (self.velocity * dt)
            self.position = position

            self.force = vec.zero()
        end,

        update = function(self, dt)
            self:position_update(dt)
            if self.grounded and self.velocity.y >= 0 then
                self.velocity.y = 0
            end
        end,

        apply_force = function(self, force) self.force = self.force + force end,
    }

    return obj
end

function occupied_tiles(position, radius)
    local top_right = vec.v2(position.x + radius, position.y - radius)
    local top_left = position - vec.v2(radius, radius)
    local bottom_left = vec.v2(position.x - radius, position.y + radius)
    local bottom_right = position + vec.v2(radius, radius)
    return {
        vec.floor(top_right / 32),
        vec.floor(top_left / 32),
        vec.floor(bottom_left / 32),
        vec.floor(bottom_right / 32),
    }
end

function is_grounded(position, static_bodies)
    local current_tile = vec.floor(position / 32)
    local result = table_utils.contains(
        static_bodies,
        function(tile) return tile.x == current_tile.x and tile.y == (current_tile.y + 1) end
    )
    return result
end

function physics.update_physics(grid, bodies, dt)
    for i, body in ipairs(bodies) do
        body.gravity = physics.GRAVITY 

        local old_position = body.position
        body:update(dt)
        local new_position = body.position
        local tiles = occupied_tiles(body.position, body.radius)

        local static_bodies = {}
        for _, tile in ipairs(tiles) do
            local rec = util.Rec(tile.x * 32, tile.y * 32, 32, 32)
            local collides = rl.CheckCollisionCircleRec(body.position, body.radius, rec)
            if grid[tile.y] ~= nil and grid[tile.y][tile.x] ~= nil and collides then
                table.insert(static_bodies, tile)
                rl.DrawRectangle(tile.x * 32, tile.y * 32, 32, 32, rl.GREEN)
            end
        end

        body.grounded = is_grounded(body.position, static_bodies)
        if body.grounded then
            body.position.y = old_position.y
        end
    end

    for i, first_body in ipairs(bodies) do
        first_body.colliders = {}
        for j = i + 1, #bodies do
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
