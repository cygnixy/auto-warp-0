local M = {}

function M.main(args)
    if eve.standalone_bookmark_window and eve.standalone_bookmark_window.entries then
        for _, entry in eve.standalone_bookmark_window.entries do
            if entry and entry[1] and string.find(entry[1], "Undock") then
                local region = entry[2]
                local move_x = region.x + region.width // 2
                local move_y = region.y + region.height // 2
                info(string.format("MOVE MOUSE: %d %d", move_x, move_y))
                mouse_move(move_x, move_y)
                sleep(50)
                mouse_click_right()
                info("CLICK Mouse Button Right")
                sleep(200)
                update_eve()
                local push_jump_or_dock_or_warp = require("push_jump_or_dock_or_warp")
                local result = push_jump_or_dock_or_warp.main()
                return result
            end
        end
    end
    return "Failure"
end

return M
