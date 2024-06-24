require "test"
local cycle = require "cycle"

return test_block("cycle lib simple tests", function (test)
    test("current value gets updated every 0.2 secs", function (test)
        local c = cycle.new_values({ 1, 2, 3, 4 }, 0.2)
        test:assert(c:current() == 1)
        c:update(0.2)
        test:assert(c:current() == 2)
        c:update(0.2)
        test:assert(c:current() == 3)
        c:update(0.2)
    end)

    test("current value should not change if update is not called", function (test)
        local c = cycle.new_values({ 1, 2, 3, 4 }, 0.2)
        for i = 0,10 do
            test:assert(c:current() == 1)
        end
    end)

    test("cycle range can start from 0", function (test)
        local c = cycle.new(0, 10, 0.2)
        for i = 0,9 do
            test:assert(c:current() == i)
            c:update(0.2)
        end
    end)
end)