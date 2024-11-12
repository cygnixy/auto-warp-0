local M = {}

-- Function to find an entry from a list based on target texts and match criteria.
-- entries: A list of entries, each containing `text` and `enabled` properties.
-- target_texts_with_match: A list of target texts, each with a `text` and `partial_match` property.
-- The function returns the first matching entry based on the specified priority order in target_texts_with_match.
function M.find_entry_by_priority(entries, target_texts_with_match)
    for _, target in ipairs(target_texts_with_match) do
        local target_text = target.text
        local partial_match = target.partial_match

        for _, entry in ipairs(entries) do
            if entry.text and entry.enabled then
                if (partial_match and string.find(entry.text, target_text)) or (not partial_match and entry.text == target_text) then
                    return entry
                end
            end
        end
    end
    return nil
end

return M
