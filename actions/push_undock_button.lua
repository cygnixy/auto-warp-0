local log = require("std.log")
local press = require("std.press")
local state = require("std.state")
local pointer = require("std.pointer")

local M = {}

-- The button is addressed by path: the station window can be covered by a chat
-- or an inventory window, and along a path the click point moves into whatever
-- part of the button is still open instead of landing on the window on top.
local UNDOCK = "station_window.buttons.Undock"

function M.main(args)
    if not state.settled() then
        return "Running"
    end

    local station = cygnixy.eve.station_window
    if not (station and station.buttons and station.buttons["Undock"]) then
        return "Running"
    end

    -- Cooldown check to avoid duplicate clicks during station window closing animation.
    if press.pending("undock") then
        return "Running"
    end
    local pressed, err = pointer.click(UNDOCK)
    press.made("undock")
    if not pressed then
        log.repeated("undock", "warn", "flight",
            "the undock button was not pressed: " .. tostring(err))
        return "Running"
    end

    log.forget("undock")
    cygnixy.bb_set("_state", "undock")
    return "Success"
end

return M
