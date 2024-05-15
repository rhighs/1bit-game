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
    self.w = self.w + accel * dt*10
    self.angle = self.angle + self.w * dt*10
    self.bob_pos = self.pivot_pos + vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.radius

    if self.angle < -math.pi/3 then
        self.state = "throw"
        self.arm_angle = self.angle
        self.time = 0
        local norm = vec.normalize(vec.rotate(self.pivot_pos - self.bob_pos, -math.pi/2))
        self.body.position = self.bob_pos
        self.body.velocity = vec.zero()
        self.body:apply_force(vec.v2(norm.x * 1000, norm.y * 2000))
        self.body.locked_ys = {}
    end
end

function entity:state_throw(dt)
    self.angle = self.angle - 0.04
    if self.angle > 2*math.pi then
        self.angle = 0
    end
    self.time = self.time + 1
    if self.time > 40 and self.arm_angle < 0 then
        self.arm_angle = self.arm_angle + 0.05
        if self.arm_angle >= 0 then
            self.arm_angle = 0
        end
    end
    if self.time > 200 then
        self.state = "pendulum"
        self.w = 3.5
        self.angle = 0
        self.body.position = vec.v2(0, 0)
        self.bob_pos = self.pivot_pos + vec.v2(0, 4 * 32)
    end
end

function entity:draw()
    local num_chains = math.ceil((self.radius - (64 - 16) - 25) / 16)
    if self.state == "throw" then
        for i = 1, num_chains+1 do
            local pos = vec.v2(-math.sin(self.angle), -math.cos(self.angle)) * ((i-1)*16)
            rl.DrawTexturePro(
                textures.chain,
                util.Rec(0, 0, 16, 16),
                util.RecV(self.body.position + pos, vec.v2(16, 16)),
                vec.v2(8, 16),
                math.deg(-self.angle),
                rl.WHITE
            )
        end
        rl.DrawTexturePro(
            textures.chain_ball,
            util.Rec(0, 0, 55, 50),
            util.RecV(self.body.position, vec.v2(55, 50)),
            vec.v2(55/2, 50/2),
            math.deg(-self.angle),
            rl.WHITE
        )
        rl.DrawTexturePro(
            textures.arm,
            util.Rec(32, 0, 32, 64),
            util.RecV(self.pivot_pos, vec.v2(32, 64)),
            vec.v2(16, 16),
            math.deg(-self.arm_angle),
            rl.WHITE
        )
    else
        rl.DrawTexturePro(
            textures.arm,
            util.Rec(0, 0, 32, 64),
            util.RecV(self.pivot_pos, vec.v2(32, 64)),
            vec.v2(16, 16),
            math.deg(-self.angle),
            rl.WHITE
        )
        for i = 1, num_chains do
            local pos = vec.v2(math.sin(self.angle), math.cos(self.angle)) * ((64 - 16) + (i-1)*16)
            rl.DrawTexturePro(
                textures.chain,
                util.Rec(0, 0, 16, 16),
                util.RecV(self.pivot_pos + pos, vec.v2(16, 16)),
                vec.v2(8, 0),
                math.deg(-self.angle),
                rl.WHITE
            )
        end
        rl.DrawTexturePro(
            textures.chain_ball,
            util.Rec(0, 0, 55, 50),
            util.RecV(self.bob_pos, vec.v2(55, 50)),
            vec.v2(55/2, 50/2),
            math.deg(-self.angle),
            rl.WHITE
        )
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
                return body.locked_ys[v.pos.y] == nil
            end),
            { pos = vec.v2(0, math.huge), info = nil },
            function (t, u)
                return t.pos.y < u.pos.y and t or u
            end
        )
        if tile.info == nil then
            return
        end
        if tile.info.gid ~= 4 or tile.info.flip_vert == -1 then
            return
        end
        body.velocity.y = -300
        body.locked_ys[tile.pos.y] = true
    end

    return setmetatable({
        pivot_pos = spawn_pos,
        bob_pos = spawn_pos + vec.v2(0, 4 * 32),
        w = 3.5,
        angle = 0,
        radius = 128,
        state = "pendulum",
        body = body,
    }, entity)
end

return ball
