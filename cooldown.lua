local cooldown = {}

function cooldown.make_cooled(callable, cooldown_secs)
    return setmetatable({
        lasttime = 0,
        cooldown_secs = cooldown_secs,
        callable = callable,
    }, {
        __call = function(self, ...)
            local now = rl.GetTime()
            if self.lasttime == 0 or now - self.lasttime > self.cooldown_secs then
                self.lasttime = now
                return self.callable(...)
            end
            return nil
        end
    })
end

return cooldown
