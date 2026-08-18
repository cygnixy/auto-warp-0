local log = require("std.log")
local state = require("std.state")
local survey = require("std.survey")

local M = {}

-- Executes ship module survey via `std.survey` during warp phase.
-- If ship is not currently warping or `survey_ship` is false, succeeds immediately.
--
-- @param args table args[1] = survey_ship, args[2] = remember_module_names
-- @return string "Success", "Running", or "Failure"
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
