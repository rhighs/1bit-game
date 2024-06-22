local ball = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"
local textures = require "textures"

local ARM_HEIGHT = 69 -- and not 64
local BALL_WIDTH = 48
local BALL_HEIGHT = 48
local HANDLE_HEIGHT = 13
local PENDULUM_RADIUS = 128
local ARM_OFFSET = 16
local BALL_OFFSET = 25
local CHAIN_HEIGHT = 16

local CHAIN_FRAME     = vec.v2(64, 48)
local BALL_FRAME      = vec.v2(64, 0)
local HOOK_FRAME      = vec.v2(80, 48)

function ball.new(world, spawn_pos, _w, _h, data)
    local ball = {
        body = physics.new_circle(vec.zero(), 16, 1/10000),
        angle = data.angle,
        radius = data.radius,
        arm_queue = data.arm_queue,
        num_chains = math.ceil((data.radius - (64 - 16) - 25) / 16),
        world = world,
        direction = data.direction
    }

    ball.body.position = spawn_pos
    ball.body.velocity = vec.zero()
    ball.body.air_resistance_enabled = false
    ball.body.static_collision_resolver = function (body, tiles)
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
        if (tile.info.gid ~= 4 and tile.info.gid ~= 3)
        or tile.info.flip_vert or tile.info.flip_diag then
            return
        end
        util.pyprint("tile info =", tile.info)
        body.velocity.y = -300
        body.locked_ys[tile.pos.y] = true
    end
    ball.body.dynamic_collision_resolver = nil

    ball.body:apply_force(data.init_force)

    function ball:update(dt)
        self.body:update(dt)
        self.angle = self.angle + (0.04 * self.direction)
        if self.angle > 2*math.pi then
            self.angle = 0
        end
    end

    function ball:draw()
        local chain_height = self.radius - (ARM_HEIGHT - ARM_OFFSET) - BALL_OFFSET
        local tmp = vec.v2(-math.sin(self.angle), -math.cos(self.angle))
        rl.DrawTexturePro(
            textures.arm,
            util.RecV(HOOK_FRAME, vec.v2(32, 16)),
            util.RecV(self.body.position + tmp * ((self.num_chains+1)*16), vec.v2(32, 16)),
            vec.v2(16, 13),
            math.deg(-self.angle),
            rl.WHITE
        )
        for i = 1, self.num_chains+1 do
            local pos = tmp * ((i-1)*16)
            rl.DrawTexturePro(
                textures.arm,
                util.RecV(CHAIN_FRAME, vec.v2(16, 16)),
                util.RecV(self.body.position + pos, vec.v2(16, 16)),
                vec.v2(8, 16),
                math.deg(-self.angle),
                rl.WHITE
            )
        end
        rl.DrawTexturePro(
            textures.arm,
            util.RecV(BALL_FRAME, vec.v2(48, 48)),
            util.RecV(self.body.position, vec.v2(48, 48)),
            vec.v2(48/2, 48/2),
            math.deg(-self.angle),
            rl.WHITE
        )
    end

    function ball:get_draw_box()
        local end_pos = self.body.position
                      - vec.v2(math.sin(self.angle), math.cos(self.angle))
                      * self.radius
        local xmin = math.min(end_pos.x, self.body.position.x - 48)
        local xmax = math.max(end_pos.x, self.body.position.x + 48)
        local ymin = math.min(end_pos.y, self.body.position.y - 48)
        local ymax = math.max(end_pos.y, self.body.position.y + 48)
        return util.Rec(xmin, ymin, xmax - xmin, ymax - ymin)
    end

    function ball:get_hitbox()
        return util.Rec(self.body.position.x - 25/2, self.body.position.y - 20/2, 25, 20)
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
