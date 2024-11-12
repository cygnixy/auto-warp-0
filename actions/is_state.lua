local M = {}

-- Function to check if the current state matches the expected state
-- args[1]: Expected state to compare with the current state from the blackboard
function M.main(args)
    local state = bb_get("_state")
    if state == args[1] then
        return "Success"
    end
    return "Failure"
end

return M
