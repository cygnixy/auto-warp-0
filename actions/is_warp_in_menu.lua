local M = {}

function M.main(args)
    if eve.context_menus and #eve.context_menus > 0 and #eve.context_menus[1].entries > 0 then
        for _, entry in eve.context_menus[1].entries do
            if string.find(entry.text, "Warp to") and entry.enabled then
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
