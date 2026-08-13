local state = require("std.state")
local tabs = require("std.tabs")

local M = {}

-- Holds the overview on the tab the ship FLIES by, for the whole flight.
--
-- THE OPERATOR'S REQUIREMENT OF 2026-08-13, AND IT IS ABOUT SAFETY. That morning
-- the fight step (cygnixy/mission-combat) put the overview on the tab it fights
-- by before warping to the mission's place, and the ship was standing at a gate
-- in Niyabainen: on that tab, in an empire system, stand the empire's own customs
-- officers and sentry guns. The fight takes any row of its tab for an enemy, so
-- it ordered a lock on a Caldari Customs Commissioner twenty kilometres away.
-- Nothing but the warp beginning two seconds later kept the guns quiet.
--
-- The fight step now waits for the pocket before it puts that tab up. This action
-- is the other half, and neither replaces the other: a tab nobody holds is a tab
-- ANYBODY may have left anywhere — the operator, an earlier step, the client
-- itself — and the flight is where the ship spends its time among strangers. The
-- operator also flies by that tab themselves: they switched to it twice by hand
-- during the run of 10:22 to see an Acceleration Gate.
--
-- WHAT IT NEVER DOES IS HOLD THE FLIGHT UP. std.tabs answers "a press of mine is
-- in flight" and the fight step turns that into Running, because a row it is
-- about to press belongs to the tab that is being replaced. Nothing in this bot
-- reads an overview row at all: the route is flown off the route panel and the
-- ship's own manoeuvre. So every tick here answers Success, and a warp ordered on
-- the same tick is ordered on the same tick.
--
-- A NUMBER THE TREE DOES NOT HAND DOWN MEANS NOTHING IS SWITCHED, said once, and
-- there is no default to invent: which preset the operator flies by is a property
-- of a client somebody set up. std.tabs says that, and everything else about a
-- tab — the reading, the press, the pacing, the budgets — for both bots.

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
