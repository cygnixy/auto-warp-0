local leg = require("leg")

local M = {}

-- Whether the current leg's destination is a station, read the same way
-- every other current-leg value is read in this bot: leg.pick, off the
-- blackboard's _leg mark, not remembered from an argument passed once at
-- the top of the mission.
--
-- A route to a station ends inside it — the last marker offers Dock, and
-- the leg is not over until the ship is actually docked. A route to a
-- system ends in open space with nothing further to press: the last jump
-- lands the ship, the route empties itself, and there is no station to
-- wait for. fly_route's own exit condition used to require a dock for
-- every mission regardless of kind, and a system-kind leg — the default
-- kind this bot ships with — circled an empty route forever, warping
-- toward a station window that a system destination was never going to
-- draw.
function M.main(args)
    local kind = leg.pick(args and args[1], args and args[2])
    if kind == "station" then
        return "Success"
    end
    return "Failure"
end

return M
