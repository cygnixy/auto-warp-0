-- What to pick from the context menu of a route marker or a bookmark, in order
-- of preference, and the bookkeeping that follows a successful choice.
--
-- The list lives here rather than in each action because all three ways of
-- sending the ship somewhere — the route marker, the dock bookmark and the
-- undock bookmark — offer the same three entries and must agree on which one
-- wins.
local log = require("std.log")
local order = require("std.order")

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
    -- Logs menu order issuance with deduplication across repeat ticks.
    log.repeated("chose", "info", "flight",
        "ordered " .. tostring(entry.text) .. " from the menu")
    -- _state is intent — what was last ordered — and the bookmark branches
    -- read it to know which leg they are on. It is not a phase: the phase is
    -- what the client shows, and the two must not be confused again.
    cygnixy.bb_set("_state", state or "warp")

    -- An order is outstanding until the client shows it has been taken, and
    -- order.lua owns that mark. All three ways of sending the ship somewhere
    -- come through here, so this is the one place it is set: the route marker
    -- used to set it twice over, once here and once at its own call site, with
    -- order_ticks -- a leftover of the days when waits were counted in ticks
    -- and read by nobody -- set alongside it.
    order.issue()
end

return M
