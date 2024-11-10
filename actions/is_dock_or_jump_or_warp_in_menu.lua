local M = {}

function M.main(args)
    if eve.context_menus and eve.context_menus and #eve.context_menus > 0 and eve.context_menus[1].entries then
        for _, entry in eve.context_menus[1].entries do
            if entry.text and entry.enabled and (entry.text == "Jump through stargate" or entry.text == "Dock" or string.find(entry.text, "Warp to")) then
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
