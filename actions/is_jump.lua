local M = {}

function M.main(args)
    if cygnixy.eve.shipui and cygnixy.eve.shipui.indication and cygnixy.eve.shipui.indication.maneuver_type then
        local maneuver_type = cygnixy.eve.shipui.indication.maneuver_type
        if maneuver_type == "Jump" then
            return "Success"
        else
            return "Failure"
        end
    end
    return "Failure"
end

return M
