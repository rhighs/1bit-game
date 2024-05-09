local arm = {}

local util = require "util"
local vec = require "vec"
local textures = require "textures"

local entity = {}

function entity:update(dt)
    return self['state_' .. self.state](self, dt)
end

function entity:draw()
    -- rl.DrawTextureV(textures.arm, self.pos, rl.WHITE)
    rl.DrawTexturePro(
        textures.arm,
        util.Rec(0, 0, textures.arm.width, textures.arm.height),
        util.Rec(self.pos.x, self.pos.y, textures.arm.width, textures.arm.height),
        vec.v2(16, 16),
        self.angle,
        rl.WHITE
    )
end

function entity:get_draw_box()
    return util.Rec(self.pos.x, self.pos.y, 32, 64)
end

function entity:get_hitbox()
    return util.Rec(self.pos.x, self.pos.y, 32, 64)
end

function entity:player_collision(pos)
end

function entity:state_idle()
    self.timer = self.timer + 1
    if self.timer > 200 then
        self.timer = 0
        self.state = 'spawn'
    end
end

function entity:state_spawn()
    self.timer = self.timer + 1
    if self.timer > 4 * 4 then
        self.state = 'rot1'
    end
end

function entity:state_rot1()
    self.angle = self.angle - 2
    if self.angle < -90 then
        self.angle = -90
        self.state = 'rot2'
    end
end

function entity:state_rot2()
    self.angle = self.angle + 8
    if self.angle > 90 then
        self.angle = 90
        self.timer = 0
        self.state = 'stop'
    end
end

function entity:state_stop()
    self.timer = self.timer + 1
    if self.timer > 100 then
        self.state = 'return'
    end
end

function entity:state_return()
    self.angle = self.angle - 1
    if self.angle < 0 then
        self.angle = 0
        self.timer = 0
        self.state = 'idle'
    end
end

function arm.new(spawn_pos)
    GAME_LOG("creating arm")
    entity.__index = entity
    return setmetatable({
        pos = spawn_pos,
        timer = 0,
        angle = 0,
        state = 'idle'
    }, entity)
end

return arm
