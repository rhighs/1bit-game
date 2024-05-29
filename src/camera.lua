local camera = {}

local ffi = require "ffi"
local vec = require "vec"
local util = require "util"

function camera.new(screen_size, start_pos)
    return {
        camera = ffi.new("Camera2D", screen_size / 2, vec.zero(), 0, 1),
        screen_size = screen_size,
        debug_counter = 0,

        get = function (self) return self.camera end,
        position = function (self) return self.camera.target end,

        clone = function (self)
            local c = camera.new(screen_size, start_pos)
            c.camera.target = self.camera.target
            c.camera.rotation = self.camera.rotation
            c.camera.zoom = self.camera.zoom
            return c
        end,

        retarget = function (self, target) self.camera.target = target end,

        top_left_world_pos = function (self)
            return rl.GetScreenToWorld2D(vec.zero(), self.camera)
        end,

        bottom_right_world_pos = function (self)
            return rl.GetScreenToWorld2D(self.screen_size, self.camera)
        end,

        debug_move = function (self)
            self.debug_counter = self.debug_counter + 1
            if self.debug_counter == 3 then
                self.debug_counter = 0
                self.camera.target.x = self.camera.target.x
                                     + (rl.IsKeyDown(rl.KEY_A) and -32 or 0)
                                     + (rl.IsKeyDown(rl.KEY_D) and  32 or 0)
                self.camera.target.y =  self.camera.target.y
                                     + (rl.IsKeyDown(rl.KEY_W) and -32 or 0)
                                     + (rl.IsKeyDown(rl.KEY_S) and  32 or 0)
                self.camera.zoom = self.camera.zoom
                                 + (rl.IsKeyDown(rl.KEY_F) and 1 or 0)
                                 + (rl.IsKeyDown(rl.KEY_G) and -1 or 0)
            end
        end,

        is_inside = function (self, draw_box)
            u = rl.GetWorldToScreen2D(vec.v2(draw_box.x, draw_box.y), self.camera)
            return rl.CheckCollisionRecs(
                util.Rec(0, 0, screen_size.x, screen_size.y),
                util.Rec(u.x, u.y, draw_box.width, draw_box.height)
            )
        end,
    }
end

return camera
