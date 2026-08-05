local M = {}

-- Pressing something and letting the client answer before pressing it again.
--
-- An order and a press are not the same thing. Giving an order twice repeats
-- it and costs a gesture; pressing a toggle twice reverses it, and pressing a
-- button twice lands the second press on whatever the client has drawn in the
-- meantime. The bot's own rule, written down when the cloak's timer was kept:
-- repeating an order is free, repeating a press is not.
--
-- It was then broken anyway. On 2026-08-05 at 19:25 the search panel was shut
-- with the magnifier, which is a toggle, once per tick: forty-three presses
-- over twenty-two seconds, each undoing the last, before one of them happened
-- to be the one that stuck. The operator watched the bot fight itself while
-- the undock button waited.
--
-- So a press is followed by a pause measured in observations of the client:
-- three ticks, in which the panel it toggled has a chance to answer. If the
-- client has answered, the caller stops asking and the pause is forgotten; if
-- it has not, the press is made again. Nothing here judges the client — it
-- only refuses to talk over it.

local PATIENCE = 3

-- True while the last press under this key is still being given its chance.
function M.pending(key, patience)
    local slot = "press_" .. key
    local ticks = cygnixy.bb_get(slot) or 0
    if ticks == 0 then
        return false
    end
    if ticks >= (patience or PATIENCE) then
        cygnixy.bb_set(slot, 0)
        return false
    end
    cygnixy.bb_set(slot, ticks + 1)
    return true
end

-- Records that a press has just been made.
function M.made(key)
    cygnixy.bb_set("press_" .. key, 1)
end

-- Forgets the press: what it was for has happened, and the next one is new.
function M.done(key)
    cygnixy.bb_set("press_" .. key, 0)
end

return M
