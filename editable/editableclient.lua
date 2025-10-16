jobData = {
    name = nil,
    grade = nil,
    playername = nil,
    playerid = nil,
    gradename = nil,
    joblabel = nil,
    gang = nil
}
clonedPed = nil
local isHotbar = false


Citizen.CreateThread(function()
    while not nuiLoaded and Core == nil do
        Citizen.Wait(0)
    end
    RegisterKeyMapping('inventory', 'Inventory', 'keyboard', Config.KeyBinds.Inventory)

    RegisterCommand('inventory', function()
        TriggerEvent('codem-inventory:openInventory')
    end)
    RegisterCommand('hotbar', function()
        isHotbar = not isHotbar
        if not IsPauseMenuActive() then
            ToggleHotbar(isHotbar)
        end
    end)

    RegisterKeyMapping('hotbar', 'hotbar', 'keyboard', Config.KeyBinds.HotBar)

    for i = 1, 6 do
        RegisterKeyMapping("useslot" .. i, 'Use Slot #' .. i, 'keyboard', i)
        RegisterCommand("useslot" .. i, function()
            UseSlot(i)
        end)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if clonedPed then
        DeleteEntity(clonedPed)
        clonedPed = nil
    end
    ClientInventory = {}
    TriggerServerEvent('codem-inventory:server:onplayerunload')
end)



RegisterNUICallback('UseItem', function(data, cb)
    if not CanAccesInventory(true) then
        return
    end
    if data then
        local slot = tostring(data.slot)
        if ClientInventory[slot] then
            TriggerServerEvent('codem-inventory:server:UseItem', slot, ClientInventory[slot].name)
        end
    end

    cb('ok')
end)


function UseSlot(slotnumber)
    if not CanAccesInventory() then
        return
    end
    slotnumber = tostring(slotnumber)
    if ClientInventory[slotnumber] then
        TriggerServerEvent('codem-inventory:server:UseItem', slotnumber, ClientInventory[slotnumber].name)
    end
end

RegisterCommand(Config.Commands['openinv'], function()
    TriggerEvent('codem-inventory:openInventory')
end)

RegisterCommand(Config.Commands['closeinv'], function()
    TriggerEvent('codem-inventory:client:closeInventory')
end)

RegisterCommand(Config.Commands['hotbar'], function()
    isHotbar = not isHotbar
    if not IsPauseMenuActive() then
        ToggleHotbar(isHotbar)
    end
end)


local gloveboxveh = nil
RegisterNetEvent('codem-inventory:openInventory', function()
    if not nuiLoaded and Core == nil then
        return
    end
    if not CanAccesInventory() then
        return
    end
    if jobData.name == nil or jobData.playerid == nil then
        local namedata = TriggerCallback('codem-inventory:GetPlayerNameandid')
        if namedata then
            jobData.playername = namedata.name or 'UNKOWN'
            jobData.playerid = namedata.id or 'UNKOWN'
        end
    end
    OpenInventory = true
    if Config.AnimPlayer['openinventory'] then
        openAnim()
    end
    ToggleHotbar(false)
    NuiMessage('LOAD_INVENTORY', ClientInventory)
    NuiMessage('PLAYERNAME_ID', jobData)
    SetNuiFocus(true, true)
    CheckVehicleInventory()
    if currentDrop then
        NuiMessage('UPDATE_GROUND', ClientGround[currentDrop])
    end
    if not PedScreen then
        Remove2d()
    else
        CreatePedScreen()
    end
    if Config.DurabilitySystem then
        TriggerServerEvent('codem-inventory:checkdurabilityItems')
    end
    if Config.ItemClothingSystem then
        TriggerEvent('codem-inventory:loadClothingInventory')
    end
end)

