local timer_lib = {}

local timer = {}

function timer:done() return self.current <= 0.0 end
function timer:reset() self.current = self.wait end

function timer:update(dt)
    if not self:done() then
        self.current = self.current - dt
    end
end

function timer:get()
    return self.current
end

function timer_lib.new(wait_secs)
    timer.__index = timer
    return setmetatable({
        current = wait_secs,
        wait = wait_secs
    }, timer)
end

return timer_lib