if eve.shipui and eve.shipui.offensive_buff_button_names then
    for _, buff_name in ipairs(eve.shipui.offensive_buff_button_names) do
        if buff_name == "CloakDefense" then
            return "Success"
        end
    end
end
return "Failure"
