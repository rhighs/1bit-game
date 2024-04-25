local timer = require "timer"

local cycle_lib = {}
local cycle = {}

function cycle:current() return self.count end
function cycle:update(dt)
    self.timer:update(dt)
    if self.timer:done() then
        self.timer:reset()
        self.count = (self.count % self.to) + self.from
    end
end

function cycle_lib.new(from, to, interval)
    cycle.__index = cycle
    return setmetatable({
        from = from,
        to = to,
        count = 1,
        timer = timer.new(interval),
    }, cycle)
end

return cycle_lib