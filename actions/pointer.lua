-- Pointer discipline, provided by the Cygnixy host.
--
-- A target is either a path into the parsed interface
-- ("station_window.buttons.Undock") or a region {x=, y=, width=, height=}.
-- Prefer the path: along it the point is worked out with the windows lying on
-- top of the target taken into account, and the centre of a button half covered
-- by another window leads where the click will not land.
--
-- Regions in the interface are client coordinates — they are counted from the
-- corner of the game window's client area. The older cygnixy.mouse_move and
-- cygnixy.mouse_click_* expect screen ones, so on a window moved off the corner
-- of the first monitor every click missed the game entirely. Nothing is
-- translated by hand here: cygnixy.click and cygnixy.click_path take client
-- coordinates and translate them themselves.

local M = {}

-- The centre of a region.
function M.center(region)
    return region.x + region.width // 2, region.y + region.height // 2
end

-- Clicks a target, bringing the game window to the front first.
--
-- The cursor is real: the press goes wherever the system is looking, so the
-- window is raised first. Returns true, or false and the reason.
function M.click(target, button)
    cygnixy.bring_to_front()
    return M.click_now(target, button)
end

-- Clicks without raising the window — for a press inside a menu already open.
--
-- Raising the window again sends it focus-change messages, and the client
-- closes the context menu on them: from the outside it looks like "the menu
-- opened, the entry was pressed, nothing happened".
function M.click_now(target, button)
    if type(target) == "string" then
        return cygnixy.click_path(target, button)
    end
    if type(target) ~= "table" or target.x == nil or target.width == nil then
        return false, "the target is neither a path nor a region"
    end
    local x, y = M.center(target)
    return cygnixy.click(x, y, button)
end

-- Right-clicks a target, waits for the menu and picks an entry — in one
-- gesture performed by the host.
--
-- The host holds the input queue for the whole gesture, which no Lua-side
-- loop could do: between the right button and the choice nobody else moves
-- the cursor or raises a window, so the menu survives until it is used.
-- The host also owns the polling (the client draws the menu a frame late or
-- more) and the escape between targets when several are offered — the route
-- panel carries up to two markers, and the first is not always the gate.
--
-- target may be a path, a region, or a list of either, tried in turn.
-- choices is a list of {text=, partial_match=} in order of preference;
-- matching ignores case and skips disabled entries. Returns the chosen entry
-- ({text=, region=, ...}), or nil and the reason.
function M.open_menu_and_choose(target, choices)
    return cygnixy.open_menu(target, choices)
end

return M
