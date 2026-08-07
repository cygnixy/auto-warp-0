local bookmarks = require("bookmarks")
local log = require("std.log")
local pointer = require("std.pointer")
local warp_choice = require("warp_choice")

local M = {}

function M.main(args)
    local bookmark, why = bookmarks.find("dock")
    if bookmark == nil then
        log.error("flight", "the dock bookmark cannot be used: " .. tostring(why))
        return "Failure"
    end

    local entry, err = pointer.open_menu_and_choose(bookmark.region, warp_choice.choices)
    if entry == nil then
        log.error("flight", "the dock bookmark gave no menu: " .. tostring(err))
        return "Failure"
    end

    warp_choice.after_chosen(entry, "dock")
    return "Success"
end

return M
