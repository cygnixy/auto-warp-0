local M = {}

function M.main(args)
    if eve.session_time_indicator then
        if eve.session_time_indicator.display then
            return "Success"
        end
    end
    return "Failure"
end

return M
