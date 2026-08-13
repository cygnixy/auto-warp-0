local flight = require("flight")
local log = require("std.log")

local M = {}

-- Whether this flight was over before it began: there is nothing to fly, and
-- the client says why.
--
-- ONE PICTURE ONLY. The mission entry's button offers a warp instead of a
-- route, which is the client saying the mission's place is in this very system
-- and the next thing wanted is a warp — the one the fight step makes. Nothing
-- was ordered, no route was laid, and none can be. The flight has done its
-- work by having nothing to do, and the step is finished here.
--
-- Success ends the run: this sits as the first child of the fallback around the
-- flight, so the tree stops on it rather than entering a loop that has nothing
-- to loop over. The run of 16:51 stood in exactly that loop, in silence, with
-- every reading upstream of it correct.
--
-- Everything else is Failure and the flight below is flown. That includes the
-- emptiness nobody explains: it is not this action's business to end anything
-- over it — see somewhere_to_fly, which stands in the plain sequence above and
-- fails the run when its minute is spent. The two are deliberately not one
-- action: an emptiness the client accounts for and an emptiness nothing
-- accounts for must not share an outcome, and here they do not even share a
-- node.
function M.main(args)
    if flight.reading(args and args[1], args and args[2]) ~= flight.WARP then
        return "Failure"
    end
    log.steady("flight_over", "info", "flight",
        "no route, and none wanted: the mission is in this system and its entry " ..
        "offers a warp to the place — this flight is over before it began")
    return "Success"
end

return M
