local log = require("std.log")
local state = require("std.state")
local survey = require("std.survey")

local M = {}

-- Writes the ship's module panel down while the ship is in warp.
--
-- The walk is std.survey, shared with cygnixy/agent-missions, which used to
-- take it standing still right after the undock: ten slots at two ticks each,
-- some twenty seconds of every mission spent going nowhere. In warp that time
-- is spent anyway, so on 2026-08-13 the operator moved the survey here. Nothing
-- of the walk is decided in this file; the two answers below are.
--
-- args[1] is survey_ship, declared in main.btree. FALSE by default, and that is
-- deliberate: this bot is shared. Other missions fly with it and have no fight
-- ahead of them, and a survey they never asked for would spend ten hovers of
-- their flight on a blackboard key nobody reads. A mission that wants it says
-- so -- agent-mission-loop does, for its flight step.
--
-- Compared with true rather than tested for truth, and the opposite way round
-- from agent-missions' own survey_after_undock: there nil means "nobody said",
-- and the default is to survey; here nil means the same thing and the default
-- is not to. Whoever reads both should see the difference stated, not inferred.
--
-- The second answer is the timing, and it is a phase, read the way the tree
-- reads it (std.state, the same module phase_is asks). "In warp" is the whole
-- condition: not "in space", not "the module panel is drawn". The panel is
-- drawn and perfectly readable while the ship still sits at the undock point --
-- that is precisely how the survey came to be taken standing still — so a
-- survey that begins the moment it can read something would move nothing at all.
--
-- Stepping aside is Success, never Failure. This action sits at the end of the
-- flight's fallback, after the moves and the cloak, and the flight is worth
-- more than the survey: whatever the survey cannot do, the ship keeps flying.
-- args[2] is remember_module_names, declared in main.btree beside survey_ship
-- and handed straight through: nothing about it is decided here. It is a second
-- variable rather than a second meaning of the first because the two answer
-- different questions -- whether this flight owes a survey at all, and whether
-- what a survey learns outlives the run -- and a mission may want either
-- without the other. See std/modules.lua for what it turns on.
function M.main(args)
    local wanted = args and args[1]
    if wanted ~= true then
        return "Success"
    end
    local remember = args and args[2]

    local phase = state.phase()
    if phase ~= state.WARPING then
        log.steady("survey_not_in_warp", "info", "ship",
            "the ship is not in warp (" .. phase .. "): the survey waits until it is")
        return "Success"
    end

    return survey.take(remember)
end

return M
