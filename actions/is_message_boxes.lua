local M = {}

-- The field is a list, and it is present whether or not the client is showing a
-- box: with no box it is empty rather than absent. Testing it against nil
-- therefore always answered Success, and the tree walked into pressing a button
-- of a message box that was not on screen.
function M.main(args)
    local boxes = cygnixy.eve.message_boxes
    if boxes ~= nil and #boxes > 0 then
        return "Success"
    end
    return "Failure"
end

return M
