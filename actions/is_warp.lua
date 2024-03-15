if eve.shipui and eve.shipui.indication and eve.shipui.indication.maneuver_type then
    local maneuver_type = eve.shipui.indication.maneuver_type
    if maneuver_type == "Warp" then
        return "Success"
    else
        return "Failure"
    end
end
return "Failure"
