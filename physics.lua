local util = require 'util'
local vec = require "vec"

local AIR_RESISTANCE_COEFF = 5

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
            if self.grounded and self.velocity.y >= 0 then
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

function resolve_body_collisions(body, static_bodies)
    local ct = vec.floor(body.position / 32)

    local ground_tile = table.find(static_bodies, function(tile) return tile.x == ct.x and tile.y == (ct.y + 1) end)
    body.grounded = ground_tile ~= nil
    if body.grounded then
        body.position.y = (ground_tile.y * 32) - body.radius
    end

    local top_tile = table.find(static_bodies, function(tile) return tile.x == ct.x and tile.y == (ct.y - 1) end)
    if top_tile ~= nil then
        body.position.y = (top_tile.y * 32 + 32) + body.radius
        if body.velocity.y < 0 then
            body.velocity.y = 0 
        end
    end

    local left_tile = table.find(static_bodies, function(tile) return tile.x == (ct.x - 1) and tile.y == ct.y end)
    if left_tile ~= nil then
        body.position.x = (left_tile.x * 32 + 32) + body.radius
        body.velocity.x = 0
    end

    local right_tile = table.find(static_bodies, function(tile) return tile.x == (ct.x + 1) and tile.y == ct.y end)
    if right_tile ~= nil then
        body.position.x = (right_tile.x * 32) - body.radius
        body.velocity.x = 0
    end
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
            end
        end

        resolve_body_collisions(body, static_bodies)
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
