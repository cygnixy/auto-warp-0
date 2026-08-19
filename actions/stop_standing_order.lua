local act = require("std.act")
local log = require("std.log")
local patience = require("std.patience")
local route = require("std.route")
local scope = require("std.scope")
local state = require("std.state")
local text = require("std.text")

local M = {}

-- Cancels external standing maneuvers (e.g. Approach or Orbit) prior to issuing flight orders.
-- Does not interrupt in-flight warps, jumps, docking, or maneuvers initiated by this flight bot.

local STOP = "shipui.stop_button"

-- Pacing cooldown between Stop button click attempts.
local ORDER_MS = 5000

-- Timeout for standing order cancellation before escalating log warnings.
local STOP_MS = 15000

-- The press, the clock and the lines this action keeps between ticks.
local PRESS = "flight_stop"
local WAIT = "flight_stop"
local SAID = "flight_stop"
local LOUD = "flight_stop_deaf"
local NO_BUTTON = "flight_stop_no_button"
local REFUSED = "flight_stop_press"

-- That this action has taken an order on and has not seen the ship come out of
-- it yet.
--
-- WHAT IT IS FOR is telling the two silences apart: a ship at rest this action
-- never touched — every quiet tick of every flight — and a ship at rest because
-- the stopping worked. The first is said nothing about; the second is worth one
-- line, and it is the line that closes the story the stall opened.
--
-- Not under keep_: an order belongs to the run it was found in.
local STOPPING = "stopping_order"

-- The step's own memory of having sent the ship somewhere.
--
-- _state is written where an order to move is given and nowhere else — by
-- warp_choice.after_chosen for the three that come off a menu (the gate, the
-- dock, the warp) and by push_undock_button for the one that comes off a
-- button. A press is not an order: opening a menu, dismissing a message box,
-- pressing Stop itself leave it untouched, and so none of them can talk this
-- action out of its job.
--
-- Not under keep_ either, and that is what makes it safe to read here. The
-- board is wiped between mission steps, so the memory dies with the step that
-- made it: the next flight starts remembering no order of its own and takes a
-- standing one off exactly as it did before. A memory that outlived its step
-- would leave every later flight unable to unstick itself.
--
-- It is never unset within a step, and it is meant not to be. Once the ship has
-- been sent somewhere, whatever it is doing afterwards it is doing because this
-- flight asked — through the warp, through the gate, into the station — and
-- there is no tick left in the step on which pressing Stop would be right.
local ORDERED = "_state"

-- Has this flight ordered the ship anywhere yet in this step?
local function flight_has_ordered()
    local ordered = cygnixy.bb_get(ORDERED)
    return text.present(ordered)
end

-- Everything the stopping kept, dropped.
--
-- THE CLOCK ABOVE ALL. A budget left standing would be spent already the next
-- time an order strands this flight, and the second one would be called
-- hopeless on its first tick without a single press having been given a chance.
local function let_go()
    local marks = { clocks = { WAIT }, presses = { PRESS }, lines = { SAID, LOUD, NO_BUTTON, REFUSED }, board = {} }
    marks.board[STOPPING] = false
    scope.forget(marks)
end

