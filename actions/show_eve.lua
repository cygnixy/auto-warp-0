local sort, rep, concat = table.sort, string.rep, table.concat

local function serialise(var, sorted, indent)
    if type(var) == 'string' then
        return "'" .. var .. "'"
    elseif type(var) == 'table' then
        local keys = {}
        for key, _ in pairs(var) do
            keys[#keys + 1] = key
        end
        if sorted then
            sort(keys, function(a, b)
                if type(a) == type(b) and (type(a) == 'number' or type(a) == 'string') then
                    return a < b
                elseif type(a) == 'number' and type(b) ~= 'number' then
                    return true
                else
                    return false
                end
            end)
        end
        local strings = {}
        local indent = indent or 0
        for _, key in ipairs(keys) do
            strings[#strings + 1]
            = rep('\t', indent + 1)
                .. serialise(key, sorted, indent + 1)
                .. ' = '
                .. serialise(var[key], sorted, indent + 1)
        end
        return 'table (\n' .. concat(strings, '\n') .. '\n' .. rep('\t', indent) .. ')'
    else
        return tostring(var)
    end
end

file = io.open("logs/eve.txt", "w")
file:write(serialise(eve, True))
file:close()
