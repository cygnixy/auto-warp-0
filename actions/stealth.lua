local log = require("std.log")
local press = require("std.press")

local M = {}

-- How long the cloak is given to show up in the ship panel.
--
-- The one wait in this bot that guards a toggle rather than an order, and the
-- reason it outlived the clearing-out of every other timer: repeating an order
-- is free, but F1 pressed twice uncloaks the ship it has just cloaked. The
-- buff takes a moment to appear, and without the wait the bot would undo its
-- own work on the next tick.
--
-- It used to be spelled in the tree as `is_timer_elapsed("stealth_timestamp",
-- 3)` and measured with os.time() -- whole seconds off the wall clock, the
-- last place in this bot counting that way after everything else moved to
-- cygnixy.now_ms(). Two consequences: three seconds meant anywhere between
-- three and four, and the harness could not test it at all, because its
-- virtual clock drives now_ms and not os.time. It is a press like any other
-- press now, spaced the way the magnifier and the undock button are.
local CLOAK_SETTLES_MS = 3000

function M.main(args)
    -- Pressed once, then given its chance.
    if press.pending("stealth", CLOAK_SETTLES_MS) then
        return "Running"
    end

    local vkF1 = 0x70
    -- The key goes to whichever window the system is looking at, so the client
    -- is raised first — and the raise's answer decides: while the operator
    -- holds the foreground elsewhere, F1 would land in their window, not in
    -- the game. Nothing is pressed then; the tree retries next tick.
    if not cygnixy.bring_to_front() then
        log.repeated("stealth", "debug", "client",
            "F1 was not pressed: the operator holds the foreground elsewhere")
        return "Running"
    end
    cygnixy.press_key(vkF1)
    -- Debug, and deliberately not counted: the cloak is pressed again every
    -- time the ship enters warp, so this line repeats all mission long by
    -- design. A warning for expected behaviour teaches the reader to skip
    -- warnings.
    log.debug("client", "cloak toggled with F1")
    press.made("stealth")
    return "Success"
end

return M