function M.main(args)
    local phase = state.phase()

    if phase ~= state.APPROACHING then
        -- NOT APPROACHING IS NOT THE SAME AS "THE ORDER IS GONE", and the
        -- difference is state.settled: docked, adrift, warping and approaching
        -- are the phases whose panels may be believed, and the rest are the
        -- client between things, where the manoeuvre is as blank as everything
        -- else. Letting go on a blank would hand the next tick a fresh budget
        -- for an order that never went anywhere, once per session change.
        if cygnixy.bb_get(STOPPING) == true and state.settled(phase) then
            log.info("flight",
                "the manoeuvre this flight never ordered is off the ship — the client " ..
                "shows " .. phase .. " now, and the flight goes on giving its orders " ..
                "the way it always has")
            let_go()
        end
        return "Failure"
    end

    -- THE FIRST HALF OF THE RULE, and the one the loop of 16:02 was missing:
    -- an Approach that followed an order of this flight's is this flight's own,
    -- whatever the client calls it. Asked before anything else about the
    -- picture, because on a step that has ordered the ship somewhere there is
    -- no manoeuvre this action may touch at all and nothing further worth
    -- reading.
    --
    -- Letting go here as well as below: the stopping can only be under way if
    -- it began before the order was given, and a budget and a mark left
    -- standing would put the line about an order coming off the ship over a
    -- manoeuvre this flight asked for itself.
    if flight_has_ordered() then
        if cygnixy.bb_get(STOPPING) == true then
            let_go()
        end
        return "Failure"
    end

    -- THE OTHER HALF OF THE RULE: a route this flight was going to fly. An
    -- Approach standing on a ship with nowhere to go is not in anybody's way,
    -- and a bot that stops ships it has no plans for is a bot taking the
    -- operator's own orders off while they work.
    --
    -- Markers as well as the jump count, the reading is_route_set gives its
    -- reasons for at length: a collapsed route panel draws no markers while its
    -- header still counts the jumps, and an expanded one has been seen carrying
    -- markers with no count at all.
    local somewhere_to_go = route.has_route()
    if not somewhere_to_go then
        if cygnixy.bb_get(STOPPING) == true then
            let_go()
        end
        return "Failure"
    end

    -- The word for the order, for the lines only. The phase above is what
    -- decides; this says which of the two manoeuvres it was, so that the
    -- operator reading the log knows whether the ship was closing on something
    -- or circling it.
    local shipui = cygnixy.eve.shipui
    local indication = shipui and shipui.indication
    local manoeuvre = indication and indication.maneuver_type
    if type(manoeuvre) ~= "string" then
        manoeuvre = "a manoeuvre"
    end

    -- A window that is not on screen arrives as an empty table rather than as
    -- nil, so a button is a button by having a place, not by not being nil.
    local button = shipui and shipui.stop_button
    local drawn = type(button) == "table" and type(button.x) == "number"

    if cygnixy.bb_get(STOPPING) ~= true then
        cygnixy.bb_set(STOPPING, true)
    end

    -- Started on the first tick this action takes the order on, and read on
    -- every one after: what it measures is the client's answer to our presses,
    -- and it is the one thing standing between this and the wait that had no end.
    local deaf = patience.gave_up(WAIT, STOP_MS)

    if not drawn then
        -- NOT DRAWN YET IS NOT ABSENT. The ship panel arrives in its own time,
        -- and a button missing from one tick's tree is a button to wait for.
        -- What tells that from a panel that will never draw one is the budget
        -- and nothing else, which is why the same clock covers both.
        if deaf then
            log.repeated(NO_BUTTON, "warn", "flight",
                "the ship has been under " .. manoeuvre .. " for " .. STOP_MS ..
                "ms and the ship panel has drawn no Stop button in all that time — the " ..
                "order cannot be taken off from here, and this flight can give none of " ..
                "its own until somebody takes it off")
            return "Failure"
        end
        log.steady(SAID, "info", "flight",
            "the ship is under " .. manoeuvre .. ", which this flight never ordered, " ..
            "and the ship panel has not drawn its Stop button yet — waiting for it " ..
            "rather than pressing where a button may not be")
        return "Running"
    end

    -- Rate-limit Stop clicks to prevent toggling the order before the client responds.
    local outcome, reason = act.click(PRESS, STOP, { pace_ms = ORDER_MS })
    if outcome == act.WAITING or outcome == act.REFUSED then
        -- The host refused the gesture — the operator is working in another
        -- window, most likely. Nothing of ours reached the client, so this
        -- is not the client refusing to stop, and it is said as its own
        -- sentence.
        log.repeated(REFUSED, "warn", "flight",
            "Stop was not pressed: " .. tostring(reason))
    end

    if deaf then
        log.repeated(LOUD, "warn", "flight",
            "the client still shows the ship under " .. manoeuvre .. " " .. STOP_MS ..
            "ms after Stop was first pressed — the ship is not taking orders, and this " ..
            "flight can give none until it does; Stop goes on being pressed at the " ..
            "same pace")
        return "Failure"
    end

    log.steady(SAID, "info", "flight",
        "the ship is under " .. manoeuvre .. ", which this flight never ordered, and " ..
        "there is a route to fly — pressing the ship panel's own Stop, because an " ..
        "Approach never ends by itself and an order given to a ship already under one " ..
        "is lost")
    return "Running"
end

return M
