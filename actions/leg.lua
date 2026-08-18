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
function M.pick(out_value, home_value)
    if M.current() == "home" then
        return M.trimmed(home_value)
    end
    return M.trimmed(out_value)
end

return M
