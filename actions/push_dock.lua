if eve.context_menus ~= nil and #eve.context_menus > 0 and #eve.context_menus[1].entries > 0 then
    for _, entry in ipairs(eve.context_menus[1].entries) do
        if entry.text and entry.enabled and entry.text == "Dock" then
            local move_x = entry.region.x + entry.region.width // 2
            local move_y = entry.region.y + entry.region.height // 2
            info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
            mouse_move(move_x, move_y)
            sleep(50)
            mouse_click_left()
            info("CLICK Mouse Button Left")
            local now = os.time()
            bb_set("warp", now)
            bb_set("state", "warp")
            unlock()
            return "Success"
        end
    end
end
return "Failure"
