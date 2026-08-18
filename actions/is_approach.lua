local M = {}

-- Returns Success if the ship is actively executing an Approach maneuver.
function M.main(args)
    local shipui = cygnixy.eve.shipui
    local indication = shipui and shipui.indication
    if indication and indication.maneuver_type == "Approach" then
        return "Success"
    end
    return "Failure"
end

return M