function CheckVehicleInventory()
    local vehicle, distance = GetClosestVehicle()
    local ped = PlayerPedId()
    local inveh = IsPedInAnyVehicle(ped, false)
    if (inveh) then
        local plate = GetVehicleNumberPlateText(GetVehiclePedIsIn(ped, false))
        gloveboxveh = GetVehiclePedIsIn(ped)
        InGlovebox = plate
    else
        InGlovebox = nil
    end
    if vehicle ~= 0 and vehicle ~= nil then
        local pos = GetEntityCoords(ped)
        local dimensionMin, dimensionMax = GetModelDimensions(GetEntityModel(vehicle))
        local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (dimensionMin.y), 0.0)
        if (IsBackEngine(GetEntityModel(vehicle))) then
            trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (dimensionMax.y), 0.0)
        end
        if #(pos - trunkpos) < 1.5 and not IsPedInAnyVehicle(ped) then
            if GetVehicleDoorLockStatus(vehicle) < 2 then
                InTrunk = GetVehicleNumberPlateText(vehicle)
                curvehicle = vehicle
            end
        else
            curvehicle = nil
            currentVehiclePlate = nil
            InTrunk = nil
        end
    else
        curvehicle = nil
        currentVehiclePlate = nil
        InTrunk = nil
    end
    if InGlovebox then
        local vehicleclass       = GetVehicleClass(gloveboxveh)
        local maxweight, slot    = GetTrunkOrGlovebox(vehicleclass, 'glovebox')
        InGlovebox               = string.lower(string.gsub(InGlovebox, "%s+", ""))
        local vehicleDisplayName = GetDisplayNameFromVehicleModel(GetEntityModel(gloveboxveh))
        local stringlowerModel   = string.lower(vehicleDisplayName)
        if stringlowerModel and Config.AddonVehicleTrunkOrGlovebox[stringlowerModel] then
            maxweight = Config.AddonVehicleTrunkOrGlovebox[stringlowerModel]['glovebox'].maxweight
            slot = Config.AddonVehicleTrunkOrGlovebox[stringlowerModel]['glovebox'].slots
        end
        if VehicleGlovebox[InGlovebox] then
            VehicleGlovebox[InGlovebox].slot = slot
            VehicleGlovebox[InGlovebox].maxweight = maxweight
            VehicleGlovebox[InGlovebox].plate = InGlovebox
            TriggerEvent('codem-inventory:client:openVehicleGlovebox', VehicleGlovebox[InGlovebox])
        else
            TriggerServerEvent('codem-inventory:server:openVehicleGlovebox', InGlovebox, maxweight, slot, givecount)
        end
    end
    if curvehicle then
        local vehicleclass = GetVehicleClass(curvehicle)
        local vehicleDisplayName = GetDisplayNameFromVehicleModel(GetEntityModel(curvehicle))
        local doorstatus = GetVehicleDoorLockStatus(curvehicle)
        if doorstatus == 2 then
            TriggerEvent('codem-inventory:client:notification', Locales[Config.Language].notification['TRUNKLOCKED'])
            return
        end
        local stringlowerModel = string.lower(vehicleDisplayName)
        local maxweight, slot = GetTrunkOrGlovebox(vehicleclass, 'trunk')
        if stringlowerModel and Config.AddonVehicleTrunkOrGlovebox[stringlowerModel] then
            maxweight = Config.AddonVehicleTrunkOrGlovebox[stringlowerModel]['trunk'].maxweight
            slot = Config.AddonVehicleTrunkOrGlovebox[stringlowerModel]['trunk'].slots
        end
        currentVehiclePlate = GetVehicleNumberPlateText(curvehicle)
        currentVehiclePlate = string.lower(string.gsub(currentVehiclePlate, "%s+", ""))

        if VehicleInventory[currentVehiclePlate] then
            VehicleInventory[currentVehiclePlate].slot = slot
            VehicleInventory[currentVehiclePlate].maxweight = maxweight
            VehicleInventory[currentVehiclePlate].plate = currentVehiclePlate
            TriggerEvent('codem-inventory:client:openVehicleTrunk', VehicleInventory[currentVehiclePlate])
        else
            TriggerServerEvent('codem-inventory:server:openVehicleTrunk', GetVehicleNumberPlateText(curvehicle),
                maxweight,
                slot, givecount)
        end
        openTrunkVehicle = true
        OpenTrunk()
    end
end

CanAccesInventory = function(useitem)
    if not AccessInv then
        return false
    end
    if not useitem then
        useitem = false
    end
    if throwingWeapon then
        return false
    end
    if robstatus then
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['ROBBINGACTION'])
        return false
    end

    while Core == nil do
        Wait(0)
    end
    --if exports['progressbar']:isDoingSomething() then
       -- TriggerEvent('codem-inventory:client:notification',
         --   Locales[Config.Language].notification['SOMETHINGDOTHIS'])
       -- return false
   -- end
    if not useitem and OpenInventory then
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['SOMETHINGDOTHIS'])
        return false
    end
    if Config.Framework == "qb" or Config.Framework == "old-qb" then
        local PlayerData = Core.Functions.GetPlayerData()
        if PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"] or PlayerData.metadata["ishandcuffed"] then
            TriggerEvent('codem-inventory:client:notification',
                Locales[Config.Language].notification['DOTHISACTION'])
            return false
        end
    end
    return true
