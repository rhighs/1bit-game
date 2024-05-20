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

function physics.clear() physics.bodies = {} end

function physics.check_collisions(grid, bodies, dt)
    for i, body in ipairs(bodies) do
        if body.static_collisions_enabled then
            local tiles = occupied_tiles(body.position, body.radius)
            local static_bodies = {}
            for _, tile in ipairs(tiles) do
                local rec = util.Rec(tile.x * 32, tile.y * 32, 32, 32)
                local collides = rl.CheckCollisionCircleRec(body.position, body.radius, rec)
                if grid[tile.y] ~= nil and grid[tile.y][tile.x] ~= nil and collides then
                    table.insert(static_bodies, { pos = tile, info = grid[tile.y][tile.x] })
                end

                body:resolve_static_collisions(static_bodies)
            end
        end
    end

    for i, first_body in ipairs(bodies) do
        local dynamic_body_collisions = {}
        for j, second_body in ipairs(bodies) do
            if i ~= j then
                local second_body = bodies[j]
                local collding = check_body_collision(first_body, second_body)
                if collding then
                    table.insert(dynamic_body_collisions, second_body)
                end
            end
        end

        first_body.colliders = dynamic_body_collisions
        first_body:resolve_dynamic_collisions(dynamic_body_collisions)
    end
end

local physics_body = {}

function physics_body:resolve_static_collisions(static_bodies)
    self.static_collision_resolver(self, static_bodies)
end

function physics_body:resolve_dynamic_collisions(dynamic_bodies)
    self.dynamic_collision_resolver(self, dynamic_bodies)
end

function physics_body:update(dt)
    function consume_velocity(velocity, dt)
        local acceleration = self.force/self.mass
        if self.air_resistance_enabled then
            local speed = vec.length(self.velocity)
            local opposing_vector = -(math.pow(speed, 2) * vec.normalize(velocity))
            local air_resistance_force = (physics.AIR_RESISTANCE_COEFF * opposing_vector) / 2
            air_resistance_force.y = 0
            acceleration = acceleration + (air_resistance_force * 10 / self.mass)
        end
    
        -- update positions
        velocity = velocity + acceleration * dt
        return velocity
    end

    -- rob: avoid being rocketed downward when a platform you just dropeed off is descending
    if not self.on_platform and self.platform_velocity.y >= 0 then
        self.platform_velocity.y = 0
    end

    if self.grounded and self.velocity.y >= 0 then
        self.velocity.y = 0
        self.platform_velocity.y = 0
    end

    self.velocity = consume_velocity(self.velocity, dt)
    if self.gravity_enabled and not self.on_platform then
        self.velocity = self.velocity + (self.gravity * dt)
    end

    self.platform_velocity = consume_velocity(self.platform_velocity, dt)

    self.old_pos = self.position
    self.position = self.position + (self.velocity * dt) + (self.platform_velocity * dt)

    self.force = vec.zero()
end

function new_body(position, mass)
    physics_body.__index = physics_body
    return setmetatable({
        radius = r,
        old_pos = position,
        position = position,
        velocity = vec.zero(),
        gravity = physics.GRAVITY,
        gravity_enabled = true,
        air_resistance_enabled = true,
        force = vec.zero(),
        grounded = false,
        colliders = {},
        mass = mass,
        friction = 1.0,
        shape_type = nil,
        reset_forces = function (self) self.force = 0 end,
        apply_force = function(self, force) self.force = self.force + force end,
        on_platform = false,
        platform_velocity = vec.zero(),
        static_collisions_enabled = true,
        dynamic_collisions_enabled = true,
    }, physics_body)
end

function physics.new_circle(position, r, density)
    local body = new_body(position, math.pi * r * r * density)
    body.__shape = "circle"
    body.radius = r
    body.static_collision_resolver = circle_static_collision_resolver
    body.dynamic_collision_resolver = circle_dynamic_collision_resolver
    return body
end

function physics.new_rectangle(position, width, height, density)
    local body = new_body(position, width * height * density)
    body.__shape = "rectangle"
    body.width = width
    body.height = height
    body.static_collision_resolver = rectangle_static_collision_resolver
    body.dynamic_collision_resolver = rectangle_dynamic_collision_resolver
    return body
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
            return rl.CheckCollisionCircleRec(
                second_body.position, second_body.radius,
                util.Rec(
                    first_body.position.x,
                    first_body.position.y,
                    first_body.width,
                    first_body.height
                )
            )
        elseif second_body.__shape == "rectangle" then
            return rl.CheckCollisionRecs(
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

function circle_dynamic_collision_resolver(body, dynamic_bodies)
    local rectangles = table.filter(dynamic_bodies, function(r) return r.__shape == "rectangle" end)
    local should_recompute = #rectangles > 0

    function poll_body(callable)
        local part1, part2 = table.partition(rectangles, callable)
        rectangles = part1
        return part2[1]
    end

    local bottom_body = poll_body(function(r) return r.position.y > body.position.y end)
    body.on_platform = bottom_body ~= nil 
    if body.on_platform then
        body.platform_velocity = bottom_body.velocity
        body.position.y = bottom_body.position.y - body.radius
    end

    local top_body = poll_body(function(r)
        return r.position.y < body.position.y
            and body.position.x >= r.position.x
            and body.position.x <= r.position.x + r.width
        end)
    if top_body ~= nil then
        body.position.y = top_body.position.y + top_body.height + body.radius
        if body.velocity.y < 0 then
            body.velocity.y = 0
        end
    end

    local left_body = poll_body(function(r)
        return r.position.x < body.position.x
            and r.position.x + r.width < body.position.x
        end)
    if left_body ~= nil then
        body.position.x = left_body.position.x + left_body.width + body.radius
        body.velocity.x = 0
    end

    local right_body = poll_body(function(r) return r.position.x > body.position.x end)
    if right_body ~= nil then
        body.position.x = right_body.position.x - body.radius
        body.velocity.x = 0
    end

    -- ideally, calculate collisions again if the above changed body.position
    -- if should_recompute then
    --     any collision?
    -- end
    -- local circles = table.filter(dynamic_bodies, function(r) return r.__shape == "circle" end)
end

function rectangle_static_collision_resolver(body, static_bodies) end
function rectangle_dynamic_collision_resolver(body, dynamic_bodies) end

return physics
