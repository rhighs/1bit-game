local ball = {}

local util = require "util"
local vec = require "vec"
local physics = require "physics"
local textures = require "textures"

function ball.new(world, spawn_pos, _w, _h, data)
    local ball = {
        body = physics.new_circle(vec.zero(), 16, 1/10000),
        angle = data.angle,
        radius = data.radius,
        arm_queue = data.arm_queue,
        num_chains = math.ceil((data.radius - (64 - 16) - 25) / 16),
        world = world
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
        if tile.info.gid ~= 4 or tile.info.flip_vert == -1 then
            return
        end
        body.velocity.y = -300
        body.locked_ys[tile.pos.y] = true
    end
    ball.body.dynamic_collision_resolver = nil

    ball.body:apply_force(data.init_force)

    function ball:update(dt)
        self.body:update(dt)
        self.angle = self.angle - 0.04
        if self.angle > 2*math.pi then
            self.angle = 0
        end
    end

    function ball:draw()
        for i = 1, self.num_chains+1 do
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
    end

    function ball:get_draw_box()
        local end_pos = self.body.position
                      - vec.v2(math.sin(self.angle), math.cos(self.angle))
                      * self.radius
        local xmin = math.min(end_pos.x, self.body.position.x - 55)
        local xmax = math.max(end_pos.x, self.body.position.x + 55)
        local ymin = math.min(end_pos.y, self.body.position.y - 50)
        local ymax = math.max(end_pos.y, self.body.position.y + 50)
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