end

--[[Citizen.CreateThread(function()
    while true do
        Wait(500)
        if exports['progressbar']:isDoingSomething() then
            TriggerEvent('codem-inventory:client:closeInventory')
        end
        if lastHealth ~= nil and lastHealth <= 0 then
            TriggerEvent('codem-inventory:client:closeInventory')
        end
    end
end) ]]




Citizen.CreateThread(function()
    for k, v in pairs(Config.Shops) do
        if v.Blip and v.Blip.enable then
            Blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(Blip, v.Blip.id)
            SetBlipColour(Blip, v.Blip.color)
            SetBlipScale(Blip, v.Blip.scale)
            SetBlipAsShortRange(Blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.label)
            EndTextCommandSetBlipName(Blip)
        end
    end
end)

function OpenInventoryStash(k, v)
    if v.job ~= 'all' then
        local found = false
        if not v.gang then
            for job, grade in pairs(v.job) do
                if job == jobData.name then
                    if grade[jobData.grade] then
                        found = true
                        break
                    end
                end
            end
        end
        if not found then
            local gangData = Core.Functions.GetPlayerData().gang

            if v.gang and gangData then
                for kk, vv in pairs(v.gang) do
                    if kk == gangData.name then
                        if gangData and gangData.grade and vv[gangData.grade.level] then
                            found = true
                            break
                        end
                    end
                end
            end
        end
        if not found then
            TriggerEvent('codem-inventory:client:notification',
                Locales[Config.Language].notification['NOTALLOWEDSTASH'])
            return
        end
    end
    TriggerServerEvent('codem-inventory:server:openstash', k, v.slot, v.maxweight, v.label, givecount)
end

-- RegisterNetEvent('codem-inventory:client:openstash', function(stashid, slot, maxweight, label)
--     TriggerServerEvent('codem-inventory:server:openstash', stashid, slot, maxweight, label)
-- end)

function OpenInventoryShop(k, v)
    if v.job ~= 'all' then
        local found = false
        for job, grade in pairs(v.job) do
            if job == jobData.name then
                if grade[jobData.grade] then
                    found = true
                    break
                end
            end
        end
        if not found then
            TriggerEvent('codem-inventory:client:notification',
                Locales[Config.Language].notification['NOTALLOWEDSHOP'])
            return
        end
    end

    TriggerEvent('codem-inventory:openInventory')

    for k, v in pairs(v.items) do
        v.label = Config.Itemlist[v.name].label
        v.image = Config.Itemlist[v.name].image
        v.amount = 1
        v.weight = Config.Itemlist[v.name].weight
    end

    NuiMessage('OPEN_SHOP', { shopname = k, shoplabel = v.label, inventory = v.items })
end

RegisterNetEvent('codem-inventory:openstashoxtarget', function(k, v)
    OpenInventoryStash(k.eventData.stashName, k.eventData.stashData)
end)

RegisterNetEvent('codem-inventory:openshopoxtarget', function(k, v)
    OpenInventoryShop(k.eventData.stashName, k.eventData.stashData)
end)
RegisterNetEvent('codem-inventory:openrepairoxtarget', function()
    RepairWeapon()
end)

RegisterNetEvent('codem-inventory:openshop', function(shopname)
    if Config.Shops[shopname] then
        OpenInventoryShop(shopname, Config.Shops[shopname])
    else
        print('not found shop')
    end
end)

--[[
        items = {
            ["1"] = { name = "weapon_pistol", price = 10, },
            ["2"] = { name = "weapon_flashlight", price = 10, },
            ["3"] = { name = "handcuffs", price = 10,},
        }
    ]]
RegisterNetEvent('codem-inventory:OpenPlayerShop', function(items)
    TriggerEvent('codem-inventory:openInventory')
    local structuredItems = {}
    if items[1] then
        for index, item in ipairs(items) do
            local itemDetails = {
                label = Config.Itemlist[item.name].label,
                image = Config.Itemlist[item.name].image,
                weight = Config.Itemlist[item.name].weight,
                amount = 1,
                price = item.price,
                name = item.name
            }
            structuredItems[tostring(index)] = itemDetails
        end
    else
        for key, item in pairs(items) do
            local itemDetails = {
                label = Config.Itemlist[item.name].label,
                image = Config.Itemlist[item.name].image,
                weight = Config.Itemlist[item.name].weight,
                amount = 1,
                price = item.price,
                name = item.name
            }
            structuredItems[key] = itemDetails
        end
    end
    NuiMessage('OPEN_SHOP', { shopname = 'market', shoplabel = 'MARKET', inventory = structuredItems })
end)

