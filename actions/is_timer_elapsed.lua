local M = {}

-- Function to check if a specified time interval has elapsed since a certain event.
-- args[1]: The blackboard key for retrieving the timestamp of the event (e.g., "openMenu").
-- args[2]: The threshold time in seconds. If the elapsed time exceeds this threshold, the function returns "Success".
function M.main(args)
    local openMenuTime = bb_get(args[1])
    if openMenuTime ~= nil then
        local currentTime = os.time()
        local elapsed = currentTime - openMenuTime
        if elapsed > args[2] then
            return "Success"
        else
            return "Failure"
        end
    else
        return "Success"
    end
end

return M
