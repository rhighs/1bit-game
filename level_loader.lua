level_loader = {}

-- load tilemap chunks and return them as a 2D array
function level_loader.load(data)
    grid = {}
    for k, v in ipairs(data.layers[1].chunks) do
        for y = 0, v.height do
            if grid[y + v.y] == nil then
                grid[y + v.y] = {}
            end
            for x = 0, v.width do
                local id = v.data[y * v.width + x]
                if id ~= 0 then
                    grid[y + v.y][x + v.x] = id
                end
            end
        end
    end
    return grid
end

return level_loader
