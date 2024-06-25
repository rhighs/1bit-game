local ball = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"
local textures = require "textures"

local ARM_HEIGHT = 69 -- and not 64
local ARM_OFFSET = 16
local BALL_OFFSET = 25
local CHAIN_HEIGHT = 16

local CHAIN_FRAME     = vec.v2(64, 48)
local HOOK_FRAME      = vec.v2(80, 48)

function ball.new(world, spawn_pos, _w, _h, data)
    local r = data.ball_size.x / 2
    local ball = {
        body = physics.new_circle(vec.zero(), r, 1/10000),
        angle = data.angle,
        radius = data.radius,
        arm_queue = data.arm_queue,
        world = world,
        direction = data.direction,
        frame = data.ball_frame,
        size  = data.ball_size,
        ball_radius = data.ball_size.x / 2
    }

    ball.body.position = spawn_pos
    ball.body.velocity = vec.zero()
    ball.body.air_resistance_enabled = false
    function ball.body:static_collision_resolver(tiles)
        -- going down?
        if self.old_pos.y >= self.position.y then
            return
        end
        self.locked_ys = self.locked_ys or {}
        local tile = table.foldl(
            table.filter(tiles, function (v)
                return self.locked_ys[v.pos.y] == nil
            end),
            { pos = vec.v2(0, math.huge), info = nil },
            function (t, u) return t.pos.y < u.pos.y and t or u end
        )
        if tile.info == nil then
            return
        end
        if world.tile_data[tile.info.gid].properties.ground_type == 'top'
        and not tile.info.flip_vert and not tile.info.flip_diag then
            self.velocity.y = -300
            self.locked_ys[tile.pos.y] = true
        end
    end
    ball.body.dynamic_collision_resolver = nil

    ball.body:apply_force(data.init_force)

    function ball:update(dt)
        self.body:update(dt)
        self.angle = self.angle + (0.03 * self.direction)
        if self.angle > 2*math.pi then
            self.angle = 0
        end
    end

    function ball:draw()
        local num_chains = math.ceil((self.radius - (ARM_HEIGHT - ARM_OFFSET) - self.ball_radius) / CHAIN_HEIGHT)
        local pivot_pos = self.body.position + vec.v2(-math.sin(self.angle), -math.cos(self.angle)) * self.radius
        local circ_pos = vec.v2(math.sin(self.angle), math.cos(self.angle))
        local hook_pos = circ_pos * (ARM_HEIGHT - ARM_OFFSET - 13)
        rl.DrawTexturePro(
            textures.arm,
            util.RecV(HOOK_FRAME, vec.v2(32, 16)),
            util.RecV(pivot_pos + hook_pos, vec.v2(32, 16)),
            vec.v2(16, 0),
            math.deg(-self.angle),
            rl.WHITE
        )
        for i = 0, num_chains-1 do
            local pos = circ_pos * (ARM_HEIGHT - ARM_OFFSET + i*16)
            rl.DrawTexturePro(
                textures.arm,
                util.RecV(CHAIN_FRAME, vec.v2(16, 16)),
                util.RecV(pivot_pos + pos, vec.v2(16, 16)),
                vec.v2(8, 0),
                math.deg(-self.angle),
                rl.WHITE
            )
        end
        rl.DrawTexturePro(
            textures.arm,
            util.RecV(self.frame, self.size),
            util.RecV(self.body.position, self.size),
            self.size * 0.5,
            math.deg(-self.angle),
            rl.WHITE
        )
    end

    function ball:get_draw_box()
        local end_pos = self.body.position - vec.v2(math.sin(self.angle), math.cos(self.angle)) * self.radius
        local xmin = math.min(end_pos.x, self.body.position.x - self.size.x)
        local xmax = math.max(end_pos.x, self.body.position.x + self.size.x)
        local ymin = math.min(end_pos.y, self.body.position.y - self.size.y)
        local ymax = math.max(end_pos.y, self.body.position.y + self.size.y)
        return util.Rec(xmin, ymin, xmax - xmin, ymax - ymin)
    end

    function ball:get_hitbox()
        local offset = self.size.x * 16 / 100 -- sub 16% of size
        local v = vec.v2(offset, offset)
        return util.RecV(self.body.position - self.size*0.5 + v, self.size - v*2)
    end

    function ball:player_collision(pos)
        self.world:send_scene_event("gameover")
    end

    function ball:on_despawn()
        self.arm_queue:send("chain-ball-despawned")
    end

    return ball
end

return ball
