local game_over = {}

local scene = {}

function scene:init()
    self.n = self.duration
end

function scene:update()
    self.n = self.n - 1
end

function scene:draw()
    local width = rl.MeasureText("game over.", 32)
    rl.DrawText("game over.", 800/2 - width/2, 450/2 - 32/2, 32, rl.WHITE)
end

function scene:should_change()
    return self.n == 0 and { name = "start" } or nil
end

function game_over.new(duration)
    scene.__index = scene
    return setmetatable({ duration = duration }, scene)
end

return game_over
