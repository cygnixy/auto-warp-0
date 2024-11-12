local M = {}

function M.main(args)
    local vkF1 = 0x70
    press_key(vkF1)
    info("PUSHED F1")
    local now = os.time()
    bb_set("stealth_timestamp", now)
    return "Success"
end

return M