-- RegisterCommand('openshop', function()
--     local items = {
--         { name = "weapon_pistol",     price = 10, },
--         { name = "weapon_flashlight", price = 10, },
--         { name = "handcuffs",         price = 10, },
--     }
--     TriggerEvent('codem-inventory:OpenPlayerShop', items)
-- end)


Citizen.CreateThread(function()
    Config.OpenTrigger = function()
        if Config.InteractionHandler == "qb-target" then
            for k, v in pairs(Config.Shops) do
                exports['qb-target']:AddBoxZone('codem_inventory_shops_' .. k, v.coords, 3, 3, {
                    name = 'codem_inventory_shops_' .. k,
                    heading = v.heading,
                    debugPoly = false,
                    minZ = v.coords.z - 3,
                    maxZ = v.coords.z + 2
                }, {
                    options = {
                        {
                            label = v.label,
                            icon = 'fa-solid fa-water',
                            action = function()
                                OpenInventoryShop(k, v)
                            end
                        }
                    },
                    distance = 2.0
                })
            end
            for k, v in pairs(Config.Stashs) do
                exports['qb-target']:AddBoxZone('codem_inventory_stash_' .. k, v.coords, 3, 3, {
                    name = 'codem_inventory_stash_' .. k,
                    heading = v.heading,
                    debugPoly = false,
                    minZ = v.coords.z - 3,
                    maxZ = v.coords.z + 2
                }, {
                    options = {
                        {
                            label = v.label,
                            icon = 'fa-solid fa-water',
                            action = function()
                                OpenInventoryStash(k, v)
                            end
                        }
                    },
                    distance = 2.0
                })
            end

            for k, v in pairs(Config.RepairWeapon) do
                exports['qb-target']:AddBoxZone('codem_inventory_repair_' .. k, v.coords, 3, 3, {
                    name = 'codem_inventory_repair_' .. k,
                    heading = v.heading,
                    debugPoly = false,
                    minZ = v.coords.z - 3,
                    maxZ = v.coords.z + 2
                }, {
                    options = {
                        {
                            label = 'Repair Weapon',
                            icon = 'fa-solid fa-water',
                            action = function()
                                RepairWeapon()
                            end
                        }
                    },
                    distance = 2.0
                })
            end
        elseif Config.InteractionHandler == "ox-target" then
            for k, v in pairs(Config.Shops) do
                exports.ox_target:addBoxZone({
                    name = 'codem_inventory_shops_' .. k,
                    coords = v.coords,
                    size = vec3(3.6, 3.6, 3.6),
                    drawSprite = false,
                    options = {
                        {
                            name = 'codem_inventory_stash_' .. k,
                            event = "codem-inventory:openshopoxtarget",
                            eventData = { stashName = k, stashData = v },
                            icon = 'fas fa-gears',
                            label = "Open Market",
                        }
                    }
                })
            end

            for k, v in pairs(Config.Stashs) do
                exports.ox_target:addBoxZone({
                    name = 'codem_inventory_stash_' .. k,
                    coords = v.coords,
                    size = vec3(3.6, 3.6, 3.6),
                    drawSprite = false,
                    options = {
                        {
                            name = 'codem_inventory_stash_' .. k,
                            event = "codem-inventory:openstashoxtarget",
                            eventData = { stashName = k, stashData = v },
                            icon = 'fas fa-gears',
                            label = "Open Sash",
                        }
                    }
                })
            end


            for k, v in pairs(Config.RepairWeapon) do
                exports.ox_target:addBoxZone({
                    name = 'codem_inventory_repair_' .. k,
                    coords = v.coords,
                    size = vec3(3.6, 3.6, 3.6),
                    drawSprite = false,
                    options = {
                        {
                            name = 'codem_inventory_repair',
                            event = "codem-inventory:openrepairoxtarget",
                            icon = 'fas fa-gears',
                            label = "Repair",
                        }
                    }
                })
            end
        elseif Config.InteractionHandler == "drawtext" then
            Citizen.CreateThread(function()
                while true do
                    local wait = 500
                    if jobData.name then
                        local ped = PlayerPedId()
                        local pedcoord = GetEntityCoords(ped)

                        -- shops
                        for k, v in pairs(Config.Shops) do
                            local diff = #(pedcoord - v.coords)
                            if diff <= 3.0 then
                                wait = 0
                                DrawText3Ds(v.coords.x, v.coords.y, v.coords.z, 'E - ' .. v.label)
                                if diff <= 1.5 then
                                    if IsControlJustReleased(1, 38) then
                                        OpenInventoryShop(k, v)
                                    end
                                end
                            end
                        end
                        -- stash
                        for k, v in pairs(Config.Stashs) do
                            local diff = #(pedcoord - v.coords)
                            if diff <= 3.0 then
                                wait = 0
                                DrawText3Ds(v.coords.x, v.coords.y, v.coords.z, 'E - ' .. v.label)
                                if diff <= 1.5 then
                                    if IsControlJustReleased(1, 38) then
                                        OpenInventoryStash(k, v)
                                    end
                                end
                            end
                        end
                        -- repair
                        for k, v in pairs(Config.RepairWeapon) do
                            local diff = #(pedcoord - v.coords)
                            if diff <= 3.0 then
                                wait = 0
                                DrawText3Ds(v.coords.x, v.coords.y, v.coords.z,
                                    'E')
                                if diff <= 1.5 then
                                    if IsControlJustReleased(1, 38) then
                                        RepairWeapon()
                                    end
                                end
                            end
                        end
                    end
                    Citizen.Wait(wait)
                end
            end)
        end
    end
end)


