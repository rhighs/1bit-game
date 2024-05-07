local timer = require "timer"
local game_over = {}

local scene = {}

function scene:init()
    self.timer:reset()
end

function scene:destroy()
end

function scene:update(dt)
    self.timer:update(dt)
end

function scene:draw()
    local width = rl.MeasureText("game over.", 32)
    rl.DrawText("game over.", 800/2 - width/2, 450/2 - 32/2, 32, rl.WHITE)
end

function scene:should_change()
    return self.timer:done() and { name = "start" } or nil
end

function game_over.new(duration_secs)
    scene.__index = scene
    return setmetatable({ timer = timer.new(duration_secs) }, scene)
end

return game_over
