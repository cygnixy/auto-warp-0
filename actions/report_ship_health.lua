local health = require("std.health")
local log = require("std.log")

local M = {}

-- Says, once, whether the ship's own health can be read — and presses nothing.
--
-- WHY A FLIGHT CARES ABOUT A FIGHT'S READING. The operator's requirement of
-- 2026-08-13, and it is about WHEN the trouble is heard rather than about the
-- flight itself. The health is the only sign a fight has for when to leave; on
-- 2026-08-13 11:35 it was missing for the whole run, and the first anybody heard
-- of it was the fight step saying so once a tick from inside the mission's pocket
-- — four jumps and several minutes after the last moment anybody could have done
-- anything about it. The setting is fixed at the keyboard, in a hangar, in five
-- seconds. So it is looked at here, while the ship is still on its way.
--
-- IT ONLY SAYS, and that is the whole difference from the fight's own use of the
-- same reading. A health nobody can read costs a flight nothing: this bot never
-- shoots, never takes damage it could avoid, and could not act on the number if
-- it had it. Failing the flight over it would strand a ship mid-route for the
-- sake of a setting only a human can change — punishing the mission for the
-- warning. mission-combat is where the same reading refuses, because that is
-- where acting without it means fighting to the explosion.
--
-- THE READING AND THE WORDS ARE std.health's, not this file's. Two bots ask this
-- now and a second copy of either would drift from the first on the first repair
-- — the same reason std.tabs, std.ship and std.survey are where they are. What
-- belongs here is the consequence, and the consequence of a flight is "carry on".
--
-- ONCE, NOT ONCE A TICK. A setting nothing but the operator will change, said
-- every tick of a four-jump flight, is a log nobody reads — which is what the run
-- of 11:35 produced. The mark holds the SENTENCE rather than a flag, so a health
-- that goes missing again later in the flight is news again.
--
-- AND THE THIRD ANSWER IS NOT THE SECOND. Straight after an undock, and through
-- every session change of the route, there is no ship panel to read a health
-- from. Blaming the operator's settings for that would be this project's own
-- besetting fault — an absence taken for a fact — committed inside the code
-- written to cure it. It is said at debug, it accuses nobody, and it mends itself.
--
-- NEITHER OF THEM GOES THROUGH log.repeated, AND THE LIVE RUN OF 12:39 IS WHY.
-- The first version of this action put the third answer through it at debug —
-- and log.repeated escalates: at the third, ninth and twenty-seventh repeat it
-- emits at WARN whatever level it was given, with "still trying" on the end. So
-- three session changes of one flight left four WARNINGS saying that a hangar is
-- not a setting anybody has to change, over a thing nobody was trying at. The
-- module's own comment says as much — "where repetition is normal, use M.debug: a
-- warning for expected behaviour teaches the reader to ignore warnings" — and a
-- session change on every jump is as normal as repetition gets.
--
-- So both answers are held under the SAME mark, and only the sentence decides.
-- One line per stretch, at the level the answer deserves, and a state that comes
-- back is news again. Which of the two the mark is holding never has to be asked:
-- two different sentences can never be equal.
--
-- Never Failure, and never Running: it waits for nothing, because there is
-- nothing of its own that it has done.

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