RegisterCommand(Config.Commands['robplayer'], function()
    RobPlayer()
end)
RegisterCommand(Config.Commands['deathrob'], function()
    DeathRobPlayer()
end)


RegisterNetEvent('codem-inventory:client:robplayer', function()
    RobPlayer()
end)
RegisterNetEvent('codem-inventory:client:deathrob', function()
    DeathRobPlayer()
end)

function RobPlayer()
    local closestPlayer, closestDistance = GetClosestPlayer()
    local ped = PlayerPedId()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        local targetplayerped = GetPlayerPed(closestPlayer)
        if IsPedArmed(ped, 4) or jobData and jobData.name == 'police' then
            if IsEntityPlayingAnim(targetplayerped, "missminuteman_1ig_2", "handsup_base", 3) or IsEntityPlayingAnim(targetplayerped, "mp_arresting", "idle", 3) or IsPedDeadOrDying(targetplayerped) then
                TriggerServerEvent('codem-inventory:server:robplayer', GetPlayerServerId(closestPlayer))
            else
                TriggerEvent('codem-inventory:client:notification',
                    Locales[Config.Language].notification['CANNOTROB'])
            end
        else
            TriggerEvent('codem-inventory:client:notification',
                Locales[Config.Language].notification['YOUNEEDTOWEAPON'])
        end
    else
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['NOTFOUNDTOROB'])
    end
end

function DeathRobPlayer()
    local closestPlayer, closestDistance = GetClosestPlayer()
    local ped = PlayerPedId()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        local targetplayerped = GetPlayerPed(closestPlayer)
        if IsPedArmed(ped, 4) or jobData and jobData.name == 'police' then
            if (Config.Framework == "qb" or Config.Framework == "oldqb") then
                local retval = TriggerCallback('codem-inventory:CheckIsPlayerDead', GetPlayerServerId(closestPlayer))
                if retval then
                    TriggerServerEvent('codem-inventory:server:robplayer', GetPlayerServerId(closestPlayer))
                else
                    TriggerEvent('codem-inventory:client:notification',
                        Locales[Config.Language].notification['NOTDEADROB'])
                end
            else
                if (IsPedDeadOrDying(targetplayerped) or IsEntityDead(targetplayerped)) then
                    TriggerServerEvent('codem-inventory:server:robplayer', GetPlayerServerId(closestPlayer))
                else
                    TriggerEvent('codem-inventory:client:notification',
                        Locales[Config.Language].notification['NOTDEADROB'])
                end
            end
        else
            TriggerEvent('codem-inventory:client:notification',
                Locales[Config.Language].notification['YOUNEEDTOWEAPON'])
        end
    else
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['NOTFOUNDTOROB'])
    end
end

