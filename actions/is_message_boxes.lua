local M = {}

function M.main(args)
    if cygnixy.eve.message_boxes ~= nil then
        return "Success"
    else
        return "Failure"
    end
end

return M
