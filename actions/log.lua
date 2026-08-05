-- How this bot talks to whoever reads lua.log.
--
-- Three rules, each of them bought with a log that misled its reader on
-- 2026-08-05, when a five-minute flight left fourteen lines that answered
-- none of the questions asked of them.
--
-- 1. A line names a subject and states a fact about the mission: "flight:
--    docked at Jita IV after 7 jumps", not "CHOSE: Dock". Paths into the
--    interface and menu contents are not facts about the mission; they belong
--    at debug level, where a reader looks only when hunting a fault.
--
-- 2. The level says what the reader is to do. info follows the mission, warn
--    marks what the bot is coping with, error marks what it cannot cope with
--    and is about to stop over. That day every line was info, so the one
--    milestone and the failures read exactly alike.
--
-- 3. A line is written when something changes. The tree re-runs an action for
--    as long as it returns Running, and one line per tick buries the story it
--    is meant to tell. But repetition is itself news — an order given three
--    times is an order not being obeyed — so repeats are counted rather than
--    swallowed, and come back as a warning that says how many.

local M = {}

-- Bound once: the host's own logger, one function per level. An unknown field
-- on the cygnixy table raises rather than returning nil, so a host too old to
-- carry a level fails here, loudly and at load, instead of silently logging
-- nothing for the rest of the mission.
local WRITE = {
    debug = cygnixy.debug,
    info = cygnixy.info,
    warn = cygnixy.warn,
    error = cygnixy.error,
}

local function emit(level, subject, message)
    WRITE[level](subject .. ": " .. message)
end

function M.debug(subject, message)
    emit("debug", subject, message)
end

function M.info(subject, message)
    emit("info", subject, message)
end

function M.warn(subject, message)
    emit("warn", subject, message)
end

function M.error(subject, message)
    emit("error", subject, message)
end

-- A line an action may produce on tick after tick, for as long as it keeps
-- returning Running.
--
-- The first occurrence reads at `level`. Identical repeats are not written
-- again — the reader has seen them — until the third, and every third after
-- that, which comes back as a warning carrying the count. Three identical
-- lines mean the bot has done the same thing three times to no effect: worth
-- attention even when one occurrence was not. A different message under the
-- same key starts the count over, because the situation has changed.
--
-- Use it where repetition means the bot is stuck. Where repetition is normal —
-- the cloak pressed once a minute for the whole flight — use M.debug: a
-- warning for expected behaviour teaches the reader to ignore warnings.
local NOISE = 3

function M.repeated(key, level, subject, message)
    local slot = "log_" .. key
    local counter = slot .. "_count"

    if cygnixy.bb_get(slot) ~= message then
        cygnixy.bb_set(slot, message)
        cygnixy.bb_set(counter, 1)
        emit(level, subject, message)
        return
    end

    local count = (cygnixy.bb_get(counter) or 1) + 1
    cygnixy.bb_set(counter, count)
    if count % NOISE == 0 then
        emit("warn", subject, message .. " — " .. count .. " times over, and nothing has changed")
    end
end

-- Forgets what was said under `key`, so that the next line is written as new.
-- Called when the thing the line was about has succeeded: the next time it
-- goes wrong is news again, not the continuation of an old complaint.
function M.forget(key)
    cygnixy.bb_set("log_" .. key, "")
    cygnixy.bb_set("log_" .. key .. "_count", 0)
end

-- "1 jump", "7 jumps", and nothing at all for none — a mission that docked in
-- the system it started in did not jump, and "after 0 jumps" says it worse.
function M.jumps(count)
    if count == nil or count < 1 then
        return nil
    end
    if count == 1 then
        return "1 jump"
    end
    return count .. " jumps"
end

return M
