local leg = require("leg")

local M = {}

-- Success when no leg remains to fly; the turn itself lives here.
--
-- On the way out with a return destination given, the mission is half done:
-- flip the leg and fail, so the surrounding repeat runs set_route and
-- fly_route again -- this time for home. The timeline matters: the flip
-- happens on the tick the outward leg completes, and the route sequence
-- re-enters on the NEXT tick, when _leg already says "home". Memory
-- sequences forget on completion, so re-entry starts from scratch.
--
-- The journal narrates the turn; this action stays silent like the rest.
function M.main(args)
    local return_destination = leg.trimmed(args and args[1])
    if leg.current() == "out"
        and type(return_destination) == "string"
        and return_destination ~= ""
    then
        cygnixy.bb_set("_leg", "home")
        return "Failure"
    end
    return "Success"
end

return M
