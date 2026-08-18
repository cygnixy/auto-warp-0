local state = require("std.state")
local tabs = require("std.tabs")

local M = {}

-- Ensures the Overview window stays on the designated travel tab during flight navigation.
-- Uses `std.tabs` to verify and switch tabs without holding execution ticks.
--
-- @param args table args[1] = 1-based index of travel tab (or nil/0 if unconfigured)
-- @return string Always returns "Success"

local WORDS = {
    key = "select_travel_tab",
    subject = "flight",
    variable = "travel_tab",
    what = "the flight's own",
    work = "the flight",
}

function M.main(args)
    -- The operator's own number: the tab's place in the strip, counting from one.
    local wanted = args and args[1]

    -- A hangar has no overview to hold, and this guard is here rather than in the
    -- tree for the reason survey_ship gives for its own: an action is what a case
    -- can tick, and "docked, so nothing to do" is a state worth pinning with one.
    -- Without it a docked run would spend a minute on the wait for a strip nobody
    -- is drawing and then warn about it every third tick for as long as the ship
    -- sat there — a warning that means nothing is how a reader learns to ignore
    -- warnings.
    --
    -- Only DOCKED is stepped over, and not "anything that is not space": a client
    -- between things is exactly when the panels are blank, and std.tabs already
    -- waits that out under a budget of its own instead of reading an absence as a
    -- fact.
    if state.phase() == state.DOCKED then
        tabs.let_go(WORDS)
        return "Success"
    end

    tabs.hold(tabs.read(), wanted, WORDS)
    return "Success"
end

return M
