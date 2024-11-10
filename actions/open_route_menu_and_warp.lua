local M = {}

function M.main(args)
    if eve.info_panel_container and eve.info_panel_container.info_panel_route then
        local route = eve.info_panel_container.info_panel_route
        if route.route_element_marker and #route.route_element_marker > 0 then
            local region = route.route_element_marker[1].region
            if region ~= nil then
                window_focus()
                local move_x = region.x + region.width // 2
                local move_y = region.y + region.height // 2
                info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
                mouse_move(move_x, move_y)
                sleep(50)
                mouse_click_right()
                info("CLICK Mouse Button Right")
                sleep(200)
                update_eve()
                info(package.path)
                local push_jump_or_dock_or_warp = require("push_jump_or_dock_or_warp")
                local result = push_jump_or_dock_or_warp.main()
                return result
            end
        end
    end
    return "Running"
end

return M
