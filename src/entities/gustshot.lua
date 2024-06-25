local gustshot = {}

local util = require "util"
local textures = require "textures"
local vec = require "vec"

local entity = {}

local POWERUP_STATE_AVAILABLE = 0
local POWERUP_STATE_COLLECTED = 1
local POWERUP_STATE_ACTIVE    = 2
local POWERUP_STATE_INACTIVE  = 3

local ACTIVE_SPEED = 400
local DRAW_DIMS = vec.v2(32, 32)

function entity:update(dt)
    if self.state == POWERUP_STATE_AVAILABLE then
        self.position = vec.v2(
            self.available_position.x,
            self.available_position.y + math.sin(rl.GetTime() * 5) * 3
        )
    elseif self.state == POWERUP_STATE_ACTIVE then
        if self.radius < self.max_radius then
            self.radius = self.radius + self.active_grow_speed * dt
        end
        self.position = self.position + self.velocity * dt
    end
end

function entity:draw()
    if self.state == POWERUP_STATE_AVAILABLE then
        rl.DrawTexturePro(
            textures.powerups,
            util.RecV(vec.zero(), DRAW_DIMS),
            util.RecV(self.position, DRAW_DIMS),
            vec.zero(),
            0,
            rl.WHITE
        )
    elseif self.state == POWERUP_STATE_ACTIVE then
        vec.draw(self.velocity, self.position, rl.RED)
        rl.DrawCircleLines(self.position.x, self.position.y, self.radius, rl.RED)
    elseif self.state == POWERUP_STATE_INACTIVE then
    end
end

function entity:get_draw_box()
    if self.state == POWERUP_STATE_ACTIVE then
        return util.RecV(self.position, vec.v2(self.radius*2, self.radius*2))
    end
    return util.RecV(self.position, DRAW_DIMS) 
end

function entity:get_hitbox()
    if self.state == POWERUP_STATE_ACTIVE then
        return util.RecV(self.position, vec.v2(self.radius*2, self.radius*2))
    end
    return util.RecV(self.position, DRAW_DIMS)
end

function entity:shoot(origin, direction)
    if self.state == POWERUP_STATE_COLLECTED then
        self.position = origin
        self.velocity = self.speed * direction
        self.state = POWERUP_STATE_ACTIVE
    end
end

function entity:check_ghosts_collision()
end

function entity:collectable()
    return self.state == POWERUP_STATE_AVAILABLE
end

function entity:collect()
    if self.state == POWERUP_STATE_AVAILABLE then
        self.state = POWERUP_STATE_COLLECTED
    end
end

function entity:player_collision(pos)
    if self.state == POWERUP_STATE_AVAILABLE then
        GAME_LOG("player colliding with powerup", { player_pos = pos })
    end
end

function entity:use(player)
    self:shoot(player:position(), vec.v2(player.facing_dir.x, 0))
    self.world:defer_run(function()
            self.world:spawn({
                enemy_id = "gustshot",
                pos = self.available_position
            })
        end,
        1
    )
    return nil
end

function gustshot.new(world, position, ...)
    entity.__index = entity
    local min_radius = 20
    local max_radius = 200
    local grow_time_secs = 1.5

    return setmetatable({
        type = "powerup",
        state = POWERUP_STATE_AVAILABLE,
        speed = ACTIVE_SPEED,

        velocity = vec.zero(),

        available_position = position,

        position = position,
        world = world,
        radius = min_radius,
        max_radius = max_radius,
        active_grow_speed = (max_radius - min_radius)/grow_time_secs
    }, entity)
end

return gustshot
