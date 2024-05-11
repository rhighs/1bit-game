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
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(result, getmetatable(t))
end

function table.sorted(t, cmp)
    local result = table.copy(t)
    table.sort(result, cmp)
    return result
end
