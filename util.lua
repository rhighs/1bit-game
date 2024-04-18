local color = require("color")
local ffi = require "ffi"

local util = {}

function util.Color(r, g, b, a) return ffi.new("Color", r, g, b, a) end
function util.Rec(x, y, w, h) return ffi.new("Rectangle", x, y, w, h) end
function util.sign(a) return a >= 0 and 1 or -1 end
function util.print(text, y) rl.DrawText(text, 0, y * 24, 24, color.COLOR_PRIMARY) end

function util.format_table(t)
    local s = "{"
    for k, v in pairs(t) do
        s = s .. "[" .. util.pystr(k) .. "] = " .. util.pystr(v) .. ", "
    end
    return s == "{" and "{}" or s:sub(1, -3) .. "}"
end

function util.pystr(...)
    local args = { n = select('#', ...); ... }
    local s = ""
    for i = 1, args.n do
        if type(args[i]) == "table" then
            s = s .. util.format_table(args[i]) .. " "
        else
            s = s .. tostring(args[i]) .. " "
        end
    end
    return s:sub(1, -2)
end

function util.pyprint(...)
    print(util.pystr(...))
end

function util.sign(x)
    return x < 0 and -1
        or x > 0 and 1
        or 0
end

return util
