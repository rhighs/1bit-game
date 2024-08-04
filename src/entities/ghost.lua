local ghost = {}

local util = require "util"
local vec = require "vec"
local textures = require "textures"

local entity = {}

function entity:update(dt)
    if self.state == "moving" then
        local old_pos = self.pos
        self.pos = self.start_pos + vec.v2(
            -math.sin(self.n/60) * 100,
             math.sin(self.n/15) * 20
        )
        self.n = self.n + dt * 50
        self.dir = (self.pos.x - old_pos.x > 0) and -1 or 1
     elseif self.state == "coming-back" then
         local move_dir = vec.normalize(self.start_pos - self.pos) * 32 * 4 * dt
         self.pos = self.pos + move_dir
         if vec.distance(self.pos, self.start_pos) < 1.0 then
             self.state = "moving"
             self.n = 0
             self.dir = 1
         end
     elseif self.state == "hit" then
         self.pos = self.pos + self.hit_dir * dt
     end
end

function entity:draw()
    local color = rl.WHITE
    if self.state == "coming-back" then
        color = math.sin(rl.GetTime() * 20) > 0 and rl.WHITE or rl.BLACK
    end
    rl.DrawTextureRec(
        textures.ghost,
        util.Rec(0, 0, 32 * self.dir, 32),
        self.pos,
        color
    )
end

function entity:get_draw_box()
    return util.Rec(self.pos.x, self.pos.y, 32, 32)
end

function entity:get_hitbox()
    return util.Rec(self.pos.x, self.pos.y, 32, 32)
end

function entity:player_collision(pos)
    if self.state ~= "coming-back" then
        self.world:send_scene_event("gameover")
    end
end

function entity:on_signal_gustshot_hit(data)
    if self.state ~= "hit" then
        self.hit_dir = 
            vec.v2((vec.normalize(self.pos - data.position) * (32 * 10)).x, 0)
        self.state = "hit"
        self.world:defer_run(function ()
            self.state = "coming-back"
            self.hit_dest = nil
        end, 1)
    end
end

function ghost.new(world, spawn_pos, ...)
    entity.__index = entity
    return setmetatable({
        start_pos = spawn_pos,
        pos = spawn_pos - vec.v2(0, 32),
        state = "moving",
        n = 0,
        dir = 1,
        world = world
    }, entity)
end

return ghost
