Citizen.CreateThread(function()
    while not Core do
        Wait(0)
    end

    RegisterCallback('codem-inventory:GetESXCash', function(source, cb)
        local Player = GetPlayer(source)
        if not Player then
            return
        end

        cb(Player.getMoney())
    end)
    RegisterCallback('codem-inventory:GetESXBank', function(source, cb)
        local Player = GetPlayer(source)
        if not Player then
            return
        end
        cb(Player.getAccount("bank").money)
    end)
    RegisterCallback('codem-inventory:GetClosestPlayers', function(source, cb, clientplayers)
        local players = {}
        for k, v in pairs(clientplayers) do
            local player = GetPlayer(tonumber(v))
            if player then
                table.insert(players, {
                    id = tonumber(v),
                    name = GetName(tonumber(v)),
                })
            end
        end
        cb(players)
    end)
    RegisterCallback('codem-inventory:GetPlayerNameandid', function(source, cb)
        local Player = GetPlayer(source)
        if Player then
            local players = {
                id = tonumber(source),
                name = GetName(tonumber(source)),
            }
            cb(players)
        end
    end)
    RegisterCallback('codem-inventory:CheckIsPlayerDead', function(source, cb, id)
        if Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            local Player = Core.Functions.GetPlayer(tonumber(id))
            local isDead = false
            if Player and (Player.PlayerData.metadata["isdead"] or Player.PlayerData.metadata["inlaststand"]) then
                isDead = true
            end
            cb(isDead)
        end
    end)

    RegisterCallback('codem-inventory:GetStashClientKey', function(source, cb)
        local key = ServerPlayerKey[source]
        if key then
            cb(key)
        else
            cb(nil)
        end
    end)
    RegisterCallback('codem-inventory:getUserInventory', function(source, cb)
        local items = LoadInventory(source)
        cb(items)
    end)

    RegisterCallback('codem-inventory:CraftItem', function(source, cb, craftitem)
        local src = source
        local identifier = Identifier[src]
        if not identifier then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
            return
        end

        local playerInventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
        if not playerInventory then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
            debugprint('DİKKAT ENVANTER BULUNAMADI 1791 SATIR')
            return
        end

        local hasAllItems = true
        for _, requiredItem in pairs(craftitem.requiredItems) do
            local found = false
            for _, inventoryItem in pairs(playerInventory) do
                if inventoryItem.name == requiredItem.name and inventoryItem.amount >= requiredItem.amount then
                    found = true
                    break
                end
            end
            if not found then
                hasAllItems = false
                break
            end
        end
        if hasAllItems then
            for _, requiredItem in pairs(craftitem.requiredItems) do
                for _, inventoryItem in pairs(playerInventory) do
                    if inventoryItem.name == requiredItem.name then
                        inventoryItem.amount = tonumber(inventoryItem.amount) - tonumber(requiredItem.amount)
                        if tonumber(inventoryItem.amount) <= 0 then
                            playerInventory[inventoryItem] = nil
                        end
                        TriggerClientEvent('codem-inventory:client:removeitemtoclientInventory', src, inventoryItem.slot,
                            requiredItem.amount)
                        break
                    end
                end
            end
            cb(true)
            SetInventory(src)
        else
            cb(false)
        end
    end)
end)

RegisterServerEvent('codem-inventory:server:FinishCraftItem', function(data)
    local src = source
    if cooldown[tonumber(src)] then
        return
    else
        cooldown[tonumber(src)] = true
        SetTimeout(1000, function()
            cooldown[tonumber(src)] = nil
        end)
    end
    local identifier = Identifier[src]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end

    local playerInventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not playerInventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
        debugprint('DİKKAT ENVANTER BULUNAMADI 1791 SATIR')
        return
    end

    AddItem(src, data.name, data.finishAmount, data.info)
end)




local function decreaseItemDurability(item, elapsedTime, src)
    local decreaseTimes = math.floor(elapsedTime / Config.DurabilityTime)
    if decreaseTimes > 0 then
        item.info.quality = item.info.quality - (item.info.durability or 0) * decreaseTimes
        item.info.lastuse = os.time()
        TriggerClientEvent('codem-inventory:refreshItemsDurability', src, tostring(item.slot), item)
        SetInventory(src)
    end
end

RegisterServerEvent('codem-inventory:checkdurabilityItems', function()
    local src = source
    local identifier = Identifier[src]
    if not identifier or lastCheckTime[src] and os.time() - lastCheckTime[src] < 600 then
        return
    end

    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('DİKKAT ENVANTER BULUNAMADI 507 SATIR')
        return
    end
    for _, item in pairs(playerInventory) do
        if item.info and item.info.decay == 'time' and item.info.quality and item.info.quality > 0 then
            local currentTime = os.time()
            local lastUseTime = item.info.lastuse or currentTime
            local elapsedTime = currentTime - lastUseTime
            decreaseItemDurability(item, elapsedTime, src)
        else
            if item.info and item.info.quality and item.info.quality < 0 then
                item.info.quality = 0
            end
        end
    end

    lastCheckTime[src] = os.time()
end)




RegisterServerEvent('codem-inventory:repairweapon', function(weaponitem)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        return
    end
    if not weaponitem or not weaponitem.slot then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['UNKOWNWEAPONINFO'])
        return
    end
    local item = playerInventory[tostring(weaponitem.slot)]
    if not item then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUND'])
        return
    end
    if item.info and item.info.quality and item.info.quality < 100 then
        if item.info.maxrepair and item.info.repair and item.info.repair >= item.info.maxrepair then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['WEAPON_REPAIR'])
            return
        end
        local repairPrice = Config.WeaponRepairCosts[item.name] or nil
        if not repairPrice then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['WEAPONREPAIRPRICENOTFOUND'])
            return
        end
        local money = GetPlayerMoney(src, 'cash')
        if tonumber(money) < tonumber(repairPrice) then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['ENOUGHMONEY'])
            return
        end
        RemoveMoney(src, 'cash', repairPrice)

        item.info.quality = 100
        item.info.repair = item.info.repair + 1
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['WEAPONREPAIRED'])
        TriggerClientEvent('codem-inventory:refreshItemsDurability', src, tostring(item.slot), item)
        SetInventory(src)
    else
        if item.info.quality and item.info.quality >= 100 then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['DOESNTREPAIRS'])
        else
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['UNKOWNWEAPONINFO'])
        end
    end
end)

RegisterNetEvent('codem-inventory:removeWeaponItem', function(data)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end
    local playerInventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not playerInventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
        debugprint('DİKKAT ENVANTER BULUNAMADI 459 SATIR')
        return
    end
    local itemData = playerInventory[tostring(data.slot)]
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDINGIVENSLOT'])
        return
    end
    RemoveItem(src, itemData.name, itemData.amount, itemData.slot)
end)

RegisterServerEvent('codem-inventory:server:throwweapon', function(data, coords, entity)
    local groundId = GenerateGroundId()
    data.object = entity
    data.slot = "1"
    ServerGround[groundId] = { inventory = { ["1"] = data }, coord = coords, id = groundId }
    TriggerClientEvent('codem-inventory:client:SetGroundTable', -1, groundId, coords,
        ServerGround[groundId].inventory)
end)
