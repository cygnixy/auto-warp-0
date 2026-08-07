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

-- Mission parameters come from a text box the operator types into, and an
-- invisible leading space is exactly the kind of thing a text box carries.
-- On 2026-08-07 at 05:58 a return destination of " Ansila V - ..." flew the
-- whole way out, turned home, typed its leading space into the search — and
-- stalled forever on "no row is named exactly", because row selection is
-- deliberately exact. The trim lives here, at the one gate every destination
-- value passes through.
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
