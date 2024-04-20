local util = require 'util'
local vec = require "vec"

local ghost = {}

function ghost.new(spawn_pos)
    return {
        left = rl.LoadTexture("assets/ghost.png"),
        right = rl.LoadTexture("assets/ghost-right.png"),
        pos = spawn_pos,
        dir = -1,
        n = 0,
        frame_counter = 0,

        update = function (self, dt)
            self.pos = vec.v2(
                self.pos.x + self.dir * 4,
                self.pos.y + math.sin(self.n/10) * 4
            )
            self.n = self.n + 1
            if self.n % 100 == 0 then
                self.dir = -self.dir
            end
        end,

        draw = function (self)
            if self.dir == -1 then
                rl.DrawTextureV(self.left, self.pos, rl.WHITE)
            else
                rl.DrawTextureV(self.right, self.pos, rl.WHITE)
            end
        end,
    }
end

return ghost
