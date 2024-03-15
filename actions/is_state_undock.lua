local state = bb_get("state")
if state == "undock" then
    return "Success"
end
return "Failure"
