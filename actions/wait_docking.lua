if eve.hero_notification and eve.hero_notification.texts then
    for _, text in eve.hero_notification.texts do
        if text == "Docking" then
            return "Success"
        end
    end
end
return "Running"
