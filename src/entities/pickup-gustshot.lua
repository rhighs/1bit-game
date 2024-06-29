local gustshot = {}

local util = require "util"
local textures = require "textures"
local vec = require "vec"

local entity = {}

local DRAW_DIMS = vec.v2(32, 32)

function entity:update(dt)
    self.position = vec.v2(
        self.init_position.x,
        (self.init_position.y - 3) + math.sin(rl.GetTime() * 5) * 3
    )
end

function entity:draw()
    rl.DrawTexturePro(
        textures.powerups,
        util.RecV(vec.zero(), DRAW_DIMS),
        util.RecV(self.position, DRAW_DIMS),
        vec.zero(),
        0,
        rl.WHITE
    )
end

function entity:get_draw_box()
    return util.RecV(self.position, DRAW_DIMS)
end

function entity:get_hitbox()
    return util.RecV(self.position, DRAW_DIMS)
end

function entity:player_collision(pos)
    self.destroyed = true
    self.world.entities_queue:send({
        type = "powerup-pickup",
        powerup_tag = "gustshot"
    })
    self.world:defer_run(function()
            self.world:spawn({
                enemy_id = self.pickup_tag,
                pos = self.init_position
            })
        end,
        1
    )
end

function gustshot.new(world, position, ...)
    entity.__index = entity
    return setmetatable({
        pickup_tag = "pickup-gustshot",
        powerup_tag = "gustshot",
        init_position = position,
        position = position,
        world = world,
    }, entity)
end

return gustshot
