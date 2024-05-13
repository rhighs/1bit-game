local util = require 'util'
local vec = require "vec"

local physics = {}
physics.METER_UNIT = 32
physics.GRAVITY = vec.v2(0, 2 * 9.8 * physics.METER_UNIT)
physics.AIR_RESISTANCE_COEFF = 2

physics.bodies = {}

function physics.register_body(body)
    table.insert(physics.bodies, body)
end

function physics.unregister_body(body)
    for i, b in ipairs(table) do
        if b == body then
            table.remove(physics.bodies, i)
        end
    end
end

function physics.check_collisions(grid, bodies, dt)
    for i, body in ipairs(bodies) do
        local tiles = occupied_tiles(body.position, body.radius)
        local static_bodies = {}
        for _, tile in ipairs(tiles) do
            local rec = util.Rec(tile.x * 32, tile.y * 32, 32, 32)
            local collides = rl.CheckCollisionCircleRec(body.position, body.radius, rec)
            if grid[tile.y] ~= nil and grid[tile.y][tile.x] ~= nil and collides then
                table.insert(static_bodies, { pos = tile, info = grid[tile.y][tile.x] })
            end
        end

        body:resolve_static_collisions(static_bodies)
    end

    for i, first_body in ipairs(bodies) do
        local rigid_body_collisions = {}
        for j = i + 1, #bodies do
            local second_body = bodies[j]
            if check_body_collision(first_body, second_body) then
                table.insert(rigid_body_collisions, second_body)
            end
        end

        first_body.colliders = rigid_body_collisions
        first_body:resolve_rigid_collisions(rigid_body_collisions)
    end
end

local physics_body = {}

function physics_body:resolve_static_collisions(static_bodies)
    self.static_collision_resolver(self, static_bodies)
end

function physics_body:resolve_rigid_collisions(rigid_bodies)
    self.rigid_collision_resolver(self, rigid_bodies)
end

function physics_body:position_update(dt)
    if self.air_resistance_enabled then
        local speed = vec.length(self.velocity)
        local opposing_vector = -(math.pow(speed, 2) * vec.normalize(self.velocity))
        local air_resistance_force = (physics.AIR_RESISTANCE_COEFF * opposing_vector) / 2
        air_resistance_force.y = 0
        self:apply_force(air_resistance_force * 10)
    end

    -- update positions
    local acceleration = self.force/self.mass
    self.velocity = self.velocity + acceleration * dt
    if self.gravity_enabled then
        self.velocity = self.velocity + (self.gravity * dt)
    end

    local position = self.position + (self.velocity * dt)
    self.position = position

    self.force = vec.zero()
end

function physics_body:update(dt)
    if self.grounded and self.velocity.y >= 0 then
        self.velocity.y = 0
    end
    self:position_update(dt)
end

function new_body(position, mass)
    physics_body.__index = physics_body
    return setmetatable({
        radius = r,
        position = position,
        velocity = vec.zero(),
        gravity = physics.GRAVITY,
        gravity_enabled = true,
        air_resistance_enabled = true,
        force = vec.zero(),
        grounded = false,
        colliders = {},
        mass = mass,
        shape_type = nil,
        reset_forces = function (self) self.force = 0 end,
        apply_force = function(self, force) self.force = self.force + force end,
    }, physics_body)
end

function physics.new_circle(position, r, density)
    local body = new_body(position, math.pi * r * r * density)
    body.__shape = "circle"
    body.radius = r
    body.static_collision_resolver = circle_static_collision_resolver
    body.rigid_collision_resolver = circle_rigid_collision_resolver
    return body
end

function physics.new_rectangle(position, width, height, density)
    local body = new_body(position, width * height * density)
    body.__shape = "rectangle"
    body.width = width
    body.height = width
    body.static_collision_resolver = rectangle_static_collision_resolver
    body.rigid_collision_resolver = rectangle_rigid_collision_resolver
    return result
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

function check_body_collision(first_body, second_body)
    if first_body.__shape == "circle" then
        if second_body.__shape == "circle" then
            return rl.CheckCollisionCircles(
                first_body.position, first_body.radius,
                second_body.position, second_body.radius
            )
        elseif second_body.__shape == "rectangle" then
            return rl.CheckCollisionCircleRec(
                first_body.position, first_body.radius,
                util.Rec(
                    second_body.position.x,
                    second_body.position.y,
                    second_body.width,
                    second_body.height
                )
            )
        end
    elseif first_body.__shape == "rectangle" then
        if second_body.__shape == "circle" then
            return rl.CheckCollisionCircles(
                util.Rec(
                    first_body.position.x,
                    first_body.position.y,
                    first_body.width,
                    first_body.height
                ),
                util.Rec(
                    second_body.position.x,
                    second_body.position.y,
                    second_body.width,
                    second_body.height
                )
            )
        elseif second_body.__shape == "rectangle" then
            return rl.CheckCollisionCircleRec(
                second_body.position, second_body.radius,
                util.Rec(
                    first_body.position.x,
                    first_body.position.y,
                    first_body.width,
                    first_body.height
                )
            )
        end
    end
end

function circle_static_collision_resolver(body, static_bodies)
    local ct = vec.floor(body.position / 32)

    local ground_tile = table.find(static_bodies, function(tile)
        return tile.pos.x == ct.x and tile.pos.y == ct.y + 1
    end)
    body.grounded = ground_tile ~= nil
    if body.grounded then
        body.position.y = (ground_tile.pos.y * 32) - body.radius
    end

    local top_tile = table.find(static_bodies, function(tile)
        return tile.pos.x == ct.x and tile.pos.y == ct.y - 1
    end)
    if top_tile ~= nil then
        body.position.y = (top_tile.pos.y * 32 + 32) + body.radius
        if body.velocity.y < 0 then
            body.velocity.y = 0
        end
    end

    local left_tile = table.find(static_bodies, function(tile)
        return tile.pos.x == ct.x - 1 and tile.pos.y == ct.y
    end)
    if left_tile ~= nil then
        body.position.x = (left_tile.pos.x * 32 + 32) + body.radius
        body.velocity.x = 0
    end

    local right_tile = table.find(static_bodies, function(tile)
        return tile.pos.x == ct.x + 1 and tile.pos.y == ct.y
    end)
    if right_tile ~= nil then
        body.position.x = (right_tile.pos.x * 32) - body.radius
        body.velocity.x = 0
    end
end

function circle_rigid_collision_resolver(body, rigid_bodies) end
function rectangle_static_collision_resolver(body, static_bodies) end
function rectangle_rigid_collision_resolver(body, rigid_bodies) end

return physics
