local log = require("std.log")
local survey = require("std.survey")

local M = {}

-- Executes static ship module survey via `std.survey` when mission destination requires no warp.
--
-- @param args table args[1] = survey_ship, args[2] = remember_module_names
-- @return string "Success", "Running", or "Failure"
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
