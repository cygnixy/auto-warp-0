local M = {}

function M.main(args)
    local vkF1 = 0x70
    -- The key goes to whichever window the system is looking at, so the client
    -- is raised first — and the raise's answer decides: while the operator
    -- holds the foreground elsewhere, F1 would land in their window, not in
    -- the game. Nothing is pressed then; the tree retries next tick.
    if not cygnixy.bring_to_front() then
        cygnixy.info("STEALTH: the client window is not in the foreground; F1 was not pressed")
        return "Running"
    end
    cygnixy.press_key(vkF1)
    cygnixy.info("PUSHED F1")
    local now = os.time()
    cygnixy.bb_set("stealth_timestamp", now)
    return "Success"
end

return M
