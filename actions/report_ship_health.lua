local health = require("std.health")
local log = require("std.log")

local M = {}

-- Checks and reports whether ship HUD hitpoints (shield/armor/structure) are readable.
-- Emits warning during transit if HUD hitpoint readout is disabled in client settings.
-- Always returns "Success" so flight navigation is never delayed or halted.

local SAID = "flight_health_said"

function M.main()
    local readout = health.readout()

    if readout == health.READ then
        -- The mark is spent, so the next time the health is anything else it is
        -- news. An empty sentence is a sentence nothing will ever equal.
        cygnixy.bb_set(SAID, "")
        return "Success"
    end

    local message, level
    if readout == health.UNDRAWN then
        message = health.NOT_YET ..
            " — the flight carries on, and the health is looked at again when the " ..
            "panel is there"
        level = "debug"
    else
        message = health.ADVICE ..
            " — the flight carries on without it, but the fight at the end of this " ..
            "route will not start without it: fix it while the ship is still on its way"
        level = "warn"
    end

    if cygnixy.bb_get(SAID) == message then
        return "Success"
    end
    cygnixy.bb_set(SAID, message)
    if level == "warn" then
        log.warn("flight", message)
    else
        log.debug("flight", message)
    end
    return "Success"
end

return M
