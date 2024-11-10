local M = {}

function M.main(args)
    if eve.station_window and eve.station_window.buttons then
        return "Success"
    end
    return "Failure"
end

return M
