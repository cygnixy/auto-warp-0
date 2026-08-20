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

-- Trims leading and trailing whitespace from destination string.
function M.trimmed(value)
    if type(value) ~= "string" then
        return value
    end
    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

-- The value for the current leg: the outward one until the turn, the
-- return one after it.
--
-- AN EMPTY LEG DEFERS TO THE RECOVERED DESTINATION, where one stands:
-- somewhere_to_fly writes _recovered_destination when a station-bound flight
-- was given nothing and no route stands (the restarted rescue of 2026-08-20
-- 13:35), and every reader of a destination comes through this function — so
-- the recovered name stands in for the emptiness everywhere at once, and for
-- a leg that carries its own value nowhere at all.
function M.pick(out_value, home_value)
    local picked
    if M.current() == "home" then
        picked = M.trimmed(home_value)
    else
        picked = M.trimmed(out_value)
    end
    if picked ~= nil and picked ~= "" then
        return picked
    end
    local recovered = cygnixy.bb_get("_recovered_destination")
    if type(recovered) == "string" and recovered ~= "" then
        return recovered
    end
    return picked
end

return M
