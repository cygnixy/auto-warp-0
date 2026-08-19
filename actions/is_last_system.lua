local route = require("std.route")

local M = {}

-- Whether the route panel names the very system the ship is in, read
-- through std.route.at_final_system() instead of a second hand-written
-- comparison of the same two fields. nil (either side unread) is not
-- arrival: it used to compare equal to itself and pass this off as
-- Success, a latent bug now closed by treating anything short of a
-- confirmed "true" as Failure.
function M.main(args)
    if route.at_final_system() then
        return "Success"
    end
    return "Failure"
end

return M
