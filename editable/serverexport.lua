SharedWeapons = {}
Citizen.CreateThread(function()
    while Core == nil do
        Wait(0)
    end
end)

Citizen.CreateThread(function()
    for k, v in pairs(Config.Itemlist) do
        if v.type == "weapon" then
            SharedWeapons[GetHashKey(v.name)] = {
                name = v.name,
                ammotype = v.ammotype or nil
            }
        end
    end
end)


function GetItemList()
    return Config.Itemlist
end

function LoadInventory(source, identifier)
    if not identifier then
        identifier = GetIdentifier(tonumber(source))
    end
    local src = tonumber(source)
    local result = ExecuteSql('SELECT inventory FROM codem_new_inventory WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    if #result == 0 then
        return {}
    end

    local playerInventoryRaw = result[1].inventory
    local playerInventory = json.decode(playerInventoryRaw)
    if not playerInventory then
        debugprint("Failed to decode inventory for identifier: " .. identifier)
        return
    end

    for itemIndex, itemData in pairs(playerInventory) do
        local itemname = tostring(itemData.name)
        local configItem = Config.Itemlist[itemname]
        if configItem then
            itemIndex = tostring(itemIndex)
            playerInventory[itemIndex] = {
                name = itemData.name,
                label = configItem.label or itemData.name,
                weight = configItem.weight or 0,
                type = configItem.type or 'item',
                amount = itemData.amount,
                count = itemData.amount,
                usable = configItem.usable or false,
                shouldClose = configItem.shouldClose or false,
                description = configItem.description or '',
                slot = tonumber(itemIndex),
                image = configItem.image or (itemData.name .. ".png"),
                unique = configItem.unique or false,
                info = itemData.info or nil,
                ammotype = configItem.ammotype or nil
            }
        else
            debugprint('^4 ITEM NOT FOUND in Config.Itemlist: ' ..
                itemData.name .. ' for identifier: ' .. identifier .. ' Name: ' .. GetName(src))
            playerInventory[itemIndex] = nil
        end
    end
    return playerInventory
end

function SaveInventory(source, offline)
    if Config.Framework == 'qb' or Config.Framework == 'oldqb' then
        local PlayerData

        -- if not offline then
        --     local Player = GetPlayer(source)
        --     if not Player then
        --         return
        --     end
        --     PlayerData = Player.PlayerData
        -- else
        --     PlayerData = source
        -- end
        local Player = GetPlayer(source)
        if not Player then
            debugprint('PLAYER NIL')
            return
        end
        local identifier = GetIdentifier(tonumber(source))
        if not identifier then
            debugprint('SAVEINVENTORY : Identifier not found')
            return
        end
        PlayerData = Player.PlayerData
        local items = PlayerData.items
        local itemList = {}
        if items and table.type(items) ~= 'empty' then
            for k, v in pairs(items) do
                itemList[k] = {
                    name = v.name,
                    amount = v.amount,
                    info = v.info
                }
            end
            ExecuteSql(
                "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE identifier = @identifier, inventory = @inventory",
                { identifier = identifier, inventory = json.encode(itemList) })
        else
            ExecuteSql(
                "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE identifier = @identifier, inventory = @inventory",
                { identifier = identifier, inventory = json.encode({}) })
        end
    end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        local identifier = GetIdentifier(tonumber(source))
        local items = PlayerServerInventory[identifier].inventory
        local itemList = {}
        if items and table.type(items) ~= 'empty' then
            for k, v in pairs(items) do
                itemList[k] = {
                    name = v.name,
                    amount = v.amount,
                    info = v.info
                }
            end
            ExecuteSql(
                "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE identifier = @identifier, inventory = @inventory",
                { identifier = identifier, inventory = json.encode(itemList) })
        else
            ExecuteSql(
                "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE identifier = @identifier, inventory = @inventory",
                { identifier = identifier, inventory = json.encode({}) })
        end
    end
end

function GetItemBySlot(source, slot)
    local src = tonumber(source)
    local identifier = Identifier[tonumber(src)]
    if not identifier then
        debugprint('GETITEMBYSLOT : Identifier not found')
        return
    end
    slot = tostring(slot)
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('GETITEMBYSLOT : Inventory not found')
        return
    end
    return playerInventory[slot]
end

function SetItemBySlot(source, slot, itemData)
    local src = tonumber(source)
    local identifier = Identifier[tonumber(src)]
    if not identifier then
        debugprint('SETITEMBYSLOT : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('SETITEMBYSLOT : Inventory not found')
        return
    end
    slot = tostring(slot)
    if playerInventory[slot] then
        playerInventory[slot] = itemData
        playerInventory[slot].slot = tonumber(slot)
        TriggerClientEvent('codem-inventory:client:setitembyslot', src, slot, itemData)
    end
    SetInventory(src)
end

function GetItemByName(source, name, slot)
    local src = source
    local identifier = Identifier[tonumber(src)]
    if not identifier then
        debugprint('GETITEMBYNAME : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not slot then
        if not playerInventory then
            debugprint('GETITEMBYNAME : Inventory not found')
            return
        end
        for k, v in pairs(playerInventory) do
            if v.name == name then
                return v
            end
        end
    else
        slot = tostring(slot)
        if not playerInventory[slot] then
            debugprint('GETITEMBYNAME : Slot not found')
            return
        else
            if playerInventory[slot].name == name then
                return playerInventory[slot]
            end
        end
    end
end

function SetInventoryItems(source, item, amount)
    if item == 'money' then
        item = 'cash'
        local money = GetPlayerMoney(source, 'cash')
        amount = tonumber(amount) - money
    end
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        debugprint('SETINVENTORYITEMS : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('SETINVENTORYITEMS : Inventory not found')
        return
    end

    local totalCurrentAmount = 0
    amount = tonumber(amount)
    local itemSlots = {}
    for k, v in pairs(playerInventory) do
        if v.name == item then
            totalCurrentAmount = totalCurrentAmount + v.amount
            itemSlots[#itemSlots + 1] = { slot = k, amount = v.amount }
        end
    end

    if totalCurrentAmount == amount then
        if item == 'cash' then
            SetInventory(src)
        end
        return
    elseif totalCurrentAmount > amount then
        local amountToRemove = totalCurrentAmount - amount
        for _, itemSlot in ipairs(itemSlots) do
            if amountToRemove > 0 then
                itemSlot.amount = tonumber(itemSlot.amount)
                amountToRemove = tonumber(amountToRemove)
                if itemSlot.amount <= amountToRemove then
                    itemSlot.slot = tostring(itemSlot.slot)
                    amountToRemove = amountToRemove - itemSlot.amount
                    playerInventory[itemSlot.slot] = nil
                    TriggerClientEvent('codem-inventory:client:removeitemtoclientInventory', src, itemSlot.slot,
                        itemSlot.amount)
                else
                    itemSlot.slot = tostring(itemSlot.slot)
                    itemSlot.amount = itemSlot.amount - amountToRemove
                    playerInventory[itemSlot.slot].amount = itemSlot.amount
                    TriggerClientEvent('codem-inventory:client:setitemamount', src, itemSlot.slot, itemSlot.amount)
                    amountToRemove = 0
                end
            else
                break
            end
        end
    else
        amount = tonumber(amount)
        totalCurrentAmount = tonumber(totalCurrentAmount)
        local amountToAdd = amount - totalCurrentAmount
        AddItem(src, item, amountToAdd)
    end

    SetInventory(src)
end

function GetItemsTotalAmount(source, itemname)
    local src = tonumber(source)
    local identifier = GetIdentifier(src)
    if not identifier then
        debugprint('GETITEMTOTALAMOUNT : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('GETITEMTOTALAMOUNT : Inventory not found')
        return
    end
    local amount = 0
    for k, v in pairs(playerInventory) do
        if v.name == itemname then
            amount = amount + v.amount
        end
    end
    return amount
end

function GetItemsWeight(items)
    local weight = 0
    if not items then return 0 end
    for _, item in pairs(items) do
        weight += item.weight * item.amount
    end
    return tonumber(weight)
end

function GetSlotsByItem(items, itemName)
    local slotsFound = {}
    if not items then return slotsFound end
    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            slotsFound[#slotsFound + 1] = slot
        end
    end
    return slotsFound
end

function GetFirstSlotByItem(items, itemName)
    if not items then return nil end
    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            return tonumber(slot)
        end
    end
    return nil
end

function CheckBagItem(source)
    local src = tonumber(source)
    local identifier = Identifier[src]
    local items = PlayerServerInventory[identifier].inventory or {}
    local totalCount = 0
    for k, v in pairs(items) do
        if v.type == 'bag' then
            totalCount = totalCount + 1
        end
    end
    return totalCount
end

function HasItem(source, items, amount)
    local Player = GetPlayer(source)
    if not Player then return false end
    local isTable = type(items) == 'table'
    local isArray = isTable and table.type(items) == 'array' or false
    local totalItems = #items
    local count = 0
    local kvIndex = 2
    if isTable and not isArray then
        totalItems = 0
        for _ in pairs(items) do totalItems += 1 end
        kvIndex = 1
    end
    if isTable then
        for k, v in pairs(items) do
            local itemKV = { k, v }
            local item = GetItemByName(source, itemKV[kvIndex])
            if item and ((amount and item.amount >= amount) or (not isArray and item.amount >= v) or (not amount and isArray)) then
                count += 1
            end
        end
        if count == totalItems then
            return true
        end
    else -- Single item as string
        local item = GetItemByName(source, items)
        if item and (not amount or (item and amount and item.amount >= amount)) then
            return true
        end
    end
    return false
end

function RemoveItem(src, itemname, amount, slot)
    if itemname == 'money' then
        itemname = 'cash'
    end
    itemname = tostring(itemname)
    local identifier = GetIdentifier(tonumber(src))
    if not identifier then
        debugprint('REMOVEITEM : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('REMOVEITEM : Inventory not found')
        return
    end
    if not amount then
        amount = 1
    end
    amount = tonumber(amount)
    if slot then
        slot = tostring(slot)
        if playerInventory[slot] and playerInventory[slot].name == itemname then
            local slotAmount = tonumber(playerInventory[slot].amount)
            if slotAmount >= amount then
                playerInventory[slot].amount = slotAmount - amount
                if playerInventory[slot].amount <= 0 then
                    playerInventory[slot] = nil
                end
                TriggerClientEvent('codem-inventory:client:removeitemtoclientInventory', tonumber(src), slot, amount)
                SetInventory(tonumber(src))
                return true
            else
                TriggerClientEvent('codem-inventory:client:notification', src, ' Not enough item in the specified slot')
                return false
            end
        end
    else
        local totalRemoved = 0
        for k, v in pairs(playerInventory) do
            if v.name == itemname then
                local canRemove = math.min(amount - totalRemoved, tonumber(v.amount))
                v.amount = v.amount - canRemove
                totalRemoved = totalRemoved + canRemove
                if v.amount <= 0 then
                    playerInventory[k] = nil
                end
                TriggerClientEvent('codem-inventory:client:removeitemtoclientInventory', tonumber(src), k, canRemove)
                SetInventory(tonumber(src))
                if totalRemoved >= amount then
                    break
                end
            end
        end
        if totalRemoved < amount then
            TriggerClientEvent('codem-inventory:client:notification', src, ' Not enough items across slots')
            return false
        else
            SetInventory(tonumber(src))
            return true
        end
    end
end

function GetItemLabel(item)
    local itemData = Config.Itemlist[item]
    if itemData then
        return itemData.label or 'UNKOWN ITEM'
    end
    return nil
end

function GetStashItems(stashid)
    if not stashid then
        return
    end
    if ServerStash[stashid] then
        return ServerStash[stashid].inventory
    else
        return {}
    end
end

function UpdateStash(stashid, items)
    if not stashid then
        return
    end
    if ServerStash[stashid] then
        ServerStash[stashid].inventory = items
        UpdateStashDatabase(stashid, items)
    else
        ServerStash[stashid] = { inventory = items, stashname = stashid }
        UpdateStashDatabase(stashid, items)
    end
end

function CheckItemValid(src, name, count)
    if (src and name and count) then
        local identifier = GetIdentifier(tonumber(src))
        if not identifier then
            debugprint('CHECKITEMVALID : Identifier not found')
            return
        end
        local playerInventory = PlayerServerInventory[identifier].inventory
        if not playerInventory then
            debugprint('CHECKITEMVALID : Inventory not found')
            return
        end
        for k, v in pairs(playerInventory) do
            if v.name == name then
                if v.amount >= count then
                    return true
                else
                    return false
                end
            end
        end
    end
end

-- RegisterCommand('randomitem', function(source)
--     local src = source
--     local itemList = {}
--     for key, value in pairs(Config.Itemlist) do
--         table.insert(itemList, value)
--     end
--     local randomItem = itemList[math.random(1, #itemList)]
--     AddItem(src, randomItem.name, math.random(1, 10))
-- end)

function AddItem(src, item, amount, slot, inforequest)
    if item == 'money' then
        item = 'cash'
    end
    item = tostring(item)
    local identifier = GetIdentifier(tonumber(src))
    if not identifier then
        return
    end

    if not PlayerServerInventory[identifier] then
        PlayerServerInventory[identifier] = { identifier = identifier, inventory = {} }
    end

    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        playerInventory = {}
        PlayerServerInventory[identifier].inventory = playerInventory
    end

    local itemData = Config.Itemlist[item]
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDITEMLIST'])
        return false
    end
    if itemData and itemData.type == 'bag' then
        local bagCount = CheckBagItem(src)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['MAXBAGPACKITEM'])
            return
        end
    end

    if not slot then
        slot = FindFirstEmptySlot(playerInventory, Config.MaxSlots)
        if not slot then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['NOEMPTYSLOTAVILABLEYOUR'])
            return false
        end
    end

    if itemData.unique then
        amount = 1
    end
    if tonumber(amount) < 0 then
        amount = 1
    end
    local CheckInvetoryWeight = CheckInventoryWeight(playerInventory, itemData.weight * amount, Config.MaxWeight)
    if not CheckInvetoryWeight then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['NOEMPTYSLOTAVILABLEYOUR'])
        return false
    end

    local info = {}
    slot = tostring(slot)
    local found = false

    for k, v in pairs(playerInventory) do
        k = tostring(k)
        if not v.unique or not itemData.unique then
            if v.name == itemData.name and k ~= slot then
                v.amount = v.amount + amount
                if slot ~= k then
                    TriggerClientEvent('codem-inventory:updateitemamount', src, k, v.amount, amount)
                end
                found = true
                break
            end
        end
    end

    if not found then
        playerInventory[slot] = {
            name = itemData.name,
            label = itemData.label or itemData.name,
            weight = itemData.weight or 0,
            type = itemData.type or 'item',
            amount = amount,
            usable = itemData.usable or false,
            shouldClose = itemData.shouldClose or false,
            description = itemData.description or '',
            image = itemData.image or '',
            unique = itemData.unique or false,
            slot = slot,
            ammotype = itemData.ammotype or nil,
            info = info
        }
    end

    if found and next(info) ~= nil then
        playerInventory[slot].info = info
    end

    if itemData.name == 'id_card' then
        if Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            local Player = Core.Functions.GetPlayer(src)
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        end
    end
    if itemData.type == 'weapon' then
        info.ammo = 0
        info.series = GetRandomString()
        info.attachments = {}
        info.tint = 0
        info.maxrepair = 1
        info.repair = 0
    end
    if itemData.type == 'bag' then
        info.series = GetRandomString()
        info.slot = itemData.slot
        info.weight = itemData.backpackweight or 0
    end

    if Config.DurabilitySystem then
        if Config.DurabilityItems[itemData.name] then
            if Config.DurabilityItems[itemData.name].decay == 'use' then
                info.quality = 100
                info.maxrepair = Config.DurabilityItems[itemData.name].maxrepair
                info.decay = Config.DurabilityItems[itemData.name].decay
                info.durability = Config.DurabilityItems[itemData.name].durability
                info.repair = 0
            end
            if Config.DurabilityItems[itemData.name].decay == 'time' then
                info.quality = 100
                info.maxrepair = Config.DurabilityItems[itemData.name].maxrepair
                info.decay = Config.DurabilityItems[itemData.name].decay
                info.durability = Config.DurabilityItems[itemData.name].durability
                info.lastuse = os.time()
                info.repair = 0
            end
        end
    end

    if next(info) ~= nil then
        playerInventory[slot].info = info
    end

    if inforequest and next(inforequest) ~= nil then
        playerInventory[slot].info = playerInventory[slot].info or {}

        for key, value in pairs(inforequest) do
            playerInventory[slot].info[key] = value
        end
    end

    if not found then
        TriggerClientEvent('codem-inventory:client:additem', tonumber(src), slot, playerInventory[slot])
    end

    SetInventory(tonumber(src))

    return true
end

function GetInventory(identifier, source)
    if not identifier then
        identifier = GetIdentifier(tonumber(source))
    end
    if not identifier then
        return
    end
    if PlayerServerInventory and PlayerServerInventory[identifier] then
        local inventory = PlayerServerInventory[identifier].inventory
        for k, v in pairs(inventory) do
            if not v.count then
                v.count = v.amount
            end
            v.count = v.amount
        end
        return inventory
    end
    return {}
end

function ClearInventory(source)
    local id = tonumber(source)
    local identifier = Identifier[id]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', source, 'identifier not found.')
        return
    end

    if not PlayerServerInventory[identifier] then
        TriggerClientEvent('codem-inventory:client:notification', source, 'Inventory not found.')
        return
    end

    local inventory = PlayerServerInventory[identifier].inventory
    local newInventory = {}
    if Config.CashItem then
        for slot, item in pairs(inventory) do
            if item.name == 'cash' and not Config.NotDeleteItemWhenPlayerDie[item.name] then
                RemoveMoney(id, 'cash', item.amount)
            end
        end
    end
    for slot, item in pairs(inventory) do
        if Config.NotDeleteItemWhenPlayerDie[item.name] then
            newInventory[slot] = item
        end
    end
    PlayerServerInventory[identifier].inventory = newInventory
    SetInventory(id)
    TriggerClientEvent('codem-inventory:client:notification', source, 'Inventory cleared.')
    TriggerClientEvent('codem-inventory:client:clearinventory', id)
end

function GetItemsByName(source, item)
    item = tostring(item):lower()
    local identifier = Identifier[tonumber(source)]
    if not identifier then
        debugprint('GETITEMSBYNAME : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    local items = {}
    local slots = GetSlotsByItem(playerInventory, item)
    for _, slot in pairs(slots) do
        if slot then
            items[#items + 1] = playerInventory[slot]
        end
    end
    return items
end

function UseItem(itemname, ...)
    local itemData = Core.Functions.CanUseItem(itemname)
    local callback = type(itemData) == 'table' and
        (rawget(itemData, '__cfx_functionReference') and itemData or itemData.cb or itemData.callback) or
        type(itemData) == 'function' and itemData
    if not callback then return end
    TriggerEvent('codem-inventory:usedItem', itemname, ...)
    callback(...)
end

function GetTrunkInventory(plate)
    if not plate then
        return
    end
    local newplate = customToLower(plate)
    if VehicleInventory[newplate] then
        return VehicleInventory[newplate].trunk
    else
        print('PLATE NOT FOUND')
    end
end

function GetGloveboxInventory(plate)
    if not plate then
        return
    end
    local newplate = customToLower(plate)
    if GloveBoxInventory[newplate] then
        return GloveBoxInventory[newplate].glovebox
    else
        print('PLATE NOT FOUND')
    end
end

function UpdateVehicleInventoryTrunkOrGlovebox(inventorytype, plate, items)
    if not plate then
        return
    end
    local newplate = customToLower(plate)
    if inventorytype == 'trunk' then
        if VehicleInventory[newplate] then
            VehicleInventory[newplate].trunk = items
            UpdateVehicleInventory(newplate, items)
        else
            VehicleInventory[newplate] = {
                plate = newplate,
                trunk = items,
            }
            UpdateVehicleInventory(newplate, items)
        end
    end
    if inventorytype == 'glovebox' then
        if GloveBoxInventory[newplate] then
            GloveBoxInventory[newplate].glovebox = items
            UpdateVehicleGlovebox(newplate, items)
        else
            GloveBoxInventory[newplate] = {
                plate = newplate,
                glovebox = items,
            }
            UpdateVehicleGlovebox(newplate, items)
        end
    end
end

AddEventHandler('codem-inventory:usedItem', function(itemname, ...)
    if itemname == 'radio' then
        local src = ...
        local item = GetItemByName(tonumber(src), itemname)
        if item then
            -- print('item slot', item.slot)
        else
            --  print('item not found')
        end
    end
end)


AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "AddItem", function(item, amount, slot, info)
        return AddItem(Player.PlayerData.source, item, amount, slot, info)
    end)

    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "RemoveItem", function(item, amount, slot)
        return RemoveItem(Player.PlayerData.source, item, amount, slot)
    end)

    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "GetItemBySlot", function(slot)
        return GetItemBySlot(Player.PlayerData.source, slot)
    end)

    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "GetItemByName", function(item)
        return GetItemByName(Player.PlayerData.source, item)
    end)

    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "GetItemsByName", function(item)
        return GetItemsByName(Player.PlayerData.source, item)
    end)

    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "ClearInventory", function()
        ClearInventory(Player.PlayerData.source)
    end)
    Core.Functions.AddPlayerMethod(Player.PlayerData.source, "SetInventory", function(items)
        local identifier = GetIdentifier(tonumber(Player.PlayerData.source))
        if PlayerServerInventory[identifier] then
            PlayerServerInventory[identifier].inventory = {}
        end

        PlayerServerInventory[identifier].inventory = items
        SetInventory(tonumber(Player.PlayerData.source))
    end)
end)


SetMethods = function(source)
    while Core == nil do
        Wait(0)
    end
    source = tonumber(source)
    if Config.Framework == "qb" or Config.Framework == "oldqb" then
        Core.Functions.AddPlayerMethod(source, "AddItem", function(item, amount, slot, info)
            return AddItem(source, item, amount, slot, info)
        end)

        Core.Functions.AddPlayerMethod(source, "RemoveItem", function(item, amount, slot)
            return RemoveItem(source, item, amount, slot)
        end)

        Core.Functions.AddPlayerMethod(source, "GetItemBySlot", function(slot)
            return GetItemBySlot(source, slot)
        end)

        Core.Functions.AddPlayerMethod(source, "GetItemByName", function(item)
            return GetItemByName(source, item)
        end)

        Core.Functions.AddPlayerMethod(source, "GetItemsByName", function(item)
            return GetItemsByName(source, item)
        end)

        Core.Functions.AddPlayerMethod(source, "ClearInventory", function()
            ClearInventory(source)
        end)
        Core.Functions.AddPlayerMethod(source, "SetInventory", function(items)
            local identifier = GetIdentifier(tonumber(source))
            if PlayerServerInventory[identifier] then
                PlayerServerInventory[identifier].inventory = {}
            end

            PlayerServerInventory[identifier].inventory = items
            SetInventory(tonumber(source))
        end)
    end
end



function SharedWeaponsfunc(name)
    if SharedWeapons[name] then
        return SharedWeapons[name]
    end
    return false
end

function CheckCashItems()
    return Config.CashItem
end

function debugprint(val)
    if Config.DebugPrint then
        print(val)
    end
end

function SetItemMetadata(source, slot, metadata)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        debugprint('SETITEMMETADATA : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('SETITEMMETADATA : Inventory not found')
        return
    end
    slot = tostring(slot)
    if playerInventory[slot] then
        playerInventory[slot].info = metadata
        TriggerClientEvent('codem-inventory:refreshiteminfo', source, slot, metadata)
        if playerInventory[slot].type == 'weapon' then
            TriggerClientEvent('codem-inventory:refreshWeaponAttachment', source, slot, metadata)
        end
        SetInventory(src)
    end
end

function GetTotalWeight(item)
    local weight = 0
    for k, v in pairs(item) do
        weight = weight + (v.weight * v.amount)
    end
    return weight
end

function CanCarryItem(source, item, count)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        debugprint('CANCARRYITEM : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('CANCARRYITEM : Inventory not found')
        return
    end
    local itemData = Config.Itemlist[item]
    if not itemData then
        debugprint('CANCARRYITEM : Item not found')
        return
    end
    local weight = GetTotalWeight(playerInventory)
    local newWeight = weight + (itemData.weight * count)
    if newWeight > Config.MaxWeight then
        return false
    end
    return true
end

function ChangeItemInfoValue(source, slot, key, value)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        debugprint('CHANGEITEMINFOVALUE : Identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        debugprint('CHANGEITEMINFOVALUE : Inventory not found')
        return
    end
    slot = tostring(slot)
    if playerInventory[slot] then
        if playerInventory[slot].info then
            if playerInventory[slot].info[key] then
                playerInventory[slot].info[key] = value
                TriggerClientEvent('codem-inventory:refreshiteminfo', source, slot, playerInventory[slot].info)
                SetInventory(src)
            end
            print('key not found')
        end
    end
end

exports('GetTrunkInventory', GetTrunkInventory)
exports('GetGloveboxInventory', GetGloveboxInventory)
exports('UpdateVehicleInventoryTrunkOrGlovebox', UpdateVehicleInventoryTrunkOrGlovebox)
exports('ChangeItemInfoValue', ChangeItemInfoValue)
exports('HasItem', HasItem)
exports('AddItem', AddItem)
exports('UseItem', UseItem)
exports('RemoveItem', RemoveItem)
exports('GetFirstSlotByItem', GetFirstSlotByItem)
exports('GetSlotsByItem', GetSlotsByItem)
exports('GetItemsWeight', GetItemsWeight)
exports('GetItemByName', GetItemByName)
exports('SetItemBySlot', SetItemBySlot)
exports('GetItemBySlot', GetItemBySlot)
exports('SaveInventory', SaveInventory)
exports('GetItemsByName', GetItemsByName)
exports('LoadInventory', LoadInventory)
exports('ClearInventory', ClearInventory)
exports('GetItemList', GetItemList)
-- exports('SetInventory', SetInventory)
exports('GetInventory', GetInventory)
exports('CheckItemValid', CheckItemValid)
exports('SharedWeapons', SharedWeaponsfunc)
exports('GetItemLabel', GetItemLabel)
exports('GetStashItems', GetStashItems)
exports('UpdateStash', UpdateStash)
exports('CheckCashItems', CheckCashItems)
exports('GetItemsTotalAmount', GetItemsTotalAmount)
exports('SetInventoryItems', SetInventoryItems)
exports('SetItemMetadata', SetItemMetadata)
exports('GetTotalWeight', GetTotalWeight)
exports('CanCarryItem', CanCarryItem)


RegisterServerEvent('codem-inventory:CheckPlayerMoney', function(item)
    local src = source
    if Config.CashItem then
        SetInventoryItems(src, 'cash', tonumber(item))
    end
end)

AddEventHandler('QBCore:Server:OnMoneyChange', function(src, account, amount, changeType)
    local src = tonumber(src)
    if account ~= "cash" then return end
    if Config.CashItem then
        if changeType == 'set' then
            CashAmount = amount
            SetInventoryItems(src, 'cash', CashAmount)
        elseif changeType == 'add' then
            local CashAmount = GetPlayerMoney(src, 'cash')
            SetInventoryItems(src, 'cash', CashAmount)
        elseif changeType == 'remove' then
            local CashAmount = GetItemsTotalAmount(src, 'cash')
            CashAmount = CashAmount - amount
            SetInventoryItems(src, 'cash', CashAmount)
        end
    end
end)