RegisterNetEvent('codem-inventory:client:robstatus', function(val)
    if val then
        TriggerEvent('codem-inventory:client:closeInventory')
    end
    robstatus = val
end)

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        SetWeaponsNoAutoswap(true)
        SetPedConfigFlag(ped, 48, false)
    end
end)





RegisterNetEvent('codem-inventory:client:closeInventory', function()
    if CurrentClosestPedVehicle then
        SetEntityAsMissionEntity(CurrentClosestPedVehicle, false, false)
        CurrentClosestPedVehicle = nil
    end
    SetNuiFocus(false, false)
    OpenInventory = false
    NuiMessage('CLOSE_INVENTORY')
    --if PedScreen then
    Remove2d()
    -- end

    if openTrunkVehicle then
        CloseTrunk()
        openTrunkVehicle = false
    end
end)

RegisterNUICallback('CloseInventory', function(data)
    if CurrentClosestPedVehicle then
        SetEntityAsMissionEntity(CurrentClosestPedVehicle, false, false)
        CurrentClosestPedVehicle = nil
    end
    SetNuiFocus(false, false)
    OpenInventory = false
    NuiMessage('CLOSE_RIGHTINVENTORY')
    Remove2d()
    if openTrunkVehicle then
        CloseTrunk()
        openTrunkVehicle = false
    end
end)
RegisterCommand('clearped', function()
    DeleteEntity(clonedPed)
    clonedPed = nil
    ClearPedInPauseMenu()
    SetFrontendActive(false)
end)

local function DrawGroundMarker(coord)
    DrawMarker(Config.DropMarker.type, coord.x, coord.y, coord.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.3, 0.3, 0.15, Config.DropMarker.r, Config.DropMarker.g, Config.DropMarker.b, 155, false,
        false, false, 1, false, false, false)
end
Citizen.CreateThread(function()
    if not Config.RealisticObjectDrop then
        while true do
            local wait = 1000
            local ped = PlayerPedId()
            local pedcoords = GetEntityCoords(ped)
            local closestDrop, closestDistance = nil, math.huge
            for k, v in pairs(ClientGround) do
                if v.coord then
                    local distbetween = #(pedcoords - v.coord)
                    if distbetween <= 2.5 then
                        if currentDrop ~= v.id then
                            currentDrop = v.id
                            if OpenInventory then
                                NuiMessage('UPDATE_GROUND', ClientGround[currentDrop])
                            end
                            if not v.object then
                                local model = GetHashKey('bkr_prop_duffel_bag_01a')
                                RequestModel(model)
                                while not HasModelLoaded(model) do
                                    Wait(10)
                                end
                                local entity = CreateObject(model, v.coord.x, v.coord.y, v.coord.z - 0.95, false, true,
                                    true)
                                SetModelAsNoLongerNeeded(model)
                                PlaceObjectOnGroundProperly(entity)
                                FreezeEntityPosition(entity, true)
                                ClientGround[k].object = entity
                            end
                        end
                    elseif v.object and distbetween > 2.5 then
                        DeleteEntityInventory(v.object)
                        ClientGround[k].object = nil
                    end
                    if distbetween < closestDistance then
                        closestDrop, closestDistance = v, distbetween
                    end
                end
            end
            if not closestDrop or closestDistance >= 2.5 then
                currentDrop = nil
            end
            Citizen.Wait(wait)
        end
    end
end)
Citizen.CreateThread(function()
    if Config.RealisticObjectDrop then
        while true do
            local wait = 500
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local closestDrop, closestDistance = nil, math.huge

            for k, groundData in pairs(ClientGround) do
                if groundData.coord then
                    local distBetween = #(pedCoords - groundData.coord)
                    if distBetween <= 2.5 and currentDrop ~= groundData.id then
                        currentDrop = groundData.id
                        if OpenInventory then
                            NuiMessage('UPDATE_GROUND', ClientGround[currentDrop])
                        end
                    end

                    if distBetween <= 50.5 then
                        for itemIndex, itemData in pairs(groundData.inventory) do
                            if not itemData.object then
                                local model = GetHashKey(Config.ObjectItems[itemData.name] or Config.DeafultProp)
                                RequestModel(model)
                                local endTime = GetGameTimer() + 40
                                while not HasModelLoaded(model) do
                                    Wait(0)
                                    if GetGameTimer() > endTime then
                                        model = GetHashKey(Config.DeafultProp)
                                        RequestModel(model)
                                        while not HasModelLoaded(model) do
                                            Wait(0)
                                            if GetGameTimer() > endTime + 40 then
                                                break
                                            end
                                        end
                                        break
                                    end
                                end
                                itemData.duiLoaded = false
                                itemData.duiObj = nil
                                itemData.sfHandle = nil
                                itemData.txdHasBeenSet = false
                                local randomX = math.random(-50, 50) / 100.0
                                local randomY = math.random(-50, 50) / 100.0

                                local entity = CreateObject(model, groundData.coord.x + randomX,
                                    groundData.coord.y + randomY, groundData.coord.z - 0.95, false, true, true)
                                SetModelAsNoLongerNeeded(model)
                                PlaceObjectOnGroundProperly(entity)
                                FreezeEntityPosition(entity, true)
                                groundData.inventory[itemIndex].object = entity
                                SendNUIMessage({
                                    action = "SHOW_DUI",
                                    data = groundData.inventory
                                })
                            end
                        end
                    end

                    if distBetween > 50.5 then
                        for itemIndex, itemData in pairs(groundData.inventory) do
                            if itemData.object then
                                DeleteEntity(itemData.object)
                                itemData.object = nil
                            end
                        end
                    end

                    if distBetween < closestDistance then
                        closestDrop, closestDistance = groundData, distBetween
                    end
                end
            end

            if closestDistance > 2.5 then
                currentDrop = nil
            end

            Citizen.Wait(wait)
        end
    end
end)

