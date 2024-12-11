local M = {}

function M.main(args)
    if cygnixy.eve.hero_notification and cygnixy.eve.hero_notification.texts then
        for _, text in cygnixy.eve.hero_notification.texts do
            if text == "Undocking" then
                return "Success"
            end
        end
    end
    return "Failure"
end

return M
