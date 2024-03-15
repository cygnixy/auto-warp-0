local warpTime = bb_get("warp")
if warpTime ~= nil then
    local currentTime = os.time()
    local elapsed = currentTime - warpTime
    if elapsed > 3 then
        return "Success"
    else
        return "Failure"
    end
else
    return "Success"
end
