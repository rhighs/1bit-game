local camera = {}

local vec = require("vec")

function camera.new(start_pos)
    return {
        pos = start_pos,

        update = function (self)
            self.pos.x = self.pos.x
                       + (rl.IsKeyDown(rl.KEY_D) and  1 or 0)
                       + (rl.IsKeyDown(rl.KEY_A) and -1 or 0)
            self.pos.y = self.pos.y
                       + (rl.IsKeyDown(rl.KEY_S) and  1 or 0)
                       + (rl.IsKeyDown(rl.KEY_W) and -1 or 0)
        end,

        draw = function (self, grid, screen_size, get_texture)
            -- transform camera coords into tile coords
            local orig   = vec.floor(self.pos / 32)
            local endvec = vec.floor((self.pos + screen_size) / 32)
            for y = orig.y, endvec.y do
                if grid[y] ~= nil then
                    for x = orig.x, endvec.x do
                        elem = grid[y][x]
                        if elem ~= nil and elem ~= 0 then
                            level_coords = vec.v2(x, y) * 32
                            screen_coords = level_coords - self.pos
                            rl.DrawTextureV(get_texture(elem), screen_coords, rl.WHITE)
                        end
                    end
                end
            end
        end,

        draw_enemies = function (self, enemies, screen_size, get_texture)
            local orig   = self.pos
            local endvec = self.pos + screen_size
            for _, e in ipairs(enemies) do
                c = e.pos * 32 - self.pos
                if c.x >= 0 and c.x <= screen_size.x and c.y >= 0 and c.y <= screen_size.y then
                    rl.DrawTextureV(get_texture(e.enemy_id), c, rl.WHITE)
                end
            end
        end
    }
end

return camera
