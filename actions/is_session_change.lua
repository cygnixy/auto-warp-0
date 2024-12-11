local M = {}

function M.main(args)
    if cygnixy.eve.session_time_indicator then
        if cygnixy.eve.session_time_indicator.display then
            return "Success"
        end
    end
    return "Failure"
end

return M
