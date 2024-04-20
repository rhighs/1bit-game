local ffi = require "ffi"

local util = {}

function util.Color(r, g, b, a) return ffi.new("Color", r, g, b, a) end
function util.Rec(x, y, w, h) return ffi.new("Rectangle", x, y, w, h) end
function util.sign(a) return a >= 0 and 1 or -1 end
function util.print(text, y) rl.DrawText(text, 0, y * 24, 24, rl.WHITE) end

util.DEFAULT_FORMAT_INDENT = 4

function render_indent(indent)
    return indent and string.rep(" ", indent) or ""
end

function _format_table(t, indent)
    local s = ""
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end

    if #keys == 0 then
        return "{}"
    end

    for i, k in ipairs(keys) do
        local v = t[k]
        local body = render_indent(indent) .. "[" .. _pystr({indent=4}, k) .. "] = " .. _pystr({indent = indent+util.DEFAULT_FORMAT_INDENT}, v)
        s = s .. body .. (i < (#keys) and "," or "") .. "\n"
    end

    return "{\n" .. s .. render_indent(indent - util.DEFAULT_FORMAT_INDENT) .. "}"
end

function _pystr(opts, ...)
    local args = { n = select('#', ...); ... }
    local s = ""
    for i = 1, args.n do
        if type(args[i]) == "table" then
            s = s .. _format_table(args[i], opts.indent) .. " "
        else
            s = s .. tostring(args[i]) .. " "
        end
    end
    return s:sub(1, -2)
end

function util.format_table(t)
    return _format_table(t, util.DEFAULT_FORMAT_INDENT)
end

function util.pystr(...)
    return _pystr({ indent = util.DEFAULT_FORMAT_INDENT }, ...)
end

function util.pyprint(...)
    print(util.pystr(...))
end

function util.sign(x)
    return x < 0 and -1
        or x > 0 and 1
        or 0
end

function util.table_contains(t, callable)
    for k, v in pairs(t) do
        if callable(v, k) then
            return true
        end
    end
    return false
end

function util.table_find(t, callable)
    for k, v in pairs(t) do
        if callable(v, k) then
            return v, k
        end
    end
    return nil, 0
end

function util.table_filter(t, callable)
    local result = {}
    for k, v in pairs(t) do
        if callable(v, k) then
            table.insert(result, v)
        end
    end
    return result
end

function util.table_map(t, callable)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, callable(v, k))
    end
    return result
end

function util.table_flatten(t)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            for kk, vv in pairs(v) do
                table.insert(result, vv)
            end
        else
            table.insert(result, v)
        end
    end
    return result
end

return util
