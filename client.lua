local isOnDuty = false
local trashTruck = nil
local collectedBins = 0
local currentZone = nil
local collectedBinsTable = {}
local selectedZone = nil
local carryingTrash = false
local trashProp = nil

CreateThread(function()
    local model = GetHashKey(Config.JobLocation.ped.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local ped = CreatePed(4, model, Config.JobLocation.ped.coords, Config.JobLocation.ped.heading, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - Config.JobLocation.ped.coords)
            
            if dist < 3.0 then
                sleep = 0
                local text = isOnDuty and Lang.t('ui_stop_service') or Lang.t('ui_start_service')
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(text)
                EndTextCommandDisplayHelp(0, false, true, -1)
                
                if IsControlJustPressed(0, 38) then -- E
                    ToggleDuty()
                end
            end
            
            Wait(sleep)
        end
    end)
end)

function ToggleDuty()
    if not isOnDuty then
        TriggerServerEvent('garbage_job:getAvailableZone')
    else
        TriggerServerEvent('garbage_job:completeZone', selectedZone.index)
        CalculateAndGiveReward()
        CleanupJob()
        ESX.ShowNotification(Lang.t('service_finished'))
    end
end

function SpawnTruckAndStartJob()
    local spawnCoords = Config.JobLocation.vehicleSpawn.coords
    local radius = 3.0

    if IsAnyVehicleNearPoint(spawnCoords.x, spawnCoords.y, spawnCoords.z, radius) then
        ESX.ShowNotification(Lang.t('spawn_blocked'))
        return false
    end
    
    local model = GetHashKey(Config.JobLocation.vehicleModel or 'trash')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    trashTruck = CreateVehicle(model, spawnCoords, Config.JobLocation.vehicleSpawn.heading, true, false)
    SetVehicleNumberPlateText(trashTruck, "TRASH"..math.random(100, 999))
    
    StartCollectingJob()
    return true
end

function StartCollectingJob()
    CreateThread(function()
        for _, binCoords in pairs(selectedZone.trashBins) do
            local blip = AddBlipForCoord(binCoords)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 5) -- Jaune
            SetBlipScale(blip, 0.4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Lang.t('blip_trash'))
            EndTextCommandSetBlipName(blip)
            table.insert(collectedBinsTable, {coords = binCoords, blip = blip, collected = false})
        end
    end)
    CreateThread(function()
        while isOnDuty do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for _, binData in pairs(collectedBinsTable) do
                if not binData.collected then
                    local dist = #(playerCoords - binData.coords)
                    
                    if dist < 20.0 then
                        sleep = 0
                        DrawMarker(1, binData.coords.x, binData.coords.y, binData.coords.z - 1.0, 
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                            1.0, 1.0, 1.0, 255, 255, 0, 100, 
                            false, false, 2, false, nil, nil, false)
                        
                        if dist < 2.0 then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName(Lang.t('help_pick_trash'))
                            EndTextCommandDisplayHelp(0, false, true, -1)
                            
                            if IsControlJustPressed(0, 38) then
                                CollectTrash(binData)
                            end
                        end
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

function CollectTrash(binData)
    if not isOnDuty or carryingTrash then return end
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
    Wait(3000)
    ClearPedTasks(PlayerPedId())
    local model = GetHashKey("prop_cs_street_binbag_01")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    local dict = "missfbi4prepp1"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(1)
    end
    TaskPlayAnim(PlayerPedId(), dict, "_idle_garbage_man", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    trashProp = CreateObject(model, 0, 0, 0, true, true, true)
    AttachEntityToEntity(trashProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    carryingTrash = true
    binData.collected = true
    RemoveBlip(binData.blip)
    ESX.ShowNotification(Lang.t('carry_to_truck'))
    CreateThread(function()
        while carryingTrash do
            local sleep = 100
            local playerCoords = GetEntityCoords(PlayerPedId())
            local truckCoords = GetEntityCoords(trashTruck)
            local truckOffset = GetOffsetFromEntityInWorldCoords(trashTruck, 0.0, -6.0, 0.0)
            local distToTruck = #(playerCoords - truckOffset)
            
            if distToTruck < 5.0 then
                sleep = 0
                DrawMarker(1, truckOffset.x, truckOffset.y, truckOffset.z - 1.0, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    1.0, 1.0, 1.0, 255, 255, 0, 100, 
                    false, false, 2, false, nil, nil, false)
                
                if distToTruck < 2.0 then
                    ESX.ShowHelpNotification(Lang.t('help_throw_bag'))
                    if IsControlJustPressed(0, 38) then
                        ThrowTrashBag()
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

function ThrowTrashBag()
    if not carryingTrash then return end
    local dict = "anim@heists@narcotics@trash"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(1)
    end
    
    TaskPlayAnim(PlayerPedId(), dict, "throw_b", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(800)
    DeleteEntity(trashProp)
    trashProp = nil
    carryingTrash = false
    collectedBins = collectedBins + 1
    ESX.ShowNotification(Lang.t('bag_thrown', { count = collectedBins }))
    ClearPedTasks(PlayerPedId())
    ClearPedSecondaryTask(PlayerPedId())
    SetPedCanPlayAmbientAnims(PlayerPedId(), true)
end

function CalculateAndGiveReward()
    local baseReward = collectedBins * Config.Rewards.perBin
    local bonusReward = math.floor(collectedBins / Config.Rewards.bonusThreshold) * Config.Rewards.bonusAmount
    local totalReward = baseReward + bonusReward
    local truckReturned = false
    if DoesEntityExist(trashTruck) then
        local truckCoords = GetEntityCoords(trashTruck)
        local spawnCoords = Config.JobLocation.vehicleSpawn.coords
        local distance = #(truckCoords - spawnCoords)
        
        if distance <= 10.0 then
            truckReturned = true
        end
    end
    
    if not truckReturned then
        totalReward = totalReward / 2
        ESX.ShowNotification(Lang.t('truck_not_returned_half_pay'))
    end
    
    TriggerServerEvent('garbage_job:giveReward', totalReward)
end

function CleanupJob()
    isOnDuty = false
    if DoesEntityExist(trashTruck) then
        DeleteVehicle(trashTruck)
    end
    if DoesEntityExist(trashProp) then
        DeleteEntity(trashProp)
    end
    carryingTrash = false
    for _, binData in pairs(collectedBinsTable) do
        if binData.blip then
            RemoveBlip(binData.blip)
        end
    end
    collectedBinsTable = {}
    collectedBins = 0
    selectedZone = nil
end

RegisterNetEvent('garbage_job:setZone')
AddEventHandler('garbage_job:setZone', function(zoneIndex)
    if zoneIndex then
        if SpawnTruckAndStartJob() then
            isOnDuty = true
            selectedZone = Config.TrashZones[zoneIndex]
            selectedZone.index = zoneIndex
            ESX.ShowAdvancedNotification(Lang.t('mission_started_title'), Lang.t('mission_started_subtitle'), Lang.t('mission_started_body', { zoneName = selectedZone.name }), "CHAR_ARTHUR", 1)
        end
    else
        ESX.ShowNotification(Lang.t('no_zone_available'))
    end
end)