local ball = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"
local textures = require "textures"

local entity = {}

function entity:update(dt)
    self.body:update(dt)
    return self['state_' .. self.state](self, dt)
end

function entity:state_pendulum(dt)
    local force = physics.GRAVITY.y * math.sin(self.angle)
    local accel = -force / self.radius
    self.w = self.w + accel * dt
    self.angle = self.angle + self.w * dt
    self.bob_pos = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.radius

    -- if self.angle < -math.pi/4 then
    --     self.state = "throw"
    --     local v = self.pivot_pos - self.bob_pos
    --     local norm = vec.normalize(vec.rotate(v, -math.pi/2))
    --     self.body.position = self.bob_pos
    --     self.body.velocity = vec.zero()
    --     self.body:apply_force(norm * 1000)
    -- end
end

function entity:state_throw(dt)
    self.angle = self.angle - 0.04
end

function entity:draw()
    if self.state == "throw" then
        rl.DrawTexturePro(
            textures.chain_ball,
            util.Rec(0, 0, 55, 50),
            util.RecV(self.body.position, vec.v2(55, 50)),
            vec.v2(55/2, 50/2),
            math.deg(self.angle),
            rl.WHITE
        )
    else
        rl.DrawTexturePro(
            textures.chain_ball,
            util.Rec(0, 0, 55, 50),
            util.RecV(self.bob_pos, vec.v2(55, 50)),
            vec.v2(55/2, 50/2),
            math.deg(self.angle),
            rl.WHITE
        )
        rl.DrawTexturePro(
            textures.arm,
            util.Rec(0, 0, 32, 64),
            util.RecV(self.pivot_pos, vec.v2(32, 64)),
            vec.v2(16, 0),
            math.deg(-self.angle),
            rl.WHITE
        )
        -- d = distance between bottom of arm and top of ball
        -- num_of_chains = d/32?
        local d = self.bob_pos.y - 16 - self.pivot_pos.y + 64
        print(d)
        rl.DrawLineV(self.pivot_pos, self.bob_pos, rl.RED)
        rl.DrawCircleV(self.bob_pos, 16, rl.RED)
    end
end

function entity:get_draw_box()
    return util.Rec(self.bob_pos.x, self.bob_pos.y, 32, 5*32)
end

function entity:get_hitbox()
    return util.Rec(0, 0, 1, 1)
end

function entity:player_collision(pos)
end

entity.has_physics_body = true

function ball.new(spawn_pos, ...)
    entity.__index = entity
    local body = physics.new_circle(vec.zero(), 16, 1/10000)
    body.air_resistance_enabled = false

    body.collision_resolver = function (body, tiles)
        -- going down?
        if body.old_pos.y >= body.position.y then
            return
        end
        body.locked_ys = body.locked_ys or {}
        local tile = table.foldl(
            table.filter(tiles, function (v)
                return body.locked_ys[v.y] == nil
            end),
            vec.v2(0, math.huge), function (t, u)
                return t.y < u.y and t or u
            end
        )
        if tile.y == math.huge then
            return
        end
        body.velocity.y = -300
        body.locked_ys[tile.y] = true
    end

    return setmetatable({
        pivot_pos = spawn_pos,
        bob_pos = spawn_pos + vec.v2(0, 4 * 32),
        w = 2.5,
        angle = 0,
        radius = 128,
        state = "pendulum",
        body = body,
    }, entity)
end

return ball

