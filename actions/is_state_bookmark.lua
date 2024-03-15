local state = bb_get("state")
if state == "bookmark" then
    return "Success"
end

return "Failure"
