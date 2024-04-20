local util = require 'util'
local vec = require "vec"

local ghost = {}

local entity = {}

function entity:update(dt)
    local old_pos = self.pos
    self.pos = vec.v2(
        self.start_pos.x + math.cos(self.n/60) * 100,
        self.start_pos.y + math.sin(self.n/15) * 20
    )
    self.n = self.n + 1
    self.dir = (self.pos.x - old_pos.x < 0) and -1 or 1
end

function entity:draw()
    rl.DrawTextureV(self.dir == -1 and self.left or self.right, self.pos, rl.WHITE)
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