function DeleteEntityInventory(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

RegisterNetEvent('codem-inventory:client:SetGroundTable', function(groundid, coord, inventory)
    if Config.RealisticObjectDrop then
        if ClientGround[groundid] then
            for itemIndex, itemData in pairs(ClientGround[groundid].inventory) do
                if itemData.object then
                    DeleteEntityInventory(itemData.object)
                end
            end
            ClientGround[groundid].inventory = inventory
            for itemIndex, itemData in pairs(ClientGround[groundid].inventory) do
                if itemData.object == nil then
                    local model = GetHashKey(Config.ObjectItems[itemData.name] or Config.DeafultProp)
                    RequestModel(model)
                    local endTime = GetGameTimer() + 20
                    while not HasModelLoaded(model) do
                        Wait(0)
                        if GetGameTimer() > endTime then
                            model = GetHashKey(Config.DeafultProp)
                            RequestModel(model)
                            while not HasModelLoaded(model) do
                                Wait(0)
                                if GetGameTimer() > endTime + 20 then
                                    break
                                end
                            end
                            break
                        end
                    end
                    local randomX = math.random(-50, 50) /
                        100.0
                    local randomY = math.random(-50, 50) /
                        100.0
                    local entity = CreateObject(model, ClientGround[groundid].coord.x + randomX,
                        ClientGround[groundid].coord.y + randomY,
                        ClientGround[groundid].coord.z - 0.95, false, true, true)
                    SetModelAsNoLongerNeeded(model)
                    PlaceObjectOnGroundProperly(entity)
                    FreezeEntityPosition(entity, true)
                    ClientGround[groundid].inventory[itemIndex].object = entity
                end
            end
        else
            ClientGround[groundid] = {
                id = groundid,
                coord = coord,
                inventory = inventory,
            }
        end
        if OpenInventory and currentDrop == groundid then
            NuiMessage('UPDATE_GROUND', ClientGround[groundid])
        end
    else
        if ClientGround[groundid] then
            ClientGround[groundid].inventory = inventory
        else
            ClientGround[groundid] = {
                id = groundid,
                coord = coord,
                inventory = inventory,
                object = nil
            }
        end
        if OpenInventory and currentDrop == groundid then
            NuiMessage('UPDATE_GROUND', ClientGround[groundid])
        end
    end
end)

RegisterNetEvent('codem-inventory:client:removeGroundTable', function(groundid)
    if OpenInventory then
        if ClientGround[groundid] then
            NuiMessage('CLOSE_GROUND')
        end
    end
    if ClientGround[groundid] then
        if Config.RealisticObjectDrop then
            for itemIndex, itemData in pairs(ClientGround[groundid].inventory) do
                if itemData.object then
                    DeleteEntityInventory(itemData.object)
                end
            end
        else
            if ClientGround[groundid].object then
                DeleteEntityInventory(ClientGround[groundid].object)
                if ClientGround[groundid].inventory then
                    for itemIndex, itemData in pairs(ClientGround[groundid].inventory) do
                        if itemData.object then
                            DeleteEntityInventory(itemData.object)
                        end
                    end
                end
            end
        end
        ClientGround[groundid] = nil
    end
end)


function DeleteEntityInventory(entity)
    if DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, false, true)
        DeleteEntity(entity)
    end
