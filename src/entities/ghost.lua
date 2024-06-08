local ghost = {}

local util = require "util"
local vec = require "vec"
local textures = require "textures"

local entity = {}

function entity:update(dt)
    local old_pos = self.pos
    self.pos = self.start_pos + vec.v2(
        math.cos(self.n/60) * 100,
        math.sin(self.n/15) * 20
    )
    self.n = self.n + dt * 50
    self.dir = (self.pos.x - old_pos.x < 0) and 1 or -1
end

function entity:draw()
    rl.DrawTextureRec(
        textures.ghost,
        util.Rec(0, 0, 32 * self.dir, 32),
        self.pos,
        rl.WHITE
    )
end

function entity:get_draw_box()
    return util.Rec(self.pos.x, self.pos.y, 32, 32)
end

function entity:get_hitbox()
    return util.Rec(self.pos.x, self.pos.y, 32, 32)
end

function entity:player_collision(pos)
    -- self.world:send_scene_event("gameover")
end

function ghost.new(world, spawn_pos, ...)
    entity.__index = entity
    return setmetatable({
        start_pos = spawn_pos,
        pos = spawn_pos - vec.v2(0, 32),
        n = 0,
        dir = -1,
        world = world
    }, entity)
end

return ghost
