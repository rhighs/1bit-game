local timer = require "timer"

local level_completed = {}

local scene = {}

function scene:init()
    self.timer:reset()
end

function scene:destroy() end

function scene:update(dt)
    self.timer:update(dt)
end

function scene:draw()
    local width = rl.MeasureText("level completed!", 32)
    rl.DrawText("level completed!", 800/2 - width/2, 450/2 - 32/2, 32, rl.WHITE)
end

function scene:should_change()
    return self.timer:done() and { name = "start" } or nil
end

function level_completed.new(duration_secs)
    scene.__index = scene
    return setmetatable({ timer = timer.new(duration_secs) }, scene)
end

return level_completed
