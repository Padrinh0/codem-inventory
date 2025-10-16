PlayerLoaded = false
PlayerPedPreview = nil
CurrentClosestPedVehicle = nil
RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function()
    Wait(1000)
    TriggerServerEvent('codem-inventory:server:loadPlayerInventory')
    PlayerLoaded = true
    SetPlayerJob()
    spawnPed()
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate')
AddEventHandler('QBCore:Client:OnGangUpdate', function(data)
    Wait(1000)
    SetPlayerJob()
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    Wait(1000)
    TriggerServerEvent('codem-inventory:server:loadPlayerInventory')
    PlayerLoaded = true
    SetPlayerJob()
    spawnPed()
end)

CreateThread(function()
    Core, Config.Framework = GetCore()
    Config.OpenTrigger()
    spawnPed()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        Remove2d()
    end
end)
function WaitForModel(model)
    if not IsModelValid(model) then
        return
    end

    if not HasModelLoaded(model) then
        RequestModel(model)
    end

    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if (resourceName == GetCurrentResourceName()) then
        TriggerServerEvent('codem-inventory:server:loadPlayerInventory')
        SetPlayerJob()
        ClearPedInPauseMenu()
        SetFrontendActive(false)
        local ped = PlayerPedId()
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        RemoveAllPedWeapons(ped, true)
        currentWeapon = nil
        PlayerLoaded = true
    end
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(data)
    Wait(1000)
    SetPlayerJob()
end)
RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    Wait(1000)
    SetPlayerJob()
end)

function WaitPlayer()
    if Config.Framework == "esx" or Config.Framework == 'oldesx' then
        while Core == nil do
            Wait(0)
        end
        while Core.GetPlayerData() == nil do
            Wait(0)
        end
        while Core.GetPlayerData().job == nil do
            Wait(0)
        end
    else
        while Core == nil do
            Wait(0)
        end
        while Core.Functions.GetPlayerData() == nil do
            Wait(0)
        end
        while Core.Functions.GetPlayerData().metadata == nil do
            Wait(0)
        end
    end
end

function SetPlayerJob()
    while Core == nil do
        Wait(0)
    end
    Wait(500)
    while not nuiLoaded and not PlayerLoaded do
        Wait(50)
    end
    WaitPlayer()

    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        local PlayerData = Core.GetPlayerData()
        if next(PlayerData) == nil then

        else
            jobData.name = PlayerData.job.name
            jobData.grade = PlayerData.job.grade
            jobData.joblabel = PlayerData.job.label
            jobData.gradename = PlayerData.job.grade_label
            PlayerLoaded = true
        end
    else
        local PlayerData = Core.Functions.GetPlayerData()
        if next(PlayerData) == nil then

        else
            jobData.name = PlayerData["job"].name
            jobData.grade = PlayerData["job"].grade.level
            jobData.joblabel = PlayerData["job"].label
            jobData.gradename = PlayerData["job"].grade.name
            PlayerLoaded = true
        end
    end
end

function DrawText3Ds(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local isPedScreenActive = false
function CreatePedScreen()
    if isPedScreenActive then
        return
    end
    isPedScreenActive = true
    if PlayerPedPreview then
        DeleteEntity(PlayerPedPreview)
        PlayerPedPreview = nil
    end

    Wait(150)
    CreateThread(function()
        vehicle, distance = GetClosestVehicle()
        if vehicle ~= nil and distance <= 4.0 then
            SetEntityAsMissionEntity(vehicle, true, true)
            CurrentClosestPedVehicle = vehicle
        end

        SetFrontendActive(true)
        local menuType =
        `FE_MENU_VERSION_EMPTY_NO_BACKGROUND` --full list: https://docs.fivem.net/natives/?_0xEF01D36B9C9D0C7B
        ActivateFrontendMenu(menuType, true, -1)
        ReplaceHudColourWithRgba(117, 0, 0, 0, 0)
        Citizen.Wait(100)
        SetMouseCursorVisibleInMenus(false)
        if PlayerPedPreview == nil then
            local ped = PlayerPedId()
            local coords = GetEntityCoords()
            PlayerPedPreview = ClonePed(ped, false, false, true)
            FreezeEntityPosition(PlayerPedPreview, true)
            SetEntityCoords(PlayerPedPreview, coords.x, coords.y, coords.z - 10.0)
            SetPauseMenuPedSleepState(true)
            FinalizeHeadBlend(PlayerPedPreview)
            FreezeEntityPosition(PlayerPedPreview, true)
            SetEntityVisible(PlayerPedPreview, false, 0)
            NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)

            GivePedToPauseMenu(PlayerPedPreview, 2)
            SetPauseMenuPedLighting(true)
        end
        Citizen.CreateThread(function()
            SetMouseCursorVisibleInMenus(false)
        end)
        isPedScreenActive = false
    end)
end

function Remove2d()
    DeleteEntity(PlayerPedPreview)
    SetFrontendActive(false)
    ReplaceHudColourWithRgba(117, 45, 44, 44, 200)
    PlayerPedPreview = nil
end

function RefreshPedScreen()
    if DoesEntityExist(PlayerPedPreview) then
        Remove2d()
        Wait(500)
        if OpenInventory then
            CreatePedScreen()
        end
    else
        DeleteEntity(PlayerPedPreview)
        SetFrontendActive(false)
        ReplaceHudColourWithRgba(117, 45, 44, 44, 200)
        PlayerPedPreview = nil
    end
end

RegisterNetEvent('RefreshPedScreen', function()
    RefreshPedScreen()
end)

GetClosestVehicle = function()
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    coords = GetEntityCoords(ped)
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

function IsBackEngine(vehModel)
    return Config.BackEngineVehicles[vehModel]
end

GetTrunkOrGlovebox = function(class, invtype)
    if not Config.TrunkAndGloveboxWeight[invtype][class] then class = 9 end
    return Config.TrunkAndGloveboxWeight[invtype][class].maxweight, Config.TrunkAndGloveboxWeight[invtype][class].slots
end

function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

GetClosestPlayers = function()
    local players = {}
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    for _, player in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(player)
        if target ~= ped then
            local targetCoords = GetEntityCoords(target)
            local distance = #(pedCoords - targetCoords)
            if distance < 3.5 then
                table.insert(players, GetPlayerServerId(player))
            end
        end
    end
    return players
end

GetClosestPlayer = function()
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)

    for index, value in ipairs(players) do
        local target = GetPlayerPed(value)
        if (target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords['x'], targetCoords['y'], targetCoords['z'],
                plyCoords['x'], plyCoords['y'], plyCoords['z'], true)
            if (closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

function Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish,
                     onCancel)
    if GetResourceState('progressbar') ~= 'started' then
        error(
            'progressbar needs to be started in order for QBCore.Functions.Progressbar to work')
    end
    exports['progressbar']:Progress({
        name = name:lower(),
        duration = duration,
        label = label,
        useWhileDead = useWhileDead,
        canCancel = canCancel,
        controlDisables = disableControls,
        animation = animation,
        prop = prop,
        propTwo = propTwo,
    }, function(cancelled)
        if not cancelled then
            if onFinish then
                onFinish()
            end
        else
            if onCancel then
                onCancel()
            end
        end
    end)
end

CreateThread(function()
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        while true do
            Wait(0)
            BlockWeaponWheelThisFrame()
        end
    end
end)
