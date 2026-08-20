local log = require("std.log")
local pointer = require("std.pointer")
local press = require("std.press")
local ship = require("std.ship")
local state = require("std.state")

local M = {}

-- Tops up weapon magazines while the ship is in warp, once per flight.
--
-- WHY A FLIGHT BOT RELOADS AT ALL: mission-combat reloads on the warps it makes
-- itself — into the pocket and between its rooms — but the flight home after a
-- fight is this bot's, and until 2026-08-20 nothing on that flight touched the
-- magazines: a launcher that had fired the pocket dry flew home empty and began
-- the next mission that way. The warp legs of this bot are exactly the moments
-- a reload costs nothing — the guns are silent anyway, and the magazine fills
-- on the way.
--
-- NO THRESHOLD, AND NONE ON PURPOSE. mission-combat's reload keeps a store of
-- magazine sizes so as not to spend a gesture mid-mission on a weapon that is
-- two-thirds full; here the client itself is asked instead, once, because its
-- menu is the one source of truth this step needs: `Reload all` standing in a
-- module's menu IS the client saying the magazine is not full, and the entry's
-- absence is the client saying it is. One gesture per weapon per flight buys
-- that answer, and nothing empties a magazine between two warps of one flight,
-- so the answer holds for the rest of the step.
--
-- The survey this reads arrives under keep_ship_survey — written by whichever
-- step surveyed the ship, and carried across steps by its keep_ prefix. A run
-- of this bot alone, with no survey made, tops nothing up and says so once.

local CHOICES = {
    { text = "Reload all", partial_match = false },
}

local SURVEY = "keep_ship_survey"

-- The slot has answered for this flight — reloaded, or full by the client's
-- own menu. Not under keep_: the next step's flight asks again.
local DONE = "reload_done_"

-- Cooldown (ms) between menu gestures on one slot whose answer did not come.
local RELOAD_MS = 30000

function M.main(args)
    -- The operator's own list of what counts as a weapon, the same
    -- comma-separated substrings mission-combat's step is given. Empty is
    -- legal and means the tree knows of no weapons: nothing to load.
    local patterns = args and args[1] or ""
    if patterns == "" then
        return "Success"
    end

    -- IN WARP, AND NOWHERE ELSE. The phase is std.state's reading of the
    -- client's own manoeuvre indication; anything else — adrift, docking, a
    -- session change, an indication not drawn — is not a ship in warp, and a
    -- menu opened over the module bar then would hold the mouse in a moment
    -- the flight may need it.
    if state.phase() ~= state.WARPING then
        return "Success"
    end

    local survey = cygnixy.bb_get(SURVEY)
    if type(survey) ~= "table" or type(survey.slots) ~= "table" then
        log.steady("reload_no_survey", "info", "ship",
            "no ship survey on the blackboard — which slot is a weapon is not " ..
            "known here, so nothing is topped up on this flight")
        return "Success"
    end

    local matched = ship.matching_modules(survey, patterns)
    -- survey-table already checked above; matched is not nil here

    for _, m in ipairs(matched) do
        local key, record, slot = m.key, m.record, m.slot
        -- A module that is CYCLING is not one to open a menu over: the client
        -- would refuse the reload, and the gesture holds the input queue for
        -- the length of it. is_active is read with an explicit `== true`
        -- because the third answer — the panel not read at all — must not
        -- count as "dark".
        if cygnixy.bb_get(DONE .. key) ~= true
            and slot ~= nil and slot.point ~= nil and slot.is_active ~= true
            and not press.pending("reload_" .. key, RELOAD_MS) then
            -- ONE MODULE A TICK. The gesture is the host's: it holds the
            -- mouse, the menu and the choice together for as long as the
            -- client needs to draw them, and doing that twice in one tick
            -- would leave the second menu waiting on a window the first had
            -- let go of.
            press.made("reload_" .. key)
            local entry, why = pointer.open_menu_and_choose(slot.point, CHOICES)
            if entry ~= nil then
                cygnixy.bb_set(DONE .. key, true)
                log.info("ship",
                    record.name .. " (" .. key .. ") offered Reload all in its " ..
                    "menu — that entry is the client saying the magazine is not " ..
                    "full, so it was chosen, and it fills on the way; the weapon " ..
                    "is dark for the seconds that takes, which is why it is " ..
                    "ordered in a warp, where the guns are silent anyway")
            elseif string.find(tostring(why), "offers nothing from the wanted list",
                1, true) ~= nil then
                -- The answer this action came for, and the ordinary one: a menu
                -- that opened and offered no Reload all is a FULL magazine.
                cygnixy.bb_set(DONE .. key, true)
                log.steady("reload_full_" .. key, "debug", "ship",
                    record.name .. " (" .. key .. ") is full: its menu offers " ..
                    "no Reload all, which is the client's own answer to " ..
                    "\"is there anything to load\" — nothing is pressed")
            else
                -- A menu that never opened is a gesture that missed, not a full
                -- magazine: no answer is written down, and the slot is asked
                -- again on a later tick of this warp.
                log.repeated("reload_failed_" .. key, "warn", "ship",
                    "no reload was made on " .. record.name .. " (" .. key ..
                    "): " .. tostring(why) .. " — it is tried again while the " ..
                    "warp lasts")
            end
            return "Success"
        end
    end

    return "Success"
end

return M
