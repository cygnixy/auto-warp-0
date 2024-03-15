if eve.standalone_bookmark_window and eve.standalone_bookmark_window.entries then
    for _, entry in ipairs(eve.standalone_bookmark_window.entries) do
        if entry and entry[1] and string.find(entry[1], "Undock") then
            return "Success"
        end
    end
end
return "Failure"
