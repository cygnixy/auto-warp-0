local undock_button = bb_get("undock")
if undock_button ~= nil then
    local currentTime = os.time()
    local elapsed = currentTime - undock_button
    if elapsed > 5 then
        return "Success"
    else
        return "Failure"
    end
else
    return "Success"
end
