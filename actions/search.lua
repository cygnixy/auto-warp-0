-- Reading the search results window.
--
-- Both the categories and the rows arrive as pairs of text and region, so the
-- work here is naming: which category a destination kind means, and which row
-- is the one asked for.

local M = {}

-- The category a destination kind is looked up in. The mission speaks of
-- systems and stations; the client writes "Solar Systems" and "Stations".
local CATEGORIES = {
    system = "Solar Systems",
    station = "Stations",
}

function M.category_of(kind)
    if type(kind) ~= "string" then
        return nil
    end
    return CATEGORIES[string.lower(kind)]
end

-- Category headers carry a count — "Solar Systems (3)" — which changes with
-- every search, so they are matched by their beginning.
function M.find_group(groups, wanted)
    local prefix = string.lower(wanted)
    for _, pair in ipairs(groups) do
        local text, region = pair[1], pair[2]
        if type(text) == "string" and region ~= nil then
            local lowered = string.lower(text)
            if string.sub(lowered, 1, #prefix) == prefix then
                return { text = text, region = region }
            end
        end
    end
    return nil
end

-- The name inside a result row.
--
-- A row is not the bare name. The client writes it with the security status
-- coloured in front and the distance in brackets behind:
--
--   <color=0xFF3A9AEB>0.9</color> Jita IV - Moon 4 - Caldari Navy Assembly Plant (3 Jumps)
--
-- so comparing the row to a destination as it stands never matches anything.
--
-- The security status is taken together with the markup that holds it, not as
-- "a number at the front": a character may be called "1 Jita", and stripping
-- leading digits blindly would turn that row into the system Jita — exactly
-- the confusion the exact match exists to prevent.
function M.row_name(text)
    if type(text) ~= "string" then
        return nil
    end
    local name = string.gsub(text, "^%s*<color=[^>]*>%s*%-?[%d%.]+%s*</color>%s*", "")
    name = string.gsub(name, "<[^>]*>", "")
    name = string.gsub(name, "%s*%(%d+%s+[Jj]umps?%)%s*$", "")
    return (string.gsub(name, "^%s*(.-)%s*$", "%1"))
end

-- The row whose name is exactly the destination, ignoring case.
--
-- Exact, not partial: a search for "Jita" brings back Jita and every character
-- with Jita in the name, and warping to the wrong one is a long way home. Two
-- rows with the same name are refused rather than guessed between.
function M.find_entry(entries, wanted)
    local needle = string.lower(wanted)
    local found = nil
    for _, pair in ipairs(entries) do
        local raw, region = pair[1], pair[2]
        local text = M.row_name(raw)
        if type(text) == "string" and region ~= nil and string.lower(text) == needle then
            if found ~= nil then
                return nil, "several rows are named " .. wanted
            end
            found = { text = text, region = region }
        end
    end
    if found == nil then
        return nil, "no row is named exactly " .. wanted
    end
    return found
end

function M.list_groups(groups)
    local texts = {}
    for _, pair in ipairs(groups) do
        if type(pair[1]) == "string" then
            texts[#texts + 1] = pair[1]
        end
    end
    return table.concat(texts, ", ")
end

return M