end

local spawnedPeds = {}

function spawnPed()
    for _, ped in pairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    spawnedPeds = {}

    for k, v in pairs(Config.RepairWeapon) do
        if v and v.ped then
            WaitForModel(v.pedHash)
            local createNpc = CreatePed(4, v.pedHash, v.coords.x, v.coords.y, v.coords.z - 0.98, v.heading, false, true)
            FreezeEntityPosition(createNpc, true)
            SetEntityInvincible(createNpc, true)
            SetBlockingOfNonTemporaryEvents(createNpc, true)
            spawnedPeds[k] = createNpc
        end
    end
end

function RepairWeapon()
    local weapon = ClientWeaponData
    if next(weapon) == nil then
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['NOTHAVEAWEAPONREPAIR'])
        return
    end
    TriggerServerEvent('codem-inventory:repairweapon', ClientWeaponData)
end

---------------------------------------------


function playPickupOrDropAnimation()
    local playerPed = PlayerPedId()
    if not IsEntityPlayingAnim(playerPed, 'random@domestic', 'pickup_low', 3) then
        LoadAnimDict('random@domestic')
        TaskPlayAnim(playerPed, 'random@domestic', 'pickup_low', 8.0, -8, -1, 48, 0, 0, 0, 0)
    end
end

function openAnim()
    local ped = PlayerPedId()
    if not IsEntityPlayingAnim(ped, 'pickup_object', 'putdown_low', 3) then
        LoadAnimDict('pickup_object')
        TaskPlayAnim(ped, 'pickup_object', 'putdown_low', 5.0, 1.5, 1.0, 48, 0.0, 0, 0, 0)
    end
end

function giveitemAnim()
    local ped = PlayerPedId()
    if not IsEntityPlayingAnim(ped, 'mp_common', 'givetake1_b', 3) then
        LoadAnimDict('mp_common')
        TaskPlayAnim(ped, 'mp_common', 'givetake1_b', 5.0, 1.5, 1.0, 48, 0.0, 0, 0, 0)
    end
end

function OpenTrunk()
    local vehicle = GetClosestVehicle()
    if Config.AnimPlayer['opentrunk'] then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed, true)
        PlayAnimAdvanced(0, 'anim@heists@fleeca_bank@scope_out@return_case', 'trevor_action', coords.x, coords.y,
            coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 1000, 49, 0.25)
    end
    if IsBackEngine(GetEntityModel(vehicle)) then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
    end
end

function CloseTrunk()
    local vehicle = GetClosestVehicle()
    if Config.AnimPlayer['closetrunk'] then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed, true)
        PlayAnimAdvanced(0, 'missminuteman_2ig_1', 'trunk_josef', coords.x, coords.y,
            coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 500, 49, 0.25)
    end
    if IsBackEngine(GetEntityModel(vehicle)) then
        SetVehicleDoorShut(vehicle, 4, false)
    else
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

RegisterNetEvent('codem-inventory:dropanim', function()
    if Config.AnimPlayer['drop'] then
        playPickupOrDropAnimation()
    end
end)

RegisterNetEvent('codem-inventory:giveanim', function()
    if Config.AnimPlayer['giveitemplayer'] then
        giveitemAnim()
    end
end)

CreateThread(function()
    SetWeaponsNoAutoswap(true)
end)


function TriggerCallback(name, data)
    local incomingData = false
    local status = 'UNKOWN'
    local counter = 0
    while Core == nil and not nuiLoaded do
        Wait(0)
    end


    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        Core.TriggerServerCallback(name, function(payload)
            status = 'SUCCESS'
            incomingData = payload
        end, data)
    else
        Core.Functions.TriggerCallback(name, function(payload)
            status = 'SUCCESS'
            incomingData = payload
        end, data)
    end
    CreateThread(function()
        while incomingData == 'UNKOWN' do
            Wait(1000)
            if counter == 4 then
                status = 'FAILED'
                incomingData = false
                break
            end
            counter = counter + 1
        end
    end)

    while status == 'UNKOWN' do
        Wait(0)
    end
    return incomingData
end
