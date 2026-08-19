local dialog = require("std.dialog")
local log = require("std.log")
local pointer = require("std.pointer")

local M = {}

-- The buttons of a message box arrive as pairs of the node and its caption, not
-- as records with `label` and `region` fields. This action read fields that were
-- never there, found nothing to press, and answered Failure on every box the
-- client put up.
function M.main(args)
    local boxes = dialog.boxes()
    if not (boxes and boxes[1].buttons) then
        return "Failure"
    end

    local node = dialog.button(boxes[1], "Yes")
    if node and node.region then
        local pressed, err = pointer.click(node.region)
        if not pressed then
            log.warn("client", "a message box was not answered: " .. tostring(err))
            return "Failure"
        end
        -- Worth a line: the client asked the operator something and the
        -- bot answered for them. Until now this happened silently, and a
        -- mission that agreed to something unexpected left no trace of it.
        log.info("client", "answered \"Yes\" to a message box")
        return "Success"
    end
    return "Failure"
end

return M
