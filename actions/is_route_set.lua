local state = require("std.state")

local M = {}

-- Whether the client is currently showing an active route.
-- Returns Running during session changes/redraws when panels are transient.
function M.main(args)
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    if not route then
        return "Running"
    end

    -- Header jump count is available in both expanded and collapsed panel states.
    local jumps = route.jumps
    if type(jumps) == "number" then
        if jumps > 0 then
            return "Success"
        end
        return "Failure"
    end

    local markers = route.route_element_marker
    if markers ~= nil and #markers > 0 then
        return "Success"
    end

    -- During session transitions or redrawing, return Running to prevent premature exit.
    if not state.settled(state.phase()) then
        return "Running"
    end

    return "Failure"
end

return M
