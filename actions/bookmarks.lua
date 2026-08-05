-- Bookmarks the client shows in two windows at once: the standalone bookmark
-- window and the locations window. This action used to look only at the first,
-- and in flight both of them are open.
--
-- Both windows carry their entries the same way: a pair of the displayed text
-- and the region it occupies.
local M = {}

local function collect(window, found)
    if window and window.entries then
        for _, entry in ipairs(window.entries) do
            local text, region = entry[1], entry[2]
            if text and region then
                found[#found + 1] = { text = text, region = region }
            end
        end
    end
end

function M.entries()
    local found = {}
    collect(cygnixy.eve.standalone_bookmark_window, found)
    collect(cygnixy.eve.locations_window, found)
    return found
end

-- Finds a bookmark by what it is for: "dock" or "undock".
--
-- "dock" is a substring of "undock", so a plain search for the first happily
-- picks an undock bookmark and sends the ship the other way. Undock is
-- therefore recognised first and excluded from the dock match.
function M.find(kind)
    local entries = M.entries()
    local wanted = nil
    for _, entry in ipairs(entries) do
        local text = string.lower(entry.text)
        local is_undock = string.find(text, "undock", 1, true) ~= nil
        local is_dock = not is_undock and string.find(text, "dock", 1, true) ~= nil
        if (kind == "undock" and is_undock) or (kind == "dock" and is_dock) then
            wanted = entry
            break
        end
    end
    if wanted == nil then
        return nil, "no " .. kind .. " bookmark among " .. #entries .. " entries"
    end

    -- The client keeps no geometry of its own for a bookmark row: every row of
    -- the list reports the region of the whole list. Clicking the centre of
    -- that would open the menu of whichever row happens to sit in the middle
    -- and warp the ship somewhere else entirely, so the rows are refused
    -- instead of guessed at.
    for _, other in ipairs(entries) do
        if other ~= wanted and M.same_region(other.region, wanted.region) then
            return nil,
                "the bookmark rows are not addressable: " .. #entries ..
                " of them report one and the same region, so there is no point that means this row"
        end
    end
    return wanted
end

function M.same_region(a, b)
    return a.x == b.x and a.y == b.y and a.width == b.width and a.height == b.height
end

return M
