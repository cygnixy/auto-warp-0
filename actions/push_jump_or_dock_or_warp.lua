local M = {}

function M.main(args)
    if eve.context_menus and #eve.context_menus > 0 and eve.context_menus[1].entries and #eve.context_menus[1].entries > 0 then
        local helpers = require("helpers")

        local entries = eve.context_menus[1].entries
        local target_texts_with_match = {
            { text = "Jump through stargate", partial_match = false },
            { text = "Dock",                  partial_match = false },
            { text = "Warp to",               partial_match = true }
        }
        local entry = helpers.find_entry_by_priority(entries, target_texts_with_match)

        if entry then
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
            return "Success"
        end
    end

    return "Running"
end

return M
