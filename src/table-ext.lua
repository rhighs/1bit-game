function table.range(start, _end)
    if _end == nil then
        _end = start
        start = 0
    end
    if start == nil then
        start = 0
    end
    local result = {}
    for k = start,_end do
        table.insert(result, k)
    end
    return result
end

function table.contains(t, callable)
    for k, v in pairs(t) do
        if callable(v, k) then
            return true
        end
    end
    return false
end

function table.find(t, callable)
    for k, v in pairs(t) do
        if callable(v, k) then
            return v, k
        end
    end
    return nil, 0
end

function table.filter(t, callable)
    local result = {}
    for k, v in pairs(t) do
        if callable(v, k) then
            table.insert(result, v)
        end
    end
    return result
end

function table.partition(t, callable)
    local part1, part2 = {}, {}
    for k, v in pairs(t) do
        table.insert(callable(v, k) and part2 or part1, v)
    end
    return part1, part2
end

function table.flatten(t)
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

function table.map(t, callable)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, callable(v, k))
    end
    return result
end

function table.copy(t)
    local result = {}
    for k, v in pairs(t) do result[k] = v end
    return setmetatable(result, getmetatable(t))
end

function table.sorted(t, cmp)
    local result = table.copy(t)
    table.sort(result, cmp)
    return result
end

function table.max(t, callable)
    if callable == nil then callable = function (v) return v end end
    if #t == 0 then return nil, nil end
    local key, value = 1, t[1]
    for i = 2, #t do
        if callable(value) < callable(t[i]) then
            key, value = i, t[i]
        end
    end
    return key, value
end

function table.foldl(t, init, fn)
    local r = init
    for _, v in ipairs(t) do
        r = fn(v, r)
    end
    return r
end
