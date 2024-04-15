local util = require('util')
local vec = require("vec")
local table_utils = require("table_utils")

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
        grounded = false,
        colliders = {},

        density = density,
        mass = density * (math.pi * math.pow(r, 2)),

        position_update = function(self, dt)
            local speed = rl.Vector2Length(self.velocity)
            local air_resistance_force = -(AIR_RESISTANCE_COEFF * (math.pow(speed, 2) * rl.Vector2Normalize(self.velocity))) /
            2
            self:apply_force(air_resistance_force)

            -- apply forces
            local acceleration = self.acceleration + self.gravity + (self.force / self.mass)

            -- update positions
            self.velocity = self.velocity + (acceleration * dt)
            local position = self.position + (self.velocity * dt)
            self.position = position

            self.force = vec.zero()
        end,

        update = function(self, dt)
            if self.grounded then
                self.velocity.y = 0
            end

            self:position_update(dt)
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
        if i == 1 then
            local new_position = body.position
            local tiles = occupied_tiles(body.position, body.radius)

            local static_bodies = {}
            for _, tile in ipairs(tiles) do
                local rec = util.Rec(tile.x*32, tile.y*32, 32, 32)
                local collides = rl.CheckCollisionCircleRec(body.position, body.radius, rec)
                if grid[tile.y] ~= nil and grid[tile.y][tile.x] ~= nil and collides then
                    table.insert(static_bodies, tile)
                    rl.DrawRectangle(tile.x*32, tile.y*32, 32, 32, rl.GREEN)
                end
            end

            body.grounded = is_grounded(body.position, static_bodies) 
            if body.grounded then
                body.position.y = old_position.y
            end
        end
    end

    local player = bodies[1]

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
