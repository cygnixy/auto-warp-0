local log = require("log")

local M = {}

function M.main(args)
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
    local now = os.time()
    cygnixy.bb_set("stealth_timestamp", now)
    return "Success"
end

return M
