require "table-ext"
local util = require "util"
local cyucle_tests = require "cycle_test"

function print_red(...)
    print("\27[31m" .. util.pystr(...) .. "\27[0m")
end

function print_green(...)
   print("\27[32m" .. util.pystr(...) .. "\27[0m")
end

local test_files = table.filter(
    table.map(util.dirfiles("tests"), function (f)
        local s, _ = f:gsub("%.lua", "")
        return s
    end),
    function (f) return f:sub(-#"_test") == "_test" end
)
-- GAME_LOG("loading test files", test_files)

local test_blocks = table.map(test_files, function (f) return require(f) end)
local test_runs = table.map(test_blocks, function (b) return b() end)

local total_tests = table.foldl(test_runs, 0, function (r, acc) return acc + #r.results end) 
local total_failed = table.foldl(test_runs, 0,
    function (r, acc)
        return acc + #table.filter(r.results, function (rr) return rr.failed end)
    end
) 

print()
for i, test_run in ipairs(test_runs) do
    print("BLOCK: " .. "\"" .. test_run.title .. "\"")
    for i, test_result in ipairs(test_run.results) do
        if test_result.failed then
            if test_result.failed_at ~=nil then
                local loc = test_result.failed_at.file .. ":" .. test_result.failed_at.line
                print_red("\tFAIL: " .. " \"" .. test_result.title .. "\" " .. loc)
            else
                print_red("\tFAIL: " .. " \"" .. test_result.title .. "\"")
            end
        else
            print_green("\tPASS: " .. " \"" .. test_result.title .. "\"")
        end
    end
end
print()

print(string.format("%-30s", "Total blocks:") .. #test_blocks)
print(string.format("%-30s", "Total tests:") .. total_tests)
print_green(string.format("%-30s", "Total passed:") .. total_tests - total_failed)
print_red(string.format("%-30s", "Total failed:") .. total_failed)

os.exit(total_failed == 0)