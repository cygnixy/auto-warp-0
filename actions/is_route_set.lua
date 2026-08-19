local state = require("std.state")
local route = require("std.route")

local M = {}

-- Whether the client is currently showing an active route, read through
-- std.route's one rule instead of a second, hand-written copy of it: a
-- route is jumps counted or markers drawn, and a route panel not yet drawn
-- is not an answer either way.
function M.main(args)
    if route.has_route() then
        return "Success"
    end
    if route.panel() == nil or not state.settled(state.phase()) then
        return "Running"
    end
    return "Failure"
end

return M
