local log = require("std.log")
local state = require("std.state")
local survey = require("std.survey")

local M = {}

-- Executes ship module survey via `std.survey` during warp phase.
--
-- args[1] == false is the only way out: the survey is left to whoever else
-- flies this ship, said aloud so a mission that turns it off can be told
-- apart from one that never asked. nil and true both mean yes -- the same
-- polarity agent-missions uses for its own switch -- because silence from a
-- mission that never mentions survey_ship is not a mission that refuses the
-- survey, and a shared bot whose upgrade quietly starts hovering slots is a
-- worse surprise than one that starts surveying by default.
--
-- @param args table args[1] = survey_ship, args[2] = remember_module_names
-- @return string "Success", "Running", or "Failure"
function M.main(args)
    local wanted = args and args[1]
    if wanted == false then
        log.repeated("survey_elsewhere", "info", "ship",
            "the survey is left to whoever flies: survey_ship is off")
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
