-- What to pick from the context menu of a route marker or a bookmark, in order
-- of preference, and the bookkeeping that follows a successful choice.
--
-- The list lives here rather than in each action because all three ways of
-- sending the ship somewhere — the route marker, the dock bookmark and the
-- undock bookmark — offer the same three entries and must agree on which one
-- wins.
local M = {}

M.choices = {
    { text = "Jump through stargate", partial_match = false },
    { text = "Dock",                  partial_match = false },
    { text = "Warp to",               partial_match = true },
}

-- Records that the ship has been sent somewhere. The tree waits on the
-- timestamp before it looks at the ship again, so a command that was issued but
-- not recorded is issued again a tick later.
function M.after_chosen(entry, state)
    cygnixy.info("CHOSE: " .. tostring(entry.text))
    cygnixy.bb_set("warp_timestamp", os.time())
    cygnixy.bb_set("_state", state or "warp")
end

return M
