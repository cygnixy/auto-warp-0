-- Pointer discipline, taken from the Cygnixy MCP server.
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
local helpers = require("helpers")

local M = {}

-- One target or several. A path is a string and a region is a table with x, so
-- anything else that is a table is already a list.
local function as_list(target)
    if type(target) == "string" then
        return { target }
    end
    if type(target) == "table" and target.x ~= nil then
        return { target }
    end
    return target
end

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

-- Right-clicks a target, waits for the menu and picks an entry — in one action.
--
-- Doing it in two does not work: between them the game window loses the
-- foreground, the next raise dismisses the open menu, and the press lands on
-- whatever ended up under the cursor. So the window is raised once, before the
-- right button, and never again.
--
-- The menu does not appear in the same instant as the press: the client draws
-- it on the next frame, or later still. One guess at a delay fits neither a
-- fast client nor a loaded one, so the state is re-read by polling.
--
-- choices is a list of {text=, partial_match=} in order of preference, as
-- helpers.find_entry_by_priority reads it. Returns the chosen entry, or nil and
-- the reason.
--
-- target may also be a list of targets, tried in turn until one of them offers
-- something from the list. The route panel carries two markers on the leg into
-- a system, and the first of them is the system just reached: right-clicking it
-- opens "Show Info, Add Waypoint, Avoid <system>" and nothing to fly by.
function M.open_menu_and_choose(target, choices)
    local targets = as_list(target)
    local reason = "no target to open a menu on"
    for index, one in ipairs(targets) do
        local entry, err = M.open_one_menu(one, choices)
        if entry ~= nil then
            return entry
        end
        reason = err
        -- The menu of the previous target may still be up, and the next target
        -- can sit close enough for the press to land inside it.
        if index < #targets then
            cygnixy.press_key(0x1B)
            cygnixy.sleep(120)
        end
    end
    return nil, reason
end

-- One target: the right button, the wait for the menu and the choice.
function M.open_one_menu(target, choices)
    cygnixy.bring_to_front()

    local opened, err = M.click_now(target, "right")
    if not opened then
        return nil, "the right button was not pressed: " .. tostring(err)
    end

    local entries = nil
    for attempt = 1, 5 do
        cygnixy.sleep(attempt == 1 and 120 or 200)
        cygnixy.update_eve()
        local menus = cygnixy.eve.context_menus
        if menus and #menus > 0 and menus[1].entries and #menus[1].entries > 0 then
            entries = menus[1].entries
            break
        end
    end

    if entries == nil then
        return nil, "no context menu opened; nothing there answers the right button"
    end

    local entry = helpers.find_entry_by_priority(entries, choices)
    if entry == nil then
        return nil, "the menu offers nothing from the wanted list: " .. helpers.list_texts(entries)
    end
    if entry.region == nil then
        return nil, "the entry " .. tostring(entry.text) .. " has no coordinates to click"
    end

    local chosen, click_error = M.click_now(entry.region, "left")
    if not chosen then
        return nil, "the entry " .. tostring(entry.text) .. " was not clicked: " .. tostring(click_error)
    end
    return entry
end

return M
