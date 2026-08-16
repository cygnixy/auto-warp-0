local log = require("std.log")
local patience = require("std.patience")
local pointer = require("std.pointer")
local press = require("std.press")
local state = require("std.state")

local M = {}

-- Takes off a manoeuvre this flight never ordered, so that it can order
-- anything at all.
--
-- THE RUN OF 2026-08-16, twice in one morning — 08:07 and 08:42 in the log's
-- own UTC. The fight step of the same mission ordered an Approach at a wreck to
-- collect it and the collecting ended; the client went on flying the ship at
-- Corpior Templar Wreck, fifteen metres off, because Approach in EVE NEVER
-- ENDS: the ship arrives, presses itself against the thing, and goes on
-- approaching for as long as anybody lets it. The flight that ran next found
-- `phase: approaching`, and this bot acts from rest and from nowhere else, so
-- every branch of its tree answered Failure and it did nothing whatever —
-- five and a half minutes the first time, nine and a half the second, the route
-- to Perimeter laid and the ship standing still. The order outlives the bot
-- that gave it: the second stall was a fresh run on a fresh mission.
--
-- THE DOCTRINE IS NOT WEAKENED, IT IS SERVED. "An order is given from rest" is
-- the rule of the whole project and it stays. What this action changes is that
-- the rest is now FETCHED rather than waited for: the ship panel has a Stop
-- button, it is the same gesture the operator uses to unpick this by hand, and
-- pressing it costs a ship that was resting anyway nothing at all.
--
-- THE ORDER IT TAKES OFF IS THE ONE IT FOUND, NEVER THE ONE IT GAVE, and that
-- distinction was bought with the run of 2026-08-16, 16:02 to 16:05 UTC — the
-- first flight after the paragraphs above were written. "Jump through stargate"
-- IN EVE IS AN APPROACH: the client takes the order, flies the ship at the gate
-- under an Approach of its own, and jumps when it arrives. Read as somebody
-- else's manoeuvre, that Approach was pressed off the ship one second after it
-- was asked for — ordered, stopped, ordered, stopped, nine rounds in three
-- minutes, every dumped frame reading speed 0.0 with the one route marker to
-- Perimeter still standing at the end. Dock is the same shape and would have
-- cost the same: it too is carried out as an approach.
--
-- SO THE MEMORY BELOW DECIDES. Once this flight has sent the ship anywhere in
-- this step, every Approach after it is the client carrying that out, and there
-- is nothing here to take off. Until it has, an Approach on the ship came from
-- outside the step and is exactly what this action is for.
--
-- IT IS A NET UNDER cygnixy/mission-combat AND NOT A REPLACEMENT FOR IT. Since
-- 0.34.0 that step takes its own Approach off when the collecting ends
-- (loot_the_wrecks.stand_down), which is right — whoever gives a standing order
-- takes it off. This one covers the orders nobody is going to come back for: one
-- left by an older version, one the operator gave by hand, one from a step that
-- died mid-errand. It never asks whose the order was, because it cannot know and
-- because the answer would not change what has to be done.
--
-- WHAT IT WILL NOT TOUCH, and the list is the point of the action rather than a
-- footnote to it: warping, jumping, docking, undocking, a session change, and
-- the unknown. There is nothing to stop in any of them — a warp is not a
-- standing order, it is a journey the client is running — and Stop pressed
-- there would either be refused or would throw away a jump this flight is in
-- the middle of. The phase decides, never the button: the live frames of that
-- morning draw the Stop button through the warp and through the session change
-- just as they draw it through the stall, so "the button is on screen" says
-- nothing at all about whether there is an order to take off.
--
-- Every read of cygnixy.eve is spelled out whole inside M.main: the path lint
-- follows a chain only within the function it starts in.

-- The ship panel's own Stop button, addressed by path and not by region — the
-- rule every press in this bot is made under (see std.pointer): along a path the
-- host works the click point out with whatever lies over the button taken into
-- account, and the ship panel is the one strip of the screen a chat window or an
-- inventory is most likely to be resting on.
local STOP = "shipui.stop_button"

-- How long one press of Stop stands before it is made again, in milliseconds.
--
-- Five seconds, and it is cygnixy/mission-combat's own pace for the same button
-- rather than a number invented here: a reading of the client may be up to 4.8
-- seconds old (measured 2026-08-11), so anything shorter presses a second time
-- at a panel that could not yet be showing the answer to the first.
local ORDER_MS = 5000

-- How long the ship is given to come out from under the order before the
-- trouble is said out loud, in milliseconds.
--
-- Fifteen seconds — three times the age a reading may have, and three presses.
-- It is a budget for SAYING and not for giving up: past it the button goes on
-- being pressed at the same pace, because there is nothing else this flight can
-- do and no number of attempts makes an order wrong (see std.log on why the
-- count is the news). What it buys is that the operator hears about a client
-- that will not let go, instead of reading five minutes of silence.
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
    return type(ordered) == "string" and ordered ~= ""
end

-- Everything the stopping kept, dropped.
--
-- THE CLOCK ABOVE ALL. A budget left standing would be spent already the next
-- time an order strands this flight, and the second one would be called
-- hopeless on its first tick without a single press having been given a chance.
local function let_go()
    cygnixy.bb_set(STOPPING, false)
    patience.forget(WAIT)
    press.done(PRESS)
    log.forget(SAID)
    log.forget(LOUD)
    log.forget(NO_BUTTON)
    log.forget(REFUSED)
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
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    local jumps = route and route.jumps
    local markers = route and route.route_element_marker
    local somewhere_to_go = (type(jumps) == "number" and jumps > 0)
        or (type(markers) == "table" and #markers > 0)
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

    -- ONCE, AND THEN THE CLIENT IS GIVEN ITS CHANCE. Stop is a button and not an
    -- order: a second press inside the pace lands on a panel that has not had
    -- time to answer the first, and the run of 2026-08-05 is what that costs —
    -- forty-three presses in twenty-two seconds, each undoing the last.
    if not press.pending(PRESS, ORDER_MS) then
        local pressed, reason = pointer.click(STOP)
        press.made(PRESS)
        if not pressed then
            -- The host refused the gesture — the operator is working in another
            -- window, most likely. Nothing of ours reached the client, so this
            -- is not the client refusing to stop, and it is said as its own
            -- sentence.
            log.repeated(REFUSED, "warn", "flight",
                "Stop was not pressed: " .. tostring(reason))
        end
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
