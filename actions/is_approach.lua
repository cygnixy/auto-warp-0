local M = {}

-- The ship is closing on something it was told to approach.
--
-- This is a movement like warp and jump, and the tree has to treat it as one:
-- after a Dock the client warps to the station, arrives, and only then starts
-- approaching, and a bot that counts approaching as standing still re-issues
-- the command every few seconds. In the run of 2026-08-05 that opened the menu
-- and chose Dock three more times while the ship was already on its way in.
function M.main(args)
    local shipui = cygnixy.eve.shipui
    local indication = shipui and shipui.indication
    if indication and indication.maneuver_type == "Approach" then
        return "Success"
    end
    return "Failure"
end

return M
