local M = {}

function M.main(args)
    if cygnixy.eve.info_panel_container and cygnixy.eve.info_panel_container.info_panel_route then
        local route = cygnixy.eve.info_panel_container.info_panel_route
        if route.route_element_marker and #route.route_element_marker > 0 then
            local region = route.route_element_marker[1].region
            if region ~= nil then
                local move_x = region.x + region.width // 2
                local move_y = region.y + region.height // 2
                cygnixy.info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
                cygnixy.mouse_move(move_x, move_y)
                cygnixy.sleep(50)
                cygnixy.mouse_click_right()
                cygnixy.info("CLICK Mouse Button Right")
                cygnixy.sleep(200)
                cygnixy.update_eve()
                local push_jump_or_dock_or_warp = require("push_jump_or_dock_or_warp")
                local result = push_jump_or_dock_or_warp.main()
                return result
            end
        end
    end
    return "Running"
end

return M
