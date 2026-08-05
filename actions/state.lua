local M = {}

-- What the client is doing, as one answer instead of eight separate questions.
--
-- The bot used to ask "am I warping?", "am I jumping?", "is the session
-- changing?", "am I docked?" — each a yes/no over a different corner of the
-- interface, each drawn by the client at a different moment. In the middle of
-- a transition every one of them answers no, and "no to everything" was read
-- as "nothing is happening, act now". It is not: leaving a station, arriving
-- in a system and dropping out of warp all pass through a moment where the
-- station window has gone, the ship panel has not arrived, and no notice is on
-- screen. Orders given into that moment are lost, and the bot's answer to
-- losing them was a three-second timer — a guess wearing a clock's clothes.
--
-- So there is a phase, it is read from the client every tick, and "the client
-- is not saying" is one of its values rather than an absence of them.
--
--   docked       the station window is up: the ship is in a hangar
--   undocking    the client announces it, the station window has gone
--   docking      the client announces it, the ship is still in space
--   session      the session-change indicator is up; the client takes no
--                orders and a context menu opened now closes itself
--   warping      the ship panel shows the manoeuvre
--   jumping      likewise, the gate has been taken
--   approaching  likewise, including Orbit — the ship is closing on something
--   adrift       in space, no manoeuvre, nothing announced: free to be given
--                an order, and the only phase in which one should be
--   unknown      none of the above says anything. Between things: wait
--
-- Every read is spelled out here rather than behind a helper, because the path
-- lint follows a chain only within the function it starts in.

M.DOCKED = "docked"
M.UNDOCKING = "undocking"
M.DOCKING = "docking"
M.SESSION = "session"
M.WARPING = "warping"
M.JUMPING = "jumping"
M.APPROACHING = "approaching"
M.ADRIFT = "adrift"
M.UNKNOWN = "unknown"

-- A window that is not on screen arrives as an empty table, not as nil, so
-- presence is emptiness and not nil-ness.
local function present(value)
    return type(value) == "table" and next(value) ~= nil
end

function M.phase()
    -- Asked first: a docked client draws a ship panel too, with every field
    -- empty, so the ship panel alone never means space.
    local station = cygnixy.eve.station_window
    if present(station and station.buttons) then
        return M.DOCKED
    end

    -- The client's own announcement — the only signal that names a transition
    -- rather than leaving it to be inferred from what has disappeared.
    local hero = cygnixy.eve.hero_notification
    local texts = hero and hero.texts
    if texts ~= nil then
        for _, text in ipairs(texts) do
            if text == "Undocking" then
                return M.UNDOCKING
            end
            if text == "Docking" then
                return M.DOCKING
            end
        end
    end

    local session = cygnixy.eve.session_time_indicator
    if session and session.display == true then
        return M.SESSION
    end

    local shipui = cygnixy.eve.shipui
    local indication = shipui and shipui.indication
    local maneuver = indication and indication.maneuver_type
    if maneuver == "Warp" then
        return M.WARPING
    end
    if maneuver == "Jump" then
        return M.JUMPING
    end
    if maneuver == "Approach" or maneuver == "Orbit" then
        return M.APPROACHING
    end

    -- Shield, armour and structure are drawn for a ship that is flying and
    -- are empty for one in a hangar: on every reference dump the in-space ones
    -- carry all three and the docked ones carry none. This is what tells "in
    -- space with nothing happening" from "the client is between things", and
    -- without it the two were the same answer.
    local hitpoints = shipui and shipui.hitpoints_percent
    if present(hitpoints) then
        -- Speed lives here no longer. It says the ship is moving, which is not
        -- the same as "the order I gave is being obeyed": a ship pushed out of
        -- a station is moving with nobody having ordered anything, and on
        -- 2026-08-05 at 19:25 that stopped the bot dead — undocked, drifting,
        -- and never adrift again. What the speed is good for belongs next to
        -- the order it is evidence about, in open_route_menu_and_warp.
        return M.ADRIFT
    end

    return M.UNKNOWN
end

-- Whether the client's panels can be believed about anything at all.
--
-- Only four phases are settled: a hangar, and the three ways of being in
-- space with the ship panel drawn. The rest are transitions, and during a
-- transition the client blanks panels it is about to redraw -- the route
-- panel does it while undocking, while the session changes, and while the
-- screen is between systems. Read then, an empty panel says "no route" when
-- it means "not yet".
--
-- The cost of believing it: the journal announced the route a second time
-- mid-flight on 2026-08-05, and is_route_set -- which is the flight's exit
-- test -- answered Failure five times over on a route that was there all
-- along. A docked ship reading that at the wrong moment would call the
-- mission finished in the wrong system.
function M.settled(phase)
    return phase == M.DOCKED
        or phase == M.ADRIFT
        or phase == M.WARPING
        or phase == M.APPROACHING
end

-- Where the ship is, when the client is sure of it. nil is an answer: during a
-- session change and in the unknown the client says nothing about place, and
-- whoever is asking should keep what they had rather than take silence for
-- space.
function M.place(phase)
    if phase == M.DOCKED then
        return "station"
    end
    if phase == M.SESSION or phase == M.UNKNOWN then
        return nil
    end
    return "space"
end

return M
