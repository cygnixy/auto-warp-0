local M = {}

function M.main(args)
    local openMenuTime = bb_get("open_menu")
    if openMenuTime ~= nil then
        local currentTime = os.time()
        local elapsed = currentTime - openMenuTime
        if elapsed > 3 then
            return "Success"
        else
            return "Failure"
        end
    else
        return "Success"
    end
end

return M
