local M = {}

function M.main(args)
    window_focus()
    local vkF1 = 0x70
    press_key(vkF1)
    info("PUSHED F1")
    local now = os.time()
    bb_set("stealth_start", now)
    return "Success"
end

return M
