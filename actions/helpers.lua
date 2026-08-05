local M = {}

-- Function to find an entry from a list based on target texts and match criteria.
-- entries: A list of entries, each containing `text` and `enabled` properties.
-- target_texts_with_match: A list of target texts, each with a `text` and `partial_match` property.
-- The function returns the first matching entry based on the specified priority order in target_texts_with_match.
-- Matching ignores case, the way the MCP server matches menu entries: client
-- builds word them differently, and "Warp to" against "Warp To" must not decide
-- whether the ship moves. A disabled entry is never chosen: clicking it does
-- nothing.
function M.find_entry_by_priority(entries, target_texts_with_match)
    for _, target in ipairs(target_texts_with_match) do
        local wanted = string.lower(target.text)
        local partial_match = target.partial_match

        for _, entry in ipairs(entries) do
            if entry.text and entry.enabled then
                local text = string.lower(entry.text)
                if (partial_match and string.find(text, wanted, 1, true)) or (not partial_match and text == wanted) then
                    return entry
                end
            end
        end
    end
    return nil
end

-- The texts a menu offered, as one line. A refusal has to say what was actually
-- on offer, otherwise there is nothing in it to fix the bot by.
function M.list_texts(entries)
    local texts = {}
    for _, entry in ipairs(entries) do
        if entry.text then
            texts[#texts + 1] = entry.text
        end
    end
    return table.concat(texts, ", ")
end

return M
