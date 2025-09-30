RegisterNetEvent('garbage_job:giveReward')
AddEventHandler('garbage_job:giveReward', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.addMoney(amount)
        TriggerClientEvent('esx:showNotification', source, Lang.t('reward_received', { amount = amount }))
    end
end)

function GetAvailableZones(identifier)
    local result = exports.oxmysql:executeSync('SELECT zone, last_done FROM garbage_zones WHERE identifier = ? AND last_done > DATE_SUB(NOW(), INTERVAL 24 HOUR)', {
        identifier
    })
    
    local completedZones = {}
    for _, data in ipairs(result) do
        completedZones[data.zone] = true
    end
    
    local availableZones = {}
    for i = 1, #Config.TrashZones do
        if not completedZones[i] then
            table.insert(availableZones, i)
        end
    end
    
    return availableZones
end

RegisterNetEvent('garbage_job:getAvailableZone')
AddEventHandler('garbage_job:getAvailableZone', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    
    local availableZones = GetAvailableZones(identifier)
    
    if #availableZones > 0 then
        local randomIndex = math.random(#availableZones)
        local selectedZoneIndex = availableZones[randomIndex]
        TriggerClientEvent('garbage_job:setZone', source, selectedZoneIndex)
    else
        TriggerClientEvent('esx:showNotification', source, Lang.t('all_zones_done_today'))
    end
end)

RegisterNetEvent('garbage_job:completeZone')
AddEventHandler('garbage_job:completeZone', function(zoneIndex)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.identifier
    
    exports.oxmysql:execute('INSERT INTO garbage_zones (identifier, zone, last_done) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE last_done = NOW()',
    {
        identifier,
        zoneIndex
    })
end) 