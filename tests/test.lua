local util = require "util"

_G.test_block = function(block_title, test_case)
    return function ()
        local test_results = {}
        function test(test_title, test_func)
            local result = {
                title = test_title,
                failed = false,
                failed_at = nil,
            }
            local test_env = {
                assert = function (self, assertion)
                    if not assertion then
                        result.failed_at = {
                            file = __FILE__(3),
                            line = __LINE__(3),
                        }
                        error()
                    end
                end,
                fail = function (self)
                    result.failed_at = {
                        file = __FILE__(3),
                        line = __LINE__(3),
                    }
                    error()
                end
            }

            local ok, err = pcall(test_func, test_env)
            result.failed = not ok
            if not ok then GAME_LOG(err) end
            table.insert(test_results, result)
        end

        test_case(test)
        return {
            title = block_title,
            results = table.copy(test_results),
        }
    end
end