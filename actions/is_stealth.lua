local M = {}

-- Whether the ship is cloaked, read off the buff the client draws for it.
--
-- The loop is spelled with ipairs, though the bare `for _, name in buffs do`
-- it replaces was legal too: these actions run on Luau, whose generalized
-- iteration walks a table without one. Written out because the two forms are
-- not the same everywhere, and a reader who knows plain Lua reads the bare
-- one as an error.
--
-- The window is read once rather than twice. Nothing here was broken; it is
-- tidying an action that until now no case ran at all -- the cloak branch is
-- off by default (`stealth = false`), and an action nobody runs is an action
-- nobody tests.
function M.main(args)
    local shipui = cygnixy.eve.shipui
    local buffs = shipui and shipui.offensive_buff_button_names
    if type(buffs) == "table" then
        for _, buff_name in ipairs(buffs) do
            if buff_name == "CloakDefense" then
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
