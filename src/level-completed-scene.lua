local timer = require "timer"

local level_completed = {}

local scene = {}

function scene:init()
    self.timer:reset()
end

function scene:destroy() end

function scene:update(dt)
    self.timer:update(dt)
    if self.timer:done() then
        self.scene_queue:send({ name = "start" })
    end
end

function scene:draw()
    local width = rl.MeasureText("level completed!", 32)
    rl.DrawText("level completed!", 800/2 - width/2, 450/2 - 32/2, 32, rl.WHITE)
end

function level_completed.new(scene_queue, duration_secs)
    scene.__index = scene
    return setmetatable({
        timer = timer.new(duration_secs),
        scene_queue = scene_queue
    }, scene)
end

return level_completed
