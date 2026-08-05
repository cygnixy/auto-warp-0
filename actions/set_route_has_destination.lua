local M = {}

-- Whether the mission was given somewhere to go.
--
-- An empty destination is not a failure of configuration: it means "the route
-- is already set, just fly it", which is what this bot did before it could set
-- routes at all.
function M.main(args)
    local destination = args and args[1]
    if type(destination) == "string" and destination ~= "" then
        return "Success"
    end
    return "Failure"
end

return M
