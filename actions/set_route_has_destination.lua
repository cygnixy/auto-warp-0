local leg = require("leg")

local M = {}

-- Whether the mission was given somewhere to go, for the leg it is currently
-- on.
--
-- An empty destination is not a failure of configuration: it means "the route
-- is already set, just fly it", which is what this bot did before it could set
-- routes at all. args[1] is the outward destination, args[2] the return one;
-- leg.pick chooses between them.
function M.main(args)
    local destination = leg.pick(args and args[1], args and args[2])
    if type(destination) == "string" and destination ~= "" then
        return "Success"
    end
    return "Failure"
end

return M
