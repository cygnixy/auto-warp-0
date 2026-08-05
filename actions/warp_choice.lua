-- What to pick from the context menu of a route marker or a bookmark, in order
-- of preference, and the bookkeeping that follows a successful choice.
--
-- The list lives here rather than in each action because all three ways of
-- sending the ship somewhere — the route marker, the dock bookmark and the
-- undock bookmark — offer the same three entries and must agree on which one
-- wins.
local log = require("log")

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
    -- Repeats are the point of counting here. The tree waits three seconds
    -- after an order and then, if the ship is still sitting still, gives the
    -- same one again — which is right when a menu click was lost and wrong
    -- when the client simply has not started moving. On 2026-08-05 "Dock" was
    -- ordered three times in sixty seconds and the log showed three identical
    -- lines with nothing to say they were the same order repeated.
    log.repeated("chose", "info", "flight",
        "ordered " .. tostring(entry.text) .. " from the menu")
    -- _state is intent — what was last ordered — and the bookmark branches
    -- read it to know which leg they are on. It is not a phase: the phase is
    -- what the client shows, and the two must not be confused again.
    cygnixy.bb_set("_state", state or "warp")
end

return M
