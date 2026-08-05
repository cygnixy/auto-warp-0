local M = {}

function M.main(args)
    local vkF1 = 0x70
    -- The key goes to whichever window the system is looking at, so the client
    -- is raised first: pressed at the wrong moment, F1 lands in the operator's
    -- own window instead of activating the module.
    cygnixy.bring_to_front()
    cygnixy.press_key(vkF1)
    cygnixy.info("PUSHED F1")
    local now = os.time()
    cygnixy.bb_set("stealth_timestamp", now)
    return "Success"
end

return M
