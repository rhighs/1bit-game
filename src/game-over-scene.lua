local timer = require "timer"
local game_over = {}

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
    local width = rl.MeasureText("game over.", 32)
    rl.DrawText("game over.", 800/2 - width/2, 450/2 - 32/2, 32, rl.WHITE)
end

function game_over.new(scene_queue, duration_secs)
    scene.__index = scene
    return setmetatable({
        timer = timer.new(duration_secs),
        scene_queue = scene_queue
    }, scene)
end

return game_over
