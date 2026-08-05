local state = require("state")

local M = {}

-- Succeeds when the client is in one of the phases named.
--
-- One condition in place of the five the tree used to carry — a timer, a
-- session check and three manoeuvre checks — which between them still could
-- not tell "free to act" from "between things", because none of them had a
-- name for the second.
function M.main(args)
    local now = state.phase()
    for _, wanted in ipairs(args or {}) do
        if wanted == now then
            return "Success"
        end
    end
    return "Failure"
end

return M
