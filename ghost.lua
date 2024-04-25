local util = require 'util'
local vec = require "vec"

local ghost = {}

local entity = {}

function entity:update(dt)
    local old_pos = self.pos
    self.pos = self.start_pos + vec.v2(
        math.cos(self.n/60) * 100,
        math.sin(self.n/15) * 20
    )
    self.n = self.n + dt * 50
    self.dir = (self.pos.x - old_pos.x < 0) and -1 or 1
end

function entity:current_texture()
    return self.dir == -1 and self.left or self.right
end

function entity:draw()
    rl.DrawTextureV(self:current_texture(), self.pos, rl.WHITE)
end

function entity:get_draw_box()
    local tex = self:current_texture()
    return util.Rec(self.pos.x, self.pos.y - tex.height, tex.width, tex.height)
end

function entity:get_hitbox()
    return util.Rec(self.pos.x, self.pos.y, 32, 32)
end

function entity:player_collision(pos)
    return "game-over"
end

function ghost.new(spawn_pos)
    entity.__index = entity
    return setmetatable({
        start_pos = spawn_pos,
        pos = spawn_pos,
        n = 0,
        dir = -1,
        left = rl.LoadTexture("assets/ghost.png"),
        right = rl.LoadTexture("assets/ghost-right.png")
    }, entity)
end

return ghost
