local M = {}

function M.main(args)
    if cygnixy.eve.station_window and cygnixy.eve.station_window.buttons then
        return "Success"
    end
    return "Failure"
end

return M
