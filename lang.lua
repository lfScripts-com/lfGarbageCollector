Lang = {
    ui_start_service = "Appuyez sur ~g~~INPUT_CONTEXT~~w~ pour ~b~commencer~w~ votre service",
    ui_stop_service = "Appuyez sur ~g~~INPUT_CONTEXT~~w~ pour ~r~terminer~w~ votre service",

    blip_trash = "Poubelle",

    spawn_blocked = "~r~La zone de spawn est bloquée par un véhicule. Veuillez libérer la zone.",

    help_pick_trash = "Appuyez sur ~g~~INPUT_CONTEXT~~w~ pour ~y~ramasser la poubelle~w~",
    carry_to_truck = "~y~Apportez le sac~w~ à l'arrière du ~b~camion~w~ et appuyez sur ~g~INPUT_CONTEXT~w~ pour le jeter",
    help_throw_bag = "Appuyez sur ~g~~INPUT_CONTEXT~~w~ pour ~b~jeter le sac~w~",

    bag_thrown = "Sac jeté ! ~g~Total : ~y~{count} ~w~sacs",

    service_finished = "~g~Service terminé ! ~b~Merci de votre travail.",

    truck_not_returned_half_pay = "~r~Vous n'avez pas rendu le camion au bon endroit, votre salaire est divisé par 2!",

    mission_started_title = "Service Éboueur",
    mission_started_subtitle = "Mission démarrée",
    mission_started_body = "Zone {zoneName} assignée.\nPrenez le camion et dirigez-vous vers les points jaunes pour collecter les déchets.\nVous pouvez arrêter quand vous voulez en revenant avec le camion ici pour avoir ton salaire.",

    no_zone_available = "~r~Aucune zone disponible pour le moment. Revenez plus tard !",

    reward_received = "~g~Vous avez reçu ~b~${amount}",
    all_zones_done_today = "Vous avez déjà fait toutes les zones aujourd\'hui. Revenez demain!"
}

function Lang.t(key, vars)
    local template = Lang[key] or key
    if vars then
        template = string.gsub(template, "{(.-)}", function(k)
            local v = vars[k]
            if v == nil then return "{" .. k .. "}" end
            return tostring(v)
        end)
    end
    return template
end

return Lang


