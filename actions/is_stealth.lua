local M = {}

function M.main(args)
    if cygnixy.eve.shipui and cygnixy.eve.shipui.offensive_buff_button_names then
        for _, buff_name in cygnixy.eve.shipui.offensive_buff_button_names do
            if buff_name == "CloakDefense" then
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
