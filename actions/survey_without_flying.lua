local log = require("std.log")
local survey = require("std.survey")

local M = {}

-- The survey this flight owes, taken standing still because there will be no
-- warp to take it in.
--
-- THE HOLE THIS FILLS WAS DUG BY THE FIX ABOVE IT. The survey moved into warp
-- on 13 August, where the twenty seconds it costs are spent flying anyway
-- (survey_ship.lua). Then the same day the flight learnt to end on its first
-- tick when there is nothing to fly — and for a mission given in the agent's
-- own system there is no warp at all, so there was no survey either. The fight
-- step of 17:11 said it three times over: no ship survey on the blackboard, so
-- the defence could not be checked, nor the weapons, nor the speed. The target
-- was taken and closed with, and there was nothing to shoot it with.
--
-- HERE IS THE ONLY SENSIBLE PLACE FOR IT. The ship is standing in space with
-- nothing to do; the module panel is drawn and its tooltips are the ones the
-- fight will need. In the pocket the same twenty seconds are spent under fire,
-- and in the hangar the slots say something else entirely.
--
-- args[1] is survey_ship, the same variable survey_ship.lua reads and with the
-- same meaning: false by default, because this bot is shared and a mission with
-- no fight ahead of it has no use for ten hovers. Compared with true rather
-- than tested for truth — nil means "nobody said", and the default is not to.
--
-- Nothing about the walk is decided here. std.survey.take resumes a survey
-- already begun, starts over on a ship that has changed shape, answers Success
-- the moment a complete one is on the board, and steps aside on a panel it
-- cannot read: asking it every tick is the whole of the bookkeeping, and
-- checking the blackboard first would only risk throwing away a walk half done.
--
-- A SURVEY THAT CANNOT BE TAKEN DOES NOT STOP THE STEP. take answers Failure
-- when the cursor cannot be put on a slot at all — the operator holding the
-- foreground for two minutes, most likely — and the flight is worth more than
-- the survey, exactly as survey_ship says in the other branch. It is said at
-- warn, where somebody looks, because the fight step will otherwise report the
-- same absence three times with no cause attached.
--
-- IT IS BOUNDED, and that matters because flight_progress is watching from
-- above: nothing about the ship changes while the walk runs, so its fifteen
-- minutes are ticking throughout. Every path inside take has an end — five
-- seconds a tooltip over ten slots, two minutes for a foreground that will not
-- yield, its own budget for a ship that keeps changing shape — and the longest
-- of them is minutes, not a quarter of an hour. The walk cannot outlast the
-- watch.
-- args[2] is remember_module_names, the same variable survey_ship.lua reads and
-- with the same meaning, handed straight through. A survey taken standing still
-- is the one this ship will fight on, so it is worth remembering exactly as much
-- as the one taken in warp.
function M.main(args)
    if args[1] ~= true then
        return "Success"
    end

    local outcome = survey.take(args[2])
    if outcome == "Failure" then
        log.repeated("survey_standing", "warn", "ship",
            "the ship could not be surveyed standing still — the fight step will " ..
            "find no survey on the blackboard, and this is why")
        return "Success"
    end
    return outcome
end

return M
