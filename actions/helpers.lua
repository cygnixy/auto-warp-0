local M = {}

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
