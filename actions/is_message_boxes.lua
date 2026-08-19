local dialog = require("std.dialog")

local M = {}

-- The field is a list, and it is present whether or not the client is showing a
-- box: with no box it is empty rather than absent. dialog.boxes reads that
-- emptiness as nil, which is the whole point of asking it.
function M.main(args)
    if dialog.boxes() ~= nil then
        return "Success"
    end
    return "Failure"
end

return M
