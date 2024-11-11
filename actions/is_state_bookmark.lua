local M = {}

function M.main(args)
    local state = bb_get("state")
    if state == "bookmark" then
        return "Success"
    end

    return "Failure"
end

return M
