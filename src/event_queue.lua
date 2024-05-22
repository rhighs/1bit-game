-- event queue library. how to use:
-- - make sure all queues are local, not global
-- - make sure you have only one handler (this is less restrictive
--   than you might think
-- - you can have as many senders as you want

local event_queue = {}

function event_queue.new()
    local queue = { buf = {} }

    function queue:send(data)
        table.insert(self.buf, data)
    end

    function queue:recv()
        if self.buf == 0 then
            return nil
        end
        return table.remove(self.buf, 1)
    end

    return queue
end

return event_queue
