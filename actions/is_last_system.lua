if eve.info_panel_container then
    local info_panel = eve.info_panel_container.info_panel_location_info
    local route = eve.info_panel_container.info_panel_route
    if info_panel and route then
        if route.next_system == info_panel.current_solar_system_name then
            return "Success"
        end
    end
end
return "Failure"
