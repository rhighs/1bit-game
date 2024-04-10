local camera = {}

local vec = require("vec")

function camera.new(start_pos)
    return {
        pos = start_pos,
        update = function ()
            camera.x = camera.x
                     + (rl.IsKeyDown(rl.KEY_D) and  1 or 0)
                     + (rl.IsKeyDown(rl.KEY_A) and -1 or 0)
            camera.y = camera.y
                     + (rl.IsKeyDown(rl.KEY_S) and  1 or 0)
                     + (rl.IsKeyDown(rl.KEY_W) and -1 or 0)
        end,
        draw = function (cam, grid, get_texture)
            -- transform camera coords into tile coords
            local orig   = vec.v2(math.floor(cam.x / 32), math.floor(cam.y / 32))
            local endvec = vec.v2(
                math.floor((cam.x + VP_WIDTH) / 32),
                math.floor((cam.y + VP_HEIGHT) / 32)
            )
            for y = orig.y, endvec.y do
                for x = orig.x, endvec.x do
                    elem = grid[y][x]
                    if elem ~= nil and elem ~= 0 then
                        level_coords = vec.v2(x, y) * 32
                        screen_coords = level_coords - cam
                        rl.DrawTextureV(get_texture(elem), screen_coords, rl.WHITE)
                    end
                end
            end
        end
    }
end

return camera
