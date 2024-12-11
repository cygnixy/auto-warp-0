local M = {}

function M.main(args)
    if cygnixy.eve.info_panel_container and cygnixy.eve.info_panel_container.info_panel_route then
        local route = cygnixy.eve.info_panel_container.info_panel_route
        if route.route_element_marker ~= nil and #route.route_element_marker > 0 then
            return "Success"
        else
            return "Failure"
        end
    end
    return "Running"
end

return M
