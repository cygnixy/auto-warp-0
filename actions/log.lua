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
-- that, which comes back as a warning carrying the count.
--
-- The warning counts; it does not cap. Nothing here or anywhere else in this
-- bot gives up on an order because it has been given often: the flight loop
-- goes on ordering Dock until the ship is docked, however many attempts that
-- takes, and the count exists so that the operator can see the bot working
-- hard — a stargate behind a warp that keeps being interrupted looks exactly
-- like a bot pressing the wrong pixel, and only the count tells them apart.
-- The wording says so: an earlier "and nothing has changed" read as a bot
-- about to stop, which it never was.
--
-- A different message under the same key starts the count over, because the
-- situation has changed. So does M.forget, which journal calls whenever the
-- ship actually gets somewhere.
--
-- Use it where repetition means the bot is stuck. Where repetition is normal —
-- the cloak pressed once a minute for the whole flight — use M.debug: a
-- warning for expected behaviour teaches the reader to ignore warnings.
-- Repeats are reported at 3, 9, 27, 81 and so on rather than every third one.
--
-- A wait that lasts reports itself thirty times at one line per three ticks,
-- and thirty identical lines are not a signal but a wall: the flight of 19:50
-- spent a minute waiting for the foreground and left ninety warnings saying
-- so, none of which said anything the first had not. Spacing them out keeps
-- both halves of what the reader needs -- that it is still happening, and how
-- long for -- without burying the rest of the mission.
local FIRST = 3
local GROWTH = 3

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

    local mark = FIRST
    while mark < count do
        mark = mark * GROWTH
    end
    if mark == count then
        emit("warn", subject, message .. " — " .. count .. " times now, still trying")
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
