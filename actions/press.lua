local M = {}

-- Pressing something and letting the client answer before pressing it again.
--
-- An order and a press are not the same thing. Giving an order twice repeats
-- it and costs a gesture; pressing a toggle twice reverses it, and pressing a
-- button twice lands the second press on whatever the client has drawn in the
-- meantime. On 2026-08-05 the search panel was shut with the magnifier once
-- per tick: forty-three presses over twenty-two seconds, each undoing the
-- last, while the undock button waited behind them.
--
-- The pause is measured in milliseconds, not in ticks.
--
-- Ticks are not a unit of anything: the bot's tick lasts 1.11 seconds while
-- dumps are being saved and 0.59 without, so counting them made every pause in
-- this bot twice as long when the operator turned on a debugging aid. It made
-- the bot visibly steadier, which is a true observation about a mechanism that
-- should not exist. The client answers in its own time, and that time is what
-- these numbers describe.

-- A pressed control redraws quickly -- a panel toggles, a window closes, a
-- field clears. A second and a half is long enough to see it and short enough
-- that a lost press is retried before the tick after next.
local PATIENCE_MS = 1500

-- True while the last press under this key is still being given its chance.
-- Nothing recorded is -1, not 0: the clock starts at zero when the application
-- does, and a bot started in that first millisecond would have its first press
-- forgotten as never made. The virtual clock in the test harness starts at zero
-- always, which is how this was caught before it reached a ship.
local NONE = -1

function M.pending(key, patience_ms)
    local slot = "press_" .. key
    local since = cygnixy.bb_get(slot) or NONE
    if since < 0 then
        return false
    end
    if cygnixy.now_ms() - since >= (patience_ms or PATIENCE_MS) then
        cygnixy.bb_set(slot, NONE)
        return false
    end
    return true
end

-- Records that a press has just been made.
function M.made(key)
    cygnixy.bb_set("press_" .. key, cygnixy.now_ms())
end

-- Forgets the press: what it was for has happened, and the next one is new.
function M.done(key)
    cygnixy.bb_set("press_" .. key, NONE)
end

return M
