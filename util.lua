local color = require("color")
local ffi = require "ffi"

local util = {}

function util.Color(r, g, b, a) return ffi.new("Color", r, g, b, a) end
function util.Rec(x, y, w, h) return ffi.new("Rectangle", x, y, w, h) end
function util.sign(a) return a >= 0 and 1 or -1 end
function util.print(text, y) rl.DrawText(text, 0, y * 24, 24, color.COLOR_PRIMARY) end

function util.tabfmt(t)
    local res = "{"
    for k, v in pairs(t) do
        -- s = type(v) == "table" and tabfmt(t) or tostring(v)
        res = res .. "[" .. tostring(k) .. "] = "
        s = type(v) == "table" and util.tabfmt(v) or tostring(v)
        res = res .. s .. ", "
    end
    res = res:sub(1, -3) .. "}"
    return res
end

function util.pyfmt(...)
    local res = ""
    for k, v in ipairs{...} do
        s = type(v) == "table" and util.tabfmt(v) or tostring(v)
        res = res .. s .. " "
    end
    return res
end

function util.pyprint(...)
    print(util.pyfmt(...))
end

return util
