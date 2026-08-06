local state = require("state")

local M = {}

-- Whether the client is showing a route.
--
-- Success and Failure are answers about the route; Running is what a client
-- that is not answering deserves. The route panel blanks while the session
-- changes -- it did five times in the flight of 19:57 -- and reporting Failure
-- then is a lie with consequences: this condition is the flight's exit test,
-- and a blank read at the wrong moment would end a mission mid-route with the
-- ship declaring it had arrived.
function M.main(args)
    local panel = cygnixy.eve.info_panel_container
    local route = panel and panel.info_panel_route
    if not route then
        return "Running"
    end

    -- The header counts the jumps, and it says so in every shape of the panel.
    -- The markers are drawn only by the expanded one: on 2026-08-05 the bot
    -- laid a route, met a collapsed panel with no markers in it, and read that
    -- as "no route" while the header said three jumps.
    local jumps = route.jumps
    if type(jumps) == "number" then
        if jumps > 0 then
            return "Success"
        end
        return "Failure"
    end

    local markers = route.route_element_marker
    if markers ~= nil and #markers > 0 then
        return "Success"
    end

    -- Nothing shown, and the client is mid-change: it is not saying there is
    -- no route, it is not saying anything. Undocking counts — the panel blanks
    -- there too, which is where the route was announced twice on 2026-08-05.
    if not state.settled(state.phase()) then
        return "Running"
    end

    return "Failure"
end

return M
