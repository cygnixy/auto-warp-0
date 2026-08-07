local M = {}

-- Which leg the mission is on. "out" until the outward route is flown,
-- "home" after legs_done turns the mission around. Lives on the blackboard
-- so the journal and every set_route action agree; journal resets it to
-- "out" when a mission starts.
function M.current()
    if cygnixy.bb_get("_leg") == "home" then
        return "home"
    end
    return "out"
end

-- The value for the current leg: the outward one until the turn, the
-- return one after it.
function M.pick(out_value, home_value)
    if M.current() == "home" then
        return home_value
    end
    return out_value
end

return M
