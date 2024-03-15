if eve.shipuiand and eve.shipui.indication and eve.shipui.indication.maneuver_type then
    local maneuver_type = eve.shipui.indication.maneuver_type
    if maneuver_type == "Jump" then
        return "Success"
    end
end
return "Running"
