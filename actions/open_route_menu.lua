if eve.info_panel_container and eve.info_panel_container.info_panel_route then
    local route = eve.info_panel_container.info_panel_route
    if route.route_element_marker and #route.route_element_marker > 0 then
        local region = route.route_element_marker[1].region
        if region ~= nil then
            local move_x = region.x + region.width // 2
            local move_y = region.y + region.height // 2
            lock()
            info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
            mouse_move(move_x, move_y)
            sleep(50)
            mouse_click_right()
            info("CLICK Mouse Button Right")
            local now = os.time()
            bb_set("open_menu", now)
            sleep(200)
            return "Success"
        end
    end
end
return "Running"
