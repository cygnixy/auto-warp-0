local stealthTime = bb_get("stealth")
if stealthTime ~= nil then
    local currentTime = os.time()
    local elapsed = currentTime - stealthTime
    if elapsed > 3 then
        return "Success"
    else
        return "Failure"
    end
else
    return "Success"
end
