-- ============================================
-- CODEM INVENTORY SYSTEM - FULL CLEANED VERSION
-- ============================================

-- Global Variables
Core = nil
PlayerServerInventory = {}
ServerGround = {}
ServerStash = {}
VehicleInventory = {}
GloveBoxInventory = {}
Identifier = {}
ServerPlayerKey = {}
cooldown = {}
ClothingInventory = {}
local duplicateCheckCooldown = {}

-- ============================================
-- CORE INITIALIZATION
-- ============================================

Citizen.CreateThread(function()
    Core = GetCore()
end)

-- ============================================
-- INVENTORY UPDATE FUNCTION
-- ============================================

function SetInventory(playerId)
    while Core == nil do
        Wait(0)
    end

    if Config.Framework == "qb" or Config.Framework == "oldqb" then
        local player = GetPlayer(tonumber(playerId))
        if player then
            local identifier = GetIdentifier(tonumber(playerId))
            if not identifier then return end
            player.Functions.SetPlayerData("items", PlayerServerInventory[identifier].inventory)
        end
    elseif Config.Framework == "esx" then
        local player = Core.GetPlayerFromId(playerId)
        if player then
            local identifier = GetIdentifier(tonumber(playerId))
            if not identifier then return end
            player.set("inv", PlayerServerInventory[identifier].inventory)
        end
    end
end

-- ============================================
-- STARTUP CHECKS
-- ============================================

Citizen.CreateThread(function()
    Citizen.Wait(15000)
    local weaponsState = GetResourceState("qb-weapons")
    if weaponsState == "started" then
        for i = 1, 20 do
            print("PLS DELETE QB-WEAPONS RESOURCE")
        end
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    local smallResourcesState = GetResourceState("qb-smallresources")
    if smallResourcesState == "started" then
        local weapDrawFile = "client/weapdraw.lua"
        local fileContent = LoadResourceFile("qb-smallresources", weapDrawFile)
        if fileContent then
            for i = 1, 20 do
                print("PLS DELETE QB-SMALLRESOURCES/CLIENT/WEAPDRAW.LUA")
            end
        end
    end
end)

-- ============================================
-- RESOURCE START HANDLER
-- ============================================

AddEventHandler("onResourceStart", function(resourceName)
    while Core == nil do Wait(0) end
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.Framework == "qb" or Config.Framework == "oldqb" then
        local players = Core.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            SetMethods(player)
        end
    end
end)

-- ============================================
-- DATABASE INITIALIZATION - STASH
-- ============================================

Citizen.CreateThread(function()
    local stashData = ExecuteSql("SELECT * FROM `codem_new_stash`")
    local deletedCount = 0

    for i = 1, #stashData do
        local row = stashData[i]
        local inventory = json.decode(row.inventory or "{}")

        if next(inventory) == nil then
            ExecuteSql("DELETE FROM `codem_new_stash` WHERE `stashname` = @stashname", {
                ["@stashname"] = row.stashname
            })
            deletedCount = deletedCount + 1
        else
            ServerStash[row.stashname] = {
                stashname = row.stashname,
                inventory = inventory
            }
        end
    end

    if deletedCount > 0 then
        print("^2 Deleted empty stash records, count: " .. deletedCount .. " ^0")
    end
end)

-- ============================================
-- DATABASE INITIALIZATION - CLOTHING
-- ============================================

Citizen.CreateThread(function()
    if Config.ItemClothingSystem then
        local clothingData = ExecuteSql("SELECT * FROM `codem_new_clothingsitem`")
        local deletedCount = 0

        for i = 1, #clothingData do
            local row = clothingData[i]
            local inventory = json.decode(row.inventory or "{}")

            if next(inventory) == nil then
                ExecuteSql("DELETE FROM `codem_new_clothingsitem` WHERE `identifier` = @identifier", {
                    ["@identifier"] = row.identifier
                })
                deletedCount = deletedCount + 1
            else
                ClothingInventory[row.identifier] = {
                    identifier = row.identifier,
                    inventory = inventory
                }
            end
        end

        if deletedCount > 0 then
            print("^2Deleted empty clothing data records, count: " .. deletedCount .. "^0")
        end

        for _, playerId in pairs(GetPlayers()) do
            local id = tonumber(playerId)
            local identifier = GetIdentifier(id)
            if ClothingInventory[identifier] then
                TriggerClientEvent("codem-inventory:loadclothingdata", tonumber(id), ClothingInventory[identifier].inventory)
            end
        end
    end
end)

-- ============================================
-- DATABASE INITIALIZATION - VEHICLES
-- ============================================

Citizen.CreateThread(function()
    local vehicleData = ExecuteSql("SELECT * FROM `codem_new_vehicleandglovebox`")
    local deletedCount = 0

    for i = 1, #vehicleData do
        local row = vehicleData[i]
        local correctedPlate = string.lower(string.gsub(row.plate, "%s+", ""))

        if correctedPlate ~= row.plate then
            ExecuteSql("UPDATE `codem_new_vehicleandglovebox` SET `plate` = @correctedPlate WHERE `plate` = @originalPlate", {
                ["@correctedPlate"] = correctedPlate,
                ["@originalPlate"] = row.plate
            })
        end

        local trunk = json.decode(row.trunk or "{}")
        local glovebox = json.decode(row.glovebox or "{}")

        if next(trunk) == nil and next(glovebox) == nil then
            ExecuteSql("DELETE FROM `codem_new_vehicleandglovebox` WHERE `plate` = @plate", {
                ["@plate"] = row.plate
            })
            deletedCount = deletedCount + 1
        else
            if next(trunk) ~= nil then
                VehicleInventory[correctedPlate] = {
                    plate = correctedPlate,
                    trunk = trunk
                }
            end
            if next(glovebox) ~= nil then
                GloveBoxInventory[correctedPlate] = {
                    plate = correctedPlate,
                    glovebox = glovebox
                }
            end
        end
    end

    if deletedCount > 0 then
        print("^2 DELETED EMPTY VEHICLE SQL, COUNT : " .. deletedCount .. "^0")
    end
end)

-- ============================================
-- DUPLICATE ITEMS CHECK
-- ============================================

function CheckDuplicateItems(playerId)
    local id = tonumber(playerId)
    local identifier = Identifier[id]
    if not identifier then return end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then return end

    if identifier then
        if duplicateCheckCooldown[id] and (os.time() - duplicateCheckCooldown[id]) < 600 then
            return
        end
    end

    duplicateCheckCooldown[id] = os.time()
    local seriesMap = {}

    for slot, item in pairs(inventory) do
        if item.info and item.info.series then
            local series = item.info.series
            if not seriesMap[series] then
                seriesMap[series] = {}
            end
            table.insert(seriesMap[series], item)
        end
    end

    for series, items in pairs(seriesMap) do
        if #items > 1 then
            print("Duplicate items detected for series: " .. series .. ". Count: " .. #items .. " Player: " .. GetName(id))

            if Config.UseDiscordWebhooks then
                local logData = {
                    playername = GetName(id) .. "-" .. id,
                    reason = "DUPLICATE ITEMS DETECTED",
                    itemname = items[1].name,
                    info = items[1].info or nil,
                    amount = 1
                }
                TriggerEvent("codem-inventory:CreateLog", "DUPLICATE ITEMS", "green", logData, id, "cheater")
                DropPlayer(id, "Duplicate Player Inventory")
            end
        end
    end
end

-- ============================================
-- PLAYER INVENTORY LOAD
-- ============================================

RegisterServerEvent("codem-inventory:server:loadPlayerInventory")
AddEventHandler("codem-inventory:server:loadPlayerInventory", function()
    local playerId = tonumber(source)
    local identifier = GetIdentifier(playerId)
    local player = GetPlayer(playerId)

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    if Config.Framework == "qb" or Config.Framework == "oldqb" then
        local playerItems = player.PlayerData.items

        if PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory then
            Identifier[tonumber(playerId)] = identifier
            PlayerServerInventory[identifier].inventory = playerItems
        else
            if Identifier[tonumber(playerId)] then
                Identifier[tonumber(playerId)] = nil
            end
            Identifier[tonumber(playerId)] = identifier
            PlayerServerInventory[identifier] = {
                identifier = identifier,
                inventory = playerItems
            }
        end

        if Config.ItemClothingSystem then
            if not ClothingInventory[identifier] then
                ClothingInventory[identifier] = {
                    identifier = identifier,
                    inventory = {}
                }
            end
            TriggerClientEvent("codem-inventory:loadclothingdata", playerId, ClothingInventory[identifier].inventory)
        end

        if Config.CashItem then
            local cashAmount = GetPlayerMoney(playerId, "cash")
            SetInventoryItems(playerId, "cash", cashAmount)
        end

        CheckDuplicateItems(playerId)
    end

    if Config.Framework == "esx" or Config.Framework == "oldesx" then
        local playerItems = player.get("inv")

        if PlayerServerInventory[identifier] then
            Identifier[tonumber(playerId)] = identifier
            PlayerServerInventory[identifier].inventory = playerItems
        else
            Identifier[tonumber(playerId)] = identifier
            PlayerServerInventory[identifier] = {
                identifier = identifier,
                inventory = playerItems
            }
        end

        if Config.ItemClothingSystem then
            if not ClothingInventory[identifier] then
                ClothingInventory[identifier] = {
                    identifier = identifier,
                    inventory = {}
                }
            end
            TriggerClientEvent("codem-inventory:loadclothingdata", playerId, ClothingInventory[identifier].inventory)
        end

        if Config.CashItem then
            local cashAmount = GetPlayerMoney(playerId, "cash")
            SetInventoryItems(playerId, "cash", cashAmount)
        end

        CheckDuplicateItems(playerId)
    end

    TriggerClientEvent("codem-inventory:client:loadClientInventory", playerId, PlayerServerInventory[identifier].inventory)
    TriggerClientEvent("codem-inventory:client:loadAllVehicleInventory", playerId, VehicleInventory)
    TriggerClientEvent("codem-inventory:client:loadAllGround", playerId, ServerGround)
    TriggerClientEvent("codem-inventory:client:loadAllVehicleGlovebox", playerId, GloveBoxInventory)

    ServerPlayerKey[playerId] = "CODEM" .. math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. "KEY"
    TriggerClientEvent("codem-inventory:client:setkey", playerId, ServerPlayerKey[playerId])
end)

-- ============================================
-- ITEM SWAP - PLAYER INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:server:checkPlayerItemForSwap")
AddEventHandler("codem-inventory:server:checkPlayerItemForSwap", function(data)
    local playerId = source
    local id = tonumber(playerId)
    local identifier = Identifier[id]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    if cooldown[id] then
        return
    else
        cooldown[id] = true
        SetTimeout(600, function()
            cooldown[id] = nil
        end)
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local oldSlot = tostring(data.oldSlot)
    local newSlot = tostring(data.newSlot)
    local item = inventory[oldSlot]

    if item then
        inventory[newSlot] = item
        inventory[newSlot].slot = newSlot
        inventory[oldSlot] = nil
        TriggerClientEvent("codem-inventory:client:ChangeSwapItem", playerId, data.oldSlot, data.newSlot)
        SetInventory(playerId)
    end
end)

-- ============================================
-- ITEM SWAP WITH TARGET - PLAYER INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:server:checkPlayerItemForSwapTargetItem")
AddEventHandler("codem-inventory:server:checkPlayerItemForSwapTargetItem", function(data)
    local playerId = tonumber(source)
    local identifier = Identifier[tonumber(playerId)]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    if cooldown[tonumber(playerId)] then
        return
    else
        cooldown[tonumber(playerId)] = true
        SetTimeout(1000, function()
            cooldown[tonumber(playerId)] = nil
        end)
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then return end

    if inventory then
        local oldItem = inventory[tostring(data.oldSlot)]
        local newItem = inventory[tostring(data.newSlot)]

        if oldItem and newItem then
            if oldItem.name == newItem.name and not oldItem.unique and not newItem.unique then
                inventory[tostring(data.newSlot)].amount = inventory[tostring(data.newSlot)].amount + oldItem.amount
                inventory[tostring(data.oldSlot)] = nil
                TriggerClientEvent("codem-inventory:client:ChangeSwapItemSimilarItem", playerId, data.oldSlot, data.newSlot)
                SetInventory(playerId)
            else
                inventory[tostring(data.oldSlot)] = newItem
                inventory[tostring(data.oldSlot)].slot = tostring(data.oldSlot)
                inventory[tostring(data.newSlot)] = oldItem
                inventory[tostring(data.newSlot)].slot = tostring(data.newSlot)
                TriggerClientEvent("codem-inventory:client:ChangeSwapItemTargetItem", playerId, data.oldSlot, data.newSlot)
                SetInventory(playerId)
            end
            Citizen.Wait(1000)
        else
            Citizen.Wait(1000)
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUND)
        end
    end
end)

-- ============================================
-- GROUND TO INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:SwapGroundToInventory")
AddEventHandler("codem-inventory:SwapGroundToInventory", function(data, groundId)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier or not ServerGround[groundId] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local groundInventory = ServerGround[groundId].inventory
    local item = groundInventory[tostring(data.oldSlot)]

    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUND)
        return
    end

    if not CheckInventoryWeight(inventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    if item and item.type == "bag" then
        local bagCount = CheckBagItem(playerId)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.MAXBAGPACKITEM)
            return
        end
    end

    local function addItemToInventory(slot, itemData)
        if inventory[slot] then
            if inventory[slot].name == itemData.name and not itemData.unique then
                inventory[slot].amount = inventory[slot].amount + itemData.amount
            end
        else
            if itemData.unique then
                slot = FindFirstEmptySlot(inventory, Config.MaxSlots)
                if not slot then
                    TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
                    return
                end
                slot = tostring(slot)
                itemData.slot = slot
                inventory[slot] = itemData
                inventory[slot].slot = slot
            else
                slot = FindFirstEmptySlot(inventory, Config.MaxSlots)
                slot = tostring(slot)
                if not slot then
                    TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
                    return
                end
                itemData.slot = slot
                inventory[slot] = itemData
                inventory[slot].slot = slot
            end
        end

        TriggerClientEvent("codem-inventory:client:additem", playerId, slot, inventory[slot])

        if Config.UseDiscordWebhooks then
            local logData = {
                playername = GetName(playerId) .. "-" .. playerId,
                itemname = item.label,
                info = item.info or nil,
                amount = item.amount,
                reason = Locales[Config.Language].notification.GROUNDTOINVENTORY
            }
            TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMS, "green", logData, playerId)
        end
    end

    addItemToInventory(tostring(data.newSlot), item)
    groundInventory[data.oldSlot] = nil

    if not next(ServerGround[groundId].inventory) then
        ServerGround[groundId] = nil
        TriggerClientEvent("codem-inventory:client:removeGroundTable", -1, groundId)
    else
        TriggerClientEvent("codem-inventory:client:SetGroundTable", -1, groundId, ServerGround[groundId].coord, ServerGround[groundId].inventory)
    end

    if Config.CashItem and item.name == "cash" then
        AddMoney(playerId, "cash", item.amount)
    else
        SetInventory(playerId)
    end

    TriggerClientEvent("codem-inventory:dropanim", playerId)
end)

-- ============================================
-- INVENTORY TO GROUND
-- ============================================

RegisterServerEvent("codem-inventory:SwapInventoryToGround")
AddEventHandler("codem-inventory:SwapInventoryToGround", function(data, groundId)
    local playerId = tonumber(source)
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.oldSlot = tostring(data.oldSlot)
    data.newSlot = tostring(data.newSlot)

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[data.oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    local groundInventory = ServerGround[groundId] and ServerGround[groundId].inventory or {}
    local targetItem = groundInventory[data.newSlot]

    if not data.newSlot then
        local emptySlot = FindFirstEmptySlot(groundInventory, Config.GroundSlots)
        if not emptySlot then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEGROUND)
            return
        end
        data.newSlot = tostring(emptySlot)
    end

    if not groundId then
        groundId = GenerateGroundId()
        local coords = GetEntityCoords(GetPlayerPed(playerId))
        item.object = nil
        ServerGround[groundId] = {
            inventory = {["1"] = item},
            coord = coords,
            id = groundId
        }
        item.slot = "1"
        TriggerClientEvent("codem-inventory:client:SetGroundTable", -1, groundId, coords, ServerGround[groundId].inventory)
    elseif targetItem then
        local emptySlot = FindFirstEmptySlot(groundInventory, Config.GroundSlots)
        if not emptySlot then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEGROUND)
            return
        end
        emptySlot = tostring(emptySlot)
        item.slot = emptySlot
        groundInventory[emptySlot] = item
        ServerGround[groundId].inventory = groundInventory
        TriggerClientEvent("codem-inventory:client:SetGroundTable", -1, groundId, ServerGround[groundId].coord, groundInventory)
    else
        local emptySlot = FindFirstEmptySlot(groundInventory, Config.GroundSlots)
        if not emptySlot then
            TriggerClientEvent("codem-inventory:client:notification", playerId, "No empty slot available in ground inventory")
            return
        end
        emptySlot = tostring(emptySlot)
        item.slot = emptySlot
        groundInventory[emptySlot] = item
        ServerGround[groundId].inventory = groundInventory
        TriggerClientEvent("codem-inventory:client:SetGroundTable", -1, groundId, ServerGround[groundId].coord, groundInventory)
    end

    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", playerId, data.oldSlot, inventory[data.oldSlot].amount)
    inventory[data.oldSlot] = nil

    if Config.CashItem and item.name == "cash" then
        local totalCash = GetItemsTotalAmount(playerId, "cash")
        local player = GetPlayer(playerId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    else
        SetInventory(playerId)
    end

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            info = item.info or nil,
            amount = item.amount,
            reason = Locales[Config.Language].notification.INVENTORYTOGROUND
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMGROUND, "green", logData, playerId, "drop")
    end

    TriggerClientEvent("codem-inventory:dropanim", playerId)
end)

-- ============================================
-- GENERATE GROUND ID
-- ============================================

function GenerateGroundId()
    local id = math.random(111111, 999999)
    while ServerGround[id] do
        id = math.random(111111, 999999)
    end
    return id
end

-- ============================================
-- STASH OPERATIONS
-- ============================================

RegisterServerEvent("codem-inventory:server:openserverstash")
AddEventHandler("codem-inventory:server:openserverstash", function(playerId, stashId, maxSlots, maxWeight, label)
    if maxSlots and maxSlots > 500 then
        maxSlots = 500
    end
    if not maxWeight then
        maxWeight = 150000
    end

    local stashExists = ServerStash[stashId] ~= nil
    local inventory = stashExists and ServerStash[stashId].inventory or {}

    local stashData = {
        inventory = inventory,
        slot = maxSlots,
        maxweight = maxWeight,
        stashId = stashId,
        label = label
    }

    if not stashExists then
        ServerStash[stashId] = {
            inventory = {},
            stashname = stashId
        }
    end

    UpdateStashDatabase(stashId, inventory)
    TriggerClientEvent("codem-inventory:client:openstash", playerId, stashData)
end)

RegisterServerEvent("inventory:server:OpenInventory")
AddEventHandler("inventory:server:OpenInventory", function()
end)

AddEventHandler("inventory:server:OpenInventory", function(inventoryType, stashId, data)
    if inventoryType == "traphouse" then
        local playerId = source
        local label = "STASH"
        local maxWeight = data.weight or 150000
        local maxSlots = data.slots or 5

        local stashExists = ServerStash[stashId] ~= nil
        local inventory = stashExists and ServerStash[stashId].inventory or {}

        local stashData = {
            inventory = inventory,
            slot = maxSlots,
            maxweight = maxWeight,
            stashId = stashId,
            label = label
        }

        if not stashExists then
            ServerStash[stashId] = {
                inventory = {},
                stashname = stashId
            }
        end

        UpdateStashDatabase(stashId, inventory)
        TriggerClientEvent("codem-inventory:client:openstash", playerId, stashData)

    elseif inventoryType == "stash" then
        local playerId = source
        local label = "STASH"
        local maxWeight = 60000
        local maxSlots = 50

        if data and next(data) ~= nil then
            maxWeight = data.maxweight or 60000
            maxSlots = data.slots or 50
        end

        if stashId == "personelstash" then
            stashId = GetIdentifier(playerId)
        end

        local stashExists = ServerStash[stashId] ~= nil
        local inventory = stashExists and ServerStash[stashId].inventory or {}

        local stashData = {
            inventory = inventory,
            slot = maxSlots,
            maxweight = maxWeight,
            stashId = stashId,
            label = label
        }

        if not stashExists then
            ServerStash[stashId] = {
                inventory = {},
                stashname = stashId
            }
        end

        UpdateStashDatabase(stashId, inventory)
        TriggerClientEvent("codem-inventory:client:openstash", playerId, stashData)
    end
end)

RegisterServerEvent("codem-inventory:server:openstash")
AddEventHandler("codem-inventory:server:openstash", function(stashId, maxSlots, maxWeight, label, extraData)
    if maxSlots and maxSlots > 500 then
        maxSlots = 500
    end
    if not maxWeight then
        maxWeight = 150000
    end

    local playerId = tonumber(source)

    ServerPlayerKey[playerId] = "CODEM" .. math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. "KEY"
    TriggerClientEvent("codem-inventory:client:setkey", playerId, ServerPlayerKey[playerId])

    if stashId == "personelstash" then
        stashId = GetIdentifier(playerId)
    end

    local stashExists = ServerStash[stashId] ~= nil
    local inventory = stashExists and ServerStash[stashId].inventory or {}

    local stashData = {
        inventory = inventory,
        slot = maxSlots,
        maxweight = maxWeight,
        stashId = stashId,
        label = label
    }

    if not stashExists then
        ServerStash[stashId] = {
            inventory = {},
            stashname = stashId
        }
    end

    UpdateStashDatabase(stashId, inventory)
    TriggerClientEvent("codem-inventory:client:openstash", playerId, stashData)
end)

-- ============================================
-- INVENTORY TO STASH
-- ============================================

RegisterServerEvent("codem-inventory:SwapInventoryToStash")
AddEventHandler("codem-inventory:SwapInventoryToStash", function(data)
    local playerId = tonumber(source)
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[tostring(data.oldSlot)]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    local stashInventory = ServerStash[data.stashId].inventory
    if not stashInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.STASHINVENTORYNOTFOUND)
        return
    end

    if not CheckInventoryWeight(stashInventory, item.weight * item.amount, data.weight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLESTASH)
        return
    end

    if item.type == "bag" then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.YOUCANNOTPUTABAG)
        return
    end

    local emptySlot = FindFirstEmptySlot(stashInventory, tonumber(data.maxslot))
    if not emptySlot or emptySlot == "nil" then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLESTASH)
        return
    end

    emptySlot = tostring(emptySlot)

    if not item.unique then
        local existingSlot = stashInventory[tostring(data.newSlot)]
        if existingSlot then
            item.slot = emptySlot
            stashInventory[emptySlot] = item
        else
            local existingItem = FindExistingItemSlot(stashInventory, item.name)
            if existingItem then
                stashInventory[tostring(existingItem)].amount = stashInventory[tostring(existingItem)].amount + item.amount
            else
                item.slot = emptySlot
                stashInventory[emptySlot] = item
            end
        end
    else
        item.slot = emptySlot
        stashInventory[emptySlot] = item
    end

    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", playerId, data.oldSlot, inventory[tostring(data.oldSlot)].amount)
    inventory[tostring(data.oldSlot)] = nil

    TriggerClientEvent("codem-inventory:UpdateStashItems", playerId, data.stashId, stashInventory)

    if Config.CashItem and item.name == "cash" then
        local totalCash = GetItemsTotalAmount(playerId, "cash")
        local player = GetPlayer(playerId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    else
        SetInventory(playerId)
    end

    UpdateStashDatabase(data.stashId, stashInventory)

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Stash Name: " .. data.stashId .. " " .. Locales[Config.Language].notification.INVENTORYTOSTASH
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMSTASH, "green", logData, playerId, "stash")
    end
end)

-- ============================================
-- STASH TO INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:swapStashToInventory")
AddEventHandler("codem-inventory:swapStashToInventory", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local stashInventory = ServerStash[data.stashId].inventory
    local item = stashInventory[data.oldSlot]

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if not CheckInventoryWeight(inventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    local function addItem(slot, itemData)
        if inventory[slot] then
            if inventory[slot].name == itemData.name and not itemData.unique then
                inventory[slot].amount = inventory[slot].amount + itemData.amount
            end
        else
            if itemData.unique then
                slot = FindFirstEmptySlot(inventory, Config.MaxSlots)
                if not slot then
                    TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
                    return false
                end
                slot = tostring(slot)
                itemData.slot = slot
                inventory[slot] = itemData
                inventory[slot].slot = slot
            else
                slot = FindFirstEmptySlot(inventory, Config.MaxSlots)
                if not slot then
                    TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
                    return false
                end
                slot = tostring(slot)
                itemData.slot = slot
                inventory[slot] = itemData
                inventory[slot].slot = slot
            end
        end
        return slot
    end

    local newSlot = addItem(data.newSlot, item)
    if not newSlot then return end

    newSlot = tostring(newSlot)
    stashInventory[data.oldSlot] = nil

    if Config.CashItem and item.name == "cash" then
        AddMoney(playerId, "cash", item.amount)
    else
        SetInventory(playerId)
    end

    TriggerClientEvent("codem-inventory:client:additem", playerId, newSlot, inventory[newSlot])
    TriggerClientEvent("codem-inventory:UpdateStashItems", playerId, data.stashId, stashInventory)

    UpdateStashDatabase(data.stashId, stashInventory)
    SetInventory(playerId)

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Stash Name: " .. data.stashId .. " " .. Locales[Config.Language].notification.STASHTOINVENTORY
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMS, "green", logData, playerId)
    end
end)

-- ============================================
-- STASH TO STASH
-- ============================================

RegisterServerEvent("codem-inventory:swapStashToStash")
AddEventHandler("codem-inventory:swapStashToStash", function(data)
    local playerId = source

    if cooldown[playerId] then
        return
    else
        cooldown[playerId] = true
        SetTimeout(400, function()
            cooldown[playerId] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local stashId = data.stashId
    local oldSlot = tostring(data.oldSlot)
    local newSlot = tostring(data.newSlot)

    local stashInventory = ServerStash[stashId] and ServerStash[stashId].inventory
    if not stashInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.STASHINVENTORYNOTFOUND)
        return
    end

    local item = stashInventory[oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    local targetItem = stashInventory[newSlot]

    if targetItem and item.name == targetItem.name and not item.unique then
        stashInventory[newSlot].amount = stashInventory[newSlot].amount + item.amount
        stashInventory[oldSlot] = nil
    elseif not targetItem then
        stashInventory[newSlot] = item
        stashInventory[newSlot].slot = newSlot
        stashInventory[oldSlot] = nil
    else
        local temp = stashInventory[newSlot]
        stashInventory[newSlot] = stashInventory[oldSlot]
        stashInventory[oldSlot] = temp
        stashInventory[oldSlot].slot = oldSlot
        stashInventory[newSlot].slot = newSlot
    end

    UpdateStashDatabase(stashId, stashInventory)
    TriggerClientEvent("codem-inventory:UpdateStashItems", playerId, stashId, stashInventory)
end)

-- ============================================
-- UPDATE STASH DATABASE
-- ============================================

function UpdateStashDatabase(stashName, inventory)
    local query = [[
            INSERT INTO codem_new_stash (stashname, inventory) VALUES (@stashname, @inventory) ON DUPLICATE KEY UPDATE inventory = @inventory
    ]]

    local params = {
        ["@stashname"] = stashName,
        ["@inventory"] = json.encode(inventory)
    }

    local success, err = pcall(function()
        UpdateInventorySql(query, params)
    end)

    if not success then
        print("Error updating stash database: " .. err)
    end
end

-- ============================================
-- FIND EXISTING ITEM SLOT
-- ============================================

function FindExistingItemSlot(inventory, itemName)
    for slot, item in pairs(inventory) do
        if item.name == itemName then
            return slot
        end
    end
    return nil
end

-- ============================================
-- VEHICLE GLOVEBOX OPERATIONS
-- ============================================

RegisterServerEvent("codem-inventory:server:openVehicleGlovebox")
AddEventHandler("codem-inventory:server:openVehicleGlovebox", function(plate, maxWeight, maxSlots, extraData)
    local playerId = source

    ServerPlayerKey[playerId] = "CODEM" .. math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. "KEY"
    TriggerClientEvent("codem-inventory:client:setkey", playerId, ServerPlayerKey[playerId])

    if not plate then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.VEHICLEPLATENOTFOUND)
        return
    end

    plate = customToLower(plate)

    if not GloveBoxInventory[plate] then
        GloveBoxInventory[plate] = {
            glovebox = {},
            plate = plate,
            maxweight = maxWeight or 0,
            slot = maxSlots or 0
        }
        TriggerClientEvent("codem-inventory:client:newVehicleGloveboxPlateInsert", -1, plate, maxWeight, maxSlots)
    end

    local gloveboxData = {
        glovebox = GloveBoxInventory[plate].glovebox,
        slot = GloveBoxInventory[plate].slot,
        maxweight = GloveBoxInventory[plate].maxweight,
        plate = plate
    }

    TriggerClientEvent("codem-inventory:client:openVehicleGlovebox", playerId, gloveboxData)
end)

-- ============================================
-- INVENTORY TO GLOVEBOX
-- ============================================

RegisterServerEvent("codem-inventory:SwapInventoryToVehicleGlovebox")
AddEventHandler("codem-inventory:SwapInventoryToVehicleGlovebox", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.newSlot = tostring(data.newSlot)
    data.oldSlot = tostring(data.oldSlot)
    local plate = customToLower(data.plate)

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[data.oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if not GloveBoxInventory[plate] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.VEHICLEPLATENOTFOUND)
        return
    end

    local gloveboxInventory = GloveBoxInventory[plate].glovebox
    if not gloveboxInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEVEHICLE)
        return
    end

    local emptySlot = FindFirstEmptySlot(gloveboxInventory, tonumber(data.maxslot))
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    emptySlot = tostring(emptySlot)
    local splitAmount = tonumber(data.amount)

    if splitAmount < 1 or splitAmount >= tonumber(item.amount) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVALODAMOUNTSPLIT)
        return
    end

    local newItem = {
        name = item.name,
        label = item.label or item.name,
        weight = item.weight or 0,
        type = item.type or "item",
        amount = splitAmount,
        usable = item.usable or false,
        shouldClose = item.shouldClose or false,
        description = item.description or "",
        slot = tonumber(emptySlot),
        image = item.image or (item.name .. ".png"),
        unique = item.unique or false,
        info = item.info or nil
    }

    inventory[emptySlot] = newItem
    inventory[tostring(data.item.slot)].amount = tonumber(item.amount) - splitAmount

    TriggerClientEvent("codem-inventory:client:splitItem", playerId, emptySlot, inventory[emptySlot], data.item.slot, inventory[tostring(data.item.slot)])
    SetInventory(playerId)
end)

-- ============================================
-- GIVE ITEM TO NEARBY PLAYER
-- ============================================

RegisterServerEvent("codem-inventory:server:giveItemToPlayerNearby")
AddEventHandler("codem-inventory:server:giveItemToPlayerNearby", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[tostring(data.item.slot)]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    local targetId = tonumber(data.player)
    if not targetId then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetPlayer = GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    if item and item.type == "bag" then
        local bagCount = CheckBagItem(targetId)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.MAXBAGPACKITEM)
            return
        end
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    local distance = #(playerCoords - targetCoords)

    if distance > 5.0 then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NEARBYPLAYERNOTFOUND)
        return
    end

    local targetIdentifier = Identifier[targetId]
    if not targetIdentifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetInventory = PlayerServerInventory[targetIdentifier].inventory

    if not CheckInventoryWeight(targetInventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLETARGET)
        return
    end

    local emptySlot = FindFirstEmptySlot(targetInventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLETARGET)
        return
    end

    emptySlot = tostring(emptySlot)
    targetInventory[emptySlot] = item
    targetInventory[emptySlot].slot = emptySlot

    local amount = inventory[tostring(data.item.slot)].amount or 1
    inventory[tostring(data.item.slot)] = nil

    if Config.CashItem and item.name == "cash" then
        AddMoney(targetId, "cash", item.amount)
        local totalCash = GetItemsTotalAmount(playerId, "cash")
        local player = GetPlayer(playerId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    end

    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", playerId, data.item.slot, amount)
    TriggerClientEvent("codem-inventory:client:additem", targetId, emptySlot, targetInventory[emptySlot])

    SetInventory(playerId)
    SetInventory(targetId)

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Target ID : " .. targetId .. " Target Name : " .. GetName(targetId) .. " " .. Locales[Config.Language].notification.GIVEITEMTOPLAYER
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.GIVEITEMTOPLAYER, "green", logData, playerId, "give")
    end

    TriggerClientEvent("codem-inventory:giveanim", playerId)
    TriggerClientEvent("codem-inventory:giveanim", targetId)
end)

-- ============================================
-- ROB PLAYER
-- ============================================

RegisterServerEvent("codem-inventory:server:robplayer")
AddEventHandler("codem-inventory:server:robplayer", function(targetId)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local targetPlayerId = tonumber(targetId)
    if not targetPlayerId then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetIdentifier = Identifier[targetPlayerId]
    if not targetIdentifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetInventory = PlayerServerInventory[targetIdentifier].inventory
    if not targetInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local targetJob = GetJob(targetPlayerId)
    if Config.NotRobJob[targetJob] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOTROBJOB)
        return
    end

    if Config.Cheaterlogs then
        local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
        local targetCoords = GetEntityCoords(GetPlayerPed(targetPlayerId))
        local distance = #(playerCoords - targetCoords)

        if distance > 5.0 then
            if Config.UseDiscordWebhooks then
                local logData = {
                    playername = GetName(playerId) .. "-" .. playerId .. ", Identifier : " .. identifier,
                    event = "Rob Player Distance : " .. distance
                }
                TriggerEvent("codem-inventory:cheaterlogs", logData)
            end
            return
        end
    end

    TriggerClientEvent("codem-inventory:client:OpenPlayerInventory", playerId, targetInventory, targetPlayerId, GetName(targetPlayerId))
    TriggerClientEvent("codem-inventory:client:robstatus", targetPlayerId, true)
end)

-- ============================================
-- OPEN PLAYER INVENTORY (ADMIN)
-- ============================================

RegisterServerEvent("codem-inventory:server:openplayerinventory")
AddEventHandler("codem-inventory:server:openplayerinventory", function(targetId)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local targetPlayerId = tonumber(targetId)
    if not targetPlayerId then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetIdentifier = Identifier[targetPlayerId]
    if not targetIdentifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetInventory = PlayerServerInventory[targetIdentifier].inventory
    if not targetInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    if Config.Cheaterlogs then
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            if Core.Functions.HasPermission(playerId, "user") then
                if Config.UseDiscordWebhooks then
                    local logData = {
                        playername = GetName(playerId) .. "-" .. playerId .. ", Identifier : " .. identifier,
                        event = "Open Player Inventory Event : "
                    }
                    TriggerEvent("codem-inventory:cheaterlogs", logData)
                    return
                end
            end
        elseif Config.Framework == "esx" or Config.Framework == "oldesx" then
            if not CheckIfAdmin(playerId) then
                if Config.UseDiscordWebhooks then
                    local logData = {
                        playername = GetName(playerId) .. "-" .. playerId .. ", Identifier : " .. identifier,
                        event = "Open Player Inventory Event "
                    }
                    TriggerEvent("codem-inventory:cheaterlogs", logData)
                    return
                end
            end
        end
    end

    TriggerClientEvent("codem-inventory:client:OpenPlayerInventory", playerId, targetInventory, targetPlayerId, GetName(targetPlayerId))
    TriggerClientEvent("codem-inventory:client:robstatus", targetPlayerId, true)
end)

-- ============================================
-- ROB PLAYER TO MAIN INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:server:swaprobplayertomaininventory")
AddEventHandler("codem-inventory:server:swaprobplayertomaininventory", function(data)
    local playerId = tonumber(source)
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local targetId = tonumber(data.playerid)
    if not targetId then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetIdentifier = Identifier[targetId]
    if not targetIdentifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetInventory = PlayerServerInventory[targetIdentifier].inventory
    if not targetInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    data.itemname.slot = tostring(data.itemname.slot)
    local item = targetInventory[data.itemname.slot]

    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    local emptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    if Config.NotRobItem[item.name] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOTSWAPITEM)
        return
    end

    if item and item.type == "bag" then
        local bagCount = CheckBagItem(playerId)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.MAXBAGPACKITEM)
            return
        end
    end

    if not CheckInventoryWeight(inventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    emptySlot = tostring(emptySlot)
    inventory[emptySlot] = item
    inventory[emptySlot].slot = emptySlot

    local amount = targetInventory[data.itemname.slot].amount or 1
    targetInventory[data.itemname.slot] = nil

    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", targetId, data.itemname.slot, amount)
    TriggerClientEvent("codem-inventory:client:additem", playerId, emptySlot, inventory[emptySlot])
    TriggerClientEvent("codem-inventory:refreshrobplayerinventory", playerId, targetInventory)

    if Config.CashItem and item.name == "cash" then
        AddMoney(playerId, "cash", item.amount)
        local totalCash = GetItemsTotalAmount(targetId, "cash")
        local player = GetPlayer(targetId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    else
        SetInventory(playerId)
    end

    SetInventory(targetId)

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Target ID : " .. targetId .. " Target Name : " .. GetName(targetId) .. " " .. Locales[Config.Language].notification.ROBPLAYER
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ROBPLAYER, "green", logData, playerId, "player")
    end
end)

-- ============================================
-- MAIN INVENTORY TO ROB PLAYER
-- ============================================

RegisterServerEvent("codem-inventory:server:swapmaininventorytorobplayer")
AddEventHandler("codem-inventory:server:swapmaininventorytorobplayer", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local targetId = tonumber(data.playerid)
    if not targetId then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetIdentifier = Identifier[targetId]
    if not targetIdentifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERNOTFOUND)
        return
    end

    local targetInventory = PlayerServerInventory[targetIdentifier].inventory
    if not targetInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    data.oldSlot = tostring(data.oldSlot)
    local item = inventory[data.oldSlot]

    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    local emptySlot = FindFirstEmptySlot(targetInventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLETARGET)
        return
    end

    if Config.NotRobItem[item.name] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOTSWAPITEM)
        return
    end

    if item and item.type == "bag" then
        local bagCount = CheckBagItem(playerId)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.MAXBAGPACKITEM)
            return
        end
    end

    if not CheckInventoryWeight(targetInventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    emptySlot = tostring(emptySlot)
    targetInventory[emptySlot] = item
    targetInventory[emptySlot].slot = emptySlot

    local amount = inventory[data.oldSlot].amount or 1
    inventory[data.oldSlot] = nil

    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", playerId, data.oldSlot, amount)
    TriggerClientEvent("codem-inventory:client:additem", targetId, emptySlot, targetInventory[emptySlot])
    TriggerClientEvent("codem-inventory:refreshrobplayerinventory", playerId, targetInventory)

    if Config.CashItem and item.name == "cash" then
        AddMoney(targetId, "cash", item.amount)
        local totalCash = GetItemsTotalAmount(playerId, "cash")
        local player = GetPlayer(playerId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    else
        SetInventory(playerId)
    end

    SetInventory(targetId)

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            info = item.info or nil,
            amount = item.amount,
            reason = "Target ID : " .. targetId .. " Target Name : " .. GetName(targetId) .. " " .. Locales[Config.Language].notification.ROBPLAYERADD
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ROBPLAYERADD, "green", logData, playerId, "player")
    end
end)

-- ============================================
-- CHANGE ROB STATUS
-- ============================================

RegisterServerEvent("codem-inventory:server:ChangePlayerRobStatus")
AddEventHandler("codem-inventory:server:ChangePlayerRobStatus", function(data)
    if data.playerid then
        TriggerClientEvent("codem-inventory:client:robstatus", tonumber(data.playerid), false)
    end
end)

-- ============================================
-- SORT ITEMS
-- ============================================

RegisterServerEvent("codem-inventory:server:sortItems")
AddEventHandler("codem-inventory:server:sortItems", function()
    local playerId = source
    local id = tonumber(playerId)

    if cooldown[id] then
        return
    else
        cooldown[id] = true
        SetTimeout(600, function()
            cooldown[id] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local tempInventory = {}

    for slot, item in pairs(inventory) do
        if not item.unique then
            if tempInventory[item.name] then
                tempInventory[item.name].amount = tempInventory[item.name].amount + item.amount
            end
        else
            if not item.unique then
                tempInventory[item.name] = item
            else
                tempInventory[tostring(slot)] = item
                tempInventory[tostring(slot)].slot = tostring(slot)
            end
        end
    end

    local sortedInventory = {}
    local slotCounter = 1

    for _, item in pairs(tempInventory) do
        sortedInventory[tostring(slotCounter)] = item
        sortedInventory[tostring(slotCounter)].slot = tostring(slotCounter)
        slotCounter = slotCounter + 1
    end

    PlayerServerInventory[identifier].inventory = sortedInventory

    TriggerClientEvent("codem-inventory:client:sortItems", playerId, PlayerServerInventory[identifier].inventory)
    SetInventory(playerId)
end)

RegisterServerEvent("codem-inventory:server:sortItemsStash")
AddEventHandler("codem-inventory:server:sortItemsStash", function(stashId)
    local playerId = source
    local id = tonumber(playerId)

    if cooldown[id] then
        return
    else
        cooldown[id] = true
        SetTimeout(600, function()
            cooldown[id] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local stashInventory = ServerStash[stashId] and ServerStash[stashId].inventory
    if not stashInventory then
        return
    end

    local tempInventory = {}

    for slot, item in pairs(stashInventory) do
        if not item.unique then
            if tempInventory[item.name] then
                tempInventory[item.name].amount = tempInventory[item.name].amount + item.amount
            end
        else
            if not item.unique then
                tempInventory[item.name] = item
            else
                tempInventory[tostring(slot)] = item
                tempInventory[tostring(slot)].slot = tostring(slot)
            end
        end
    end

    local sortedInventory = {}
    local slotCounter = 1

    for _, item in pairs(tempInventory) do
        sortedInventory[tostring(slotCounter)] = item
        sortedInventory[tostring(slotCounter)].slot = tostring(slotCounter)
        slotCounter = slotCounter + 1
    end

    ServerStash[stashId].inventory = sortedInventory

    TriggerClientEvent("codem-inventory:UpdateStashItems", playerId, stashId, sortedInventory)
    UpdateStashDatabase(stashId, sortedInventory)
end)

-- ============================================
-- CHECK SERVER ITEMS COMMANDS
-- ============================================

RegisterCommand(Config.Commands.checkserveronlineitems, function(source, args)
    if source > 0 then return end

    local itemName = args[1]
    local results = {}

    for identifier, data in pairs(PlayerServerInventory) do
        local inventory = data.inventory
        local totalAmount = 0

        for slot, item in pairs(inventory) do
            if item.name == itemName then
                totalAmount = totalAmount + item.amount
            end
        end

        if totalAmount > 0 then
            results[identifier] = (results[identifier] or 0) + totalAmount
        end
    end

    local sortedResults = {}
    for identifier, amount in pairs(results) do
        table.insert(sortedResults, {identifier = identifier, totalAmount = amount})
    end

    table.sort(sortedResults, function(a, b)
        return a.totalAmount > b.totalAmount
    end)

    local message = "Offline items report for `" .. itemName .. "`:\n"
    local limit = math.min(#sortedResults, 100)

    if limit > 0 then
        for i = 1, limit do
            local entry = sortedResults[i]
            message = message .. "Identifier: " .. entry.identifier .. ", Total Amount: " .. entry.totalAmount .. "\n"
        end
    else
        message = "No offline items found for `" .. itemName .. "`."
    end

    PerformHttpRequest(DiscordWebhook.checkserveritems, function(err, text, headers) end, "POST", json.encode({
        username = "Server Item Checker",
        embeds = {{
            title = "Server Online Items Check",
            description = message,
            color = 65280
        }}
    }), {["Content-Type"] = "application/json"})
end)

RegisterCommand(Config.Commands.checkserverofflineitems, function(source, args)
    if source > 0 then return end

    local itemName = args[1]
    if not itemName then return end

    local results = {}
    local sortedResults = {}
    local webhookUrl = DiscordWebhook.checkserveritems

    local inventoryData = ExecuteSql("SELECT identifier, inventory FROM `codem_new_inventory`")

    for _, row in ipairs(inventoryData) do
        local inventory = json.decode(row.inventory or "{}")
        local totalAmount = 0

        for _, item in pairs(inventory) do
            if item.name == itemName then
                totalAmount = totalAmount + item.amount
            end
        end

        if totalAmount > 0 then
            results[row.identifier] = (results[row.identifier] or 0) + totalAmount
        end
    end

    for identifier, amount in pairs(results) do
        table.insert(sortedResults, {identifier = identifier, totalAmount = amount})
    end

    table.sort(sortedResults, function(a, b)
        return a.totalAmount > b.totalAmount
    end)

    local message = "Offline items report for `" .. itemName .. "`:\n"
    local limit = math.min(#sortedResults, 100)

    if limit > 0 then
        for i = 1, limit do
            local entry = sortedResults[i]
            message = message .. "Identifier: " .. entry.identifier .. ", Total Amount: " .. entry.totalAmount .. "\n"
        end
    else
        message = "No offline items found for `" .. itemName .. "`."
    end

    PerformHttpRequest(webhookUrl, function(err, text, headers) end, "POST", json.encode({
        username = "Server Item Checker",
        embeds = {{
            title = "Server Offline Items Check",
            description = message,
            color = 65280
        }}
    }), {["Content-Type"] = "application/json"})
end)

-- ============================================
-- DUPLICATE ITEMS CHECK SYSTEM
-- ============================================

local duplicateData = {}

local function processInventoryData(data, sourceType)
    for _, row in ipairs(data) do
        local inventory = json.decode(row.inventory or "{}")

        for slot, item in pairs(inventory) do
            if item.info and item.info.series then
                local series = item.info.series

                if not duplicateData[series] then
                    duplicateData[series] = {
                        name = item.name,
                        count = 0,
                        sources = {}
                    }
                end

                local identifier = row.identifier or row.stashname or row.plate
                local source = string.format("%s:%s", sourceType, identifier)

                duplicateData[series].count = duplicateData[series].count + 1
                table.insert(duplicateData[series].sources, {
                    source = source,
                    slot = slot or item.slot,
                    serial = item.info.series
                })
            end
        end
    end
end

function DuplicateServerItems()
    local playersOnline = false
    for _, playerId in ipairs(GetPlayers()) do
        playersOnline = true
    end

    if playersOnline then
        print("^2 Duplicate check failed because there is a player on the server ^0")
        return
    end

    local webhookUrl = DiscordWebhook.duplicateitems
    local inventoryData = ExecuteSql("SELECT identifier, inventory FROM `codem_new_inventory`")
    local stashData = ExecuteSql("SELECT stashname, inventory FROM `codem_new_stash`")
    local vehicleData = ExecuteSql("SELECT plate, trunk, glovebox FROM `codem_new_vehicleandglovebox`")

    processInventoryData(inventoryData, "Player")
    processInventoryData(stashData, "Stash")

    for _, row in ipairs(vehicleData) do
        local trunk = json.decode(row.trunk or "{}")
        local glovebox = json.decode(row.glovebox or "{}")

        processInventoryData({{plate = row.plate, inventory = json.encode(trunk)}}, "Trunk")
        processInventoryData({{plate = row.plate, inventory = json.encode(glovebox)}}, "Glovebox")
    end

    local fieldsToSend = {}

    for series, data in pairs(duplicateData) do
        if data.count > 1 then
            for _, source in ipairs(data.sources) do
                local parts = {}
                for part in source.source:gmatch("[^:]+") do
                    table.insert(parts, part)
                end

                local identifier = parts[2]
                local inventoryType = nil

                if string.find(source.source, "Trunk") then
                    inventoryType = "Trunk"
                elseif string.find(source.source, "Glovebox") then
                    inventoryType = "Glovebox"
                elseif string.find(source.source, "Stash") then
                    inventoryType = "Stash"
                elseif string.find(source.source, "Player") then
                    inventoryType = "Player"
                end

                if inventoryType == "Trunk" then
                    if VehicleInventory[identifier] and VehicleInventory[identifier].trunk[source.slot] then
                        VehicleInventory[identifier].trunk[source.slot] = nil
                        UpdateVehicleInventory(identifier, VehicleInventory[identifier].trunk)
                        print("^2 DELETE DUPLICATED ITEM FROM TRUNK INVENTORY ^0")
                    end
                elseif inventoryType == "Glovebox" then
                    if GloveBoxInventory[identifier] and GloveBoxInventory[identifier].glovebox[source.slot] then
                        GloveBoxInventory[identifier].glovebox[source.slot] = nil
                        UpdateVehicleGlovebox(identifier, GloveBoxInventory[identifier].glovebox)
                        print("^2 DELETE DUPLICATED ITEM FROM GLOVEBOX INVENTORY ^0")
                    end
                elseif inventoryType == "Stash" then
                    local stashInv = ExecuteSql("SELECT inventory FROM `codem_new_stash` WHERE stashname = @stashname", {
                        ["@stashname"] = identifier
                    })

                    local stashInventory = nil
                    if #stashInv > 0 then
                        stashInventory = json.decode(stashInv[1].inventory or "{}")
                    else
                        stashInventory = {}
                    end

                    if stashInventory[tostring(source.slot)] then
                        stashInventory[tostring(source.slot)] = nil
                        ExecuteSql("UPDATE codem_new_stash SET inventory = @inventory WHERE stashname = @stashname", {
                            ["@stashname"] = identifier,
                            ["@inventory"] = json.encode(stashInventory)
                        })
                    end
                    print("^2 DELETE DUPLICATED ITEM FROM STASH INVENTORY ^0")
                elseif inventoryType == "Player" then
                    local playerInv = ExecuteSql("SELECT inventory FROM `codem_new_inventory` WHERE identifier = @identifier", {
                        ["@identifier"] = identifier
                    })

                    local playerInventory = nil
                    if #playerInv > 0 then
                        playerInventory = json.decode(playerInv[1].inventory or "{}")
                    else
                        playerInventory = {}
                    end

                    if playerInventory[tostring(source.slot)] then
                        playerInventory[tostring(source.slot)] = nil
                        ExecuteSql("UPDATE codem_new_inventory SET inventory = @inventory WHERE identifier = @identifier", {
                            ["@identifier"] = identifier,
                            ["@inventory"] = json.encode(playerInventory)
                        })
                    end
                    print("^2 DELETE DUPLICATED ITEM FROM PLAYER INVENTORY ^0")
                end

                local itemName = data.name
                local serial = source.serial or "unkown"
                local slot = source.slot

                table.insert(fieldsToSend, {
                    name = string.format("**%s** (in %s)", itemName, inventoryType),
                    value = string.format("Serial: `%s`\nName: `%s`\nSlot: `%s`", serial, identifier, slot),
                    inline = true
                })
            end
        end
    end

    local function chunkArray(array, chunkSize)
        local chunks = {}
        for i = 1, #array, chunkSize do
            local chunk = {}
            for j = i, math.min(i + chunkSize - 1, #array) do
                table.insert(chunk, array[j])
            end
            table.insert(chunks, chunk)
        end
        return chunks
    end

    local function sendWebhook(fields)
        PerformHttpRequest(webhookUrl, function(err, text, headers) end, "POST", json.encode({
            username = "Inventory Cleaner",
            embeds = {{
                title = "Deleted Duplicate Items",
                description = "The following duplicate items have been deleted from vehicle inventories:",
                color = 16711680,
                fields = fields
            }}
        }), {["Content-Type"] = "application/json"})
    end

    local chunks = chunkArray(fieldsToSend, 10)

    if #fieldsToSend > 0 then
        for _, chunk in ipairs(chunks) do
            sendWebhook(chunk)
        end
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(15000)
    DuplicateServerItems()
end)

-- ============================================
-- END OF SCRIPT
-- ============================================

RegisterServerEvent("codem-inventory:server:openVehicleTrunk")
AddEventHandler("codem-inventory:server:openVehicleTrunk", function(plate, maxWeight, maxSlots, extraData)
    local playerId = source

    ServerPlayerKey[playerId] = "CODEM" .. math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. "KEY"
    TriggerClientEvent("codem-inventory:client:setkey", playerId, ServerPlayerKey[playerId])

    if not plate then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.VEHICLEPLATENOTFOUND)
        return
    end

    plate = customToLower(plate)
    local correctedPlate = string.lower(string.gsub(plate, "%s+", ""))

    if not VehicleInventory[correctedPlate] then
        VehicleInventory[correctedPlate] = {
            glovebox = {},
            trunk = {},
            plate = correctedPlate,
            maxweight = maxWeight or 0,
            slot = maxSlots or 0
        }
        TriggerClientEvent("codem-inventory:client:newVehiclePlateInsert", -1, correctedPlate, maxWeight, maxSlots)
    end

    local trunkData = {
        trunk = VehicleInventory[correctedPlate].trunk,
        slot = VehicleInventory[correctedPlate].slot,
        maxweight = VehicleInventory[correctedPlate].maxweight,
        plate = correctedPlate
    }

    TriggerClientEvent("codem-inventory:client:openVehicleTrunk", playerId, trunkData)
end)

-- ============================================
-- INVENTORY TO TRUNK
-- ============================================

RegisterServerEvent("codem-inventory:SwapInventoryToVehicleTrunk")
AddEventHandler("codem-inventory:SwapInventoryToVehicleTrunk", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.newSlot = tostring(data.newSlot)
    data.oldSlot = tostring(data.oldSlot)
    local plate = customToLower(data.plate)

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[data.oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if not VehicleInventory[plate] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.VEHICLEPLATENOTFOUND)
        return
    end

    local trunkInventory = VehicleInventory[plate].trunk
    if not trunkInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEVEHICLE)
        return
    end

    local emptySlot = FindFirstEmptySlot(trunkInventory, tonumber(data.maxslot))
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEVEHICLEINVENTORY)
        return
    end

    emptySlot = tostring(emptySlot)
    local amount = inventory[data.oldSlot].amount or 1
    local targetItem = trunkInventory[data.newSlot]

    if not CheckInventoryWeight(trunkInventory, item.weight * item.amount, data.weight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEVEHICLEINVENTORY)
        return
    end

    if targetItem then
        if item.unique or targetItem.unique then
            item.slot = emptySlot
            trunkInventory[emptySlot] = item
            inventory[data.oldSlot] = nil
            TriggerClientEvent("codem-inventory:client:updateVehicleTrunkItem", -1, plate, emptySlot, trunkInventory[emptySlot])
        elseif targetItem.name == item.name then
            targetItem.amount = targetItem.amount + item.amount
            inventory[data.oldSlot] = nil
            TriggerClientEvent("codem-inventory:client:updateVehicleTrunkItem", -1, plate, data.newSlot, trunkInventory[data.newSlot])
        else
            item.slot = emptySlot
            trunkInventory[emptySlot] = item
            inventory[data.oldSlot] = nil
            data.newSlot = emptySlot
        end
    else
        item.slot = data.newSlot
        trunkInventory[data.newSlot] = item
        inventory[data.oldSlot] = nil
    end

    UpdateVehicleInventory(plate, trunkInventory)

    if Config.CashItem and item.name == "cash" then
        local totalCash = GetItemsTotalAmount(playerId, "cash")
        local player = GetPlayer(playerId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    else
        SetInventory(playerId)
    end

    TriggerClientEvent("codem-inventory:client:updateVehicleTrunkItem", -1, plate, data.newSlot, trunkInventory[tostring(data.newSlot)])
    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", playerId, data.oldSlot, amount)

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Plate : " .. plate .. " " .. Locales[Config.Language].notification.INVENTORYTOTRUNK
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMTRUNK, "green", logData, playerId, "trunk")
    end
end)

-- ============================================
-- UPDATE VEHICLE INVENTORY/GLOVEBOX
-- ============================================

function UpdateVehicleInventory(plate, inventory)
    local correctedPlate = string.lower(string.gsub(plate, "%s+", ""))

    local query = [[
        INSERT INTO codem_new_vehicleandglovebox (plate, trunk) VALUES (@plate, @trunk) ON DUPLICATE KEY UPDATE plate = @plate, trunk = @trunk
    ]]

    local params = {
        ["@plate"] = correctedPlate,
        ["@trunk"] = json.encode(inventory)
    }

    local success, err = pcall(function()
        UpdateInventorySql(query, params)
    end)

    if not success then
        print("UpdateVehicleInventory Error: " .. err)
    end
end

function UpdateVehicleGlovebox(plate, inventory)
    local correctedPlate = string.lower(string.gsub(plate, "%s+", ""))

    local query = [[
        INSERT INTO codem_new_vehicleandglovebox (plate, glovebox) VALUES (@plate, @glovebox) ON DUPLICATE KEY UPDATE plate = @plate, glovebox = @glovebox
    ]]

    local params = {
        ["@plate"] = correctedPlate,
        ["@glovebox"] = json.encode(inventory)
    }

    local success, err = pcall(function()
        UpdateInventorySql(query, params)
    end)

    if not success then
        print("UpdateVehicleGlovebox Error: " .. err)
    end
end

-- ============================================
-- TRUNK/GLOVEBOX TO INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:swapVehicleTrunkToInventory")
AddEventHandler("codem-inventory:swapVehicleTrunkToInventory", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.newSlot = tostring(data.newSlot)
    data.oldSlot = tostring(data.oldSlot)
    local plate = tostring(data.plate)

    local trunkInventory = VehicleInventory[plate] and VehicleInventory[plate].trunk
    if not trunkInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEVEHICLE)
        return
    end

    local item = trunkInventory[data.oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if item and item.type == "bag" then
        local bagCount = CheckBagItem(playerId)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.MAXBAGPACKITEM)
            return
        end
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local emptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    if not CheckInventoryWeight(inventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    emptySlot = tostring(emptySlot)
    local targetSlot = inventory[data.newSlot]

    if not targetSlot then
        item.slot = data.newSlot
        inventory[data.newSlot] = item
    else
        if targetSlot.name == item.name and not item.unique and not (inventory[data.oldSlot] and inventory[data.oldSlot].unique) then
            inventory[data.newSlot].amount = inventory[data.newSlot].amount + item.amount
        else
            local newEmptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
            if not newEmptySlot then
                TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.FAILEDANEWSLOT)
                return
            end
            newEmptySlot = tostring(newEmptySlot)
            item.slot = newEmptySlot
            inventory[newEmptySlot] = item
            data.newSlot = newEmptySlot
        end
    end

    if Config.CashItem and item.name == "cash" then
        AddMoney(playerId, "cash", item.amount)
    else
        SetInventory(playerId)
    end

    trunkInventory[data.oldSlot] = nil
    UpdateVehicleInventory(data.plate, trunkInventory)

    TriggerClientEvent("codem-inventory:client:RemoveVehicleTrunkItem", -1, data.plate, data.oldSlot, trunkInventory[tostring(data.oldSlot)])
    TriggerClientEvent("codem-inventory:client:additem", playerId, tostring(data.newSlot), inventory[tostring(data.newSlot)])

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. " - " .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Plate : " .. data.plate .. " " .. Locales[Config.Language].notification.TRUNKTOINVENTORY
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMS, "green", logData, playerId)
    end
end)

RegisterServerEvent("codem-inventory:swapVehicleGloveboxToInventory")
AddEventHandler("codem-inventory:swapVehicleGloveboxToInventory", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.newSlot = tostring(data.newSlot)
    data.oldSlot = tostring(data.oldSlot)
    local plate = tostring(data.plate)

    local gloveboxInventory = GloveBoxInventory[plate] and GloveBoxInventory[plate].glovebox
    if not gloveboxInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.GLOVEBOXINVENTORYNOTFOUND)
        return
    end

    local item = gloveboxInventory[data.oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if item and item.type == "bag" then
        local bagCount = CheckBagItem(playerId)
        if tonumber(bagCount) > tonumber(Config.MaxBackPackItem) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.MAXBAGPACKITEM)
            return
        end
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local emptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    if not CheckInventoryWeight(inventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    emptySlot = tostring(emptySlot)
    local targetSlot = inventory[data.newSlot]

    if not targetSlot then
        item.slot = data.newSlot
        inventory[data.newSlot] = item
    else
        if targetSlot.name == item.name and not item.unique and not (inventory[data.oldSlot] and inventory[data.oldSlot].unique) then
            inventory[data.newSlot].amount = inventory[data.newSlot].amount + item.amount
        else
            local newEmptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
            if not newEmptySlot then
                TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.FAILEDANEWSLOT)
                return
            end
            newEmptySlot = tostring(newEmptySlot)
            item.slot = newEmptySlot
            inventory[newEmptySlot] = item
            data.newSlot = newEmptySlot
        end
    end

    gloveboxInventory[data.oldSlot] = nil

    if Config.CashItem and item.name == "cash" then
        AddMoney(playerId, "cash", item.amount)
    else
        SetInventory(playerId)
    end

    UpdateVehicleGlovebox(data.plate, gloveboxInventory)

    TriggerClientEvent("codem-inventory:client:RemoveVehicleGloveboxItem", -1, data.plate, data.oldSlot, gloveboxInventory[tostring(data.oldSlot)])
    TriggerClientEvent("codem-inventory:client:additem", playerId, tostring(data.newSlot), inventory[tostring(data.newSlot)])

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. " - " .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Plate : " .. data.plate .. " " .. Locales[Config.Language].notification.GLOVEBOXTOINVENTORY
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMS, "green", logData, playerId)
    end
end)

-- ============================================
-- SHOP SYSTEM
-- ============================================

RegisterServerEvent("codem-inventory:swapShopToInventory")
AddEventHandler("codem-inventory:swapShopToInventory", function(data, jobData)
    local playerId = tonumber(source)
    local identifier = Identifier[tonumber(playerId)]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local itemData = data.itemname
    if not itemData then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUND)
        return
    end

    local shop = Config.Shops[data.shopname]
    if not shop then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.SHOPNOTFOUND)
        return
    end

    if #data.amount <= 0 then
        itemData.count = 1
    else
        itemData.count = data.amount
    end

    itemData.count = tonumber(itemData.count)
    itemData.price = tonumber(itemData.price)

    local emptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    local configItem = Config.Itemlist[itemData.name]
    if not configItem then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDITEMLIST)
        return
    end

    -- Check job/grade requirements
    if itemData.grade then
        if jobData and jobData.grade and jobData.name then
            for jobName, _ in pairs(shop.job) do
                if jobData.name == jobName then
                    if tonumber(jobData.grade) >= tonumber(itemData.grade) then
                        if configItem.unique then
                            data.itemname.count = 1
                        end

                        local totalPrice = data.itemname.price * data.itemname.count
                        local playerMoney = GetPlayerMoney(playerId, data.paymentMethod)

                        if tonumber(playerMoney) < tonumber(totalPrice) then
                            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ENOUGHMONEY)
                            return
                        end

                        if AddItem(playerId, configItem.name, data.itemname.count) then
                            RemoveMoney(playerId, data.paymentMethod, totalPrice)
                        end
                    else
                        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOTGRADE)
                        return
                    end
                end
            end
        else
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.JOBNOTFOUND)
            return
        end
    else
        if configItem.unique then
            data.itemname.count = 1
        end

        local totalPrice = data.itemname.price * data.itemname.count
        local playerMoney = GetPlayerMoney(playerId, data.paymentMethod)

        if tonumber(playerMoney) < tonumber(totalPrice) then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ENOUGHMONEY)
            return
        end

        if AddItem(playerId, configItem.name, data.itemname.count) then
            RemoveMoney(playerId, data.paymentMethod, totalPrice)

            if Config.UseDiscordWebhooks then
                local logData = {
                    playername = GetName(playerId) .. "-" .. playerId,
                    itemname = data.itemname.label,
                    info = data.info or nil,
                    amount = data.itemname.count or data.itemname.amount,
                    reason = Locales[Config.Language].notification.SHOPTOINVENTORY
                }
                TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.BUYITEM, "green", logData, playerId, "shop")
            end
        end
    end
end)

-- ============================================
-- BACKPACK SYSTEM
-- ============================================

RegisterServerEvent("codem-inventory:openbackpack")
AddEventHandler("codem-inventory:openbackpack", function(item)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    if not item or not item.info then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMINFONOTFOUND)
        return
    end

    local itemInfo = item.info
    local backpackData = {
        inventory = {},
        slot = itemInfo.slot or 0,
        maxweight = itemInfo.weight or 0,
        backpackname = itemInfo.series
    }

    if ServerStash[itemInfo.series] then
        backpackData.inventory = ServerStash[itemInfo.series].inventory
        if not backpackData.inventory then
            TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.BACKPACKINVNOTFOUND)
            return
        end
    else
        ExecuteSql("INSERT INTO codem_new_stash (stashname, inventory) VALUES (@stashname, @inventory) ON DUPLICATE KEY UPDATE stashname = @stashname, inventory = @inventory", {
            stashname = itemInfo.series,
            inventory = json.encode({})
        })
        ServerStash[itemInfo.series] = {
            inventory = {}
        }
    end

    TriggerClientEvent("codem-inventory:GetBackPackItem", playerId, backpackData)
end)

-- ============================================
-- INVENTORY TO BACKPACK
-- ============================================

RegisterServerEvent("codem-inventory:SwapInventoryToBackPack")
AddEventHandler("codem-inventory:SwapInventoryToBackPack", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.newSlot = tostring(data.newSlot)
    data.oldSlot = tostring(data.oldSlot)

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[data.oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if item.type == "bag" then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.YOUCANNOTPUTABAG)
        return
    end

    if not ServerStash[data.backpackname] then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.BACKPACKNOTFOUND)
        return
    end

    local backpackInventory = ServerStash[data.backpackname].inventory
    local amount = inventory[data.oldSlot].amount or 1

    if not backpackInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.BACKPACKINVNOTFOUND)
        return
    end

    if not CheckInventoryWeight(backpackInventory, item.weight * item.amount, data.weight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.STASHFULL)
        return
    end

    local emptySlot = FindFirstEmptySlot(backpackInventory, data.maxslot)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.FAILEDANEWSLOT)
        return
    end

    emptySlot = tostring(emptySlot)
    local targetSlot = backpackInventory[data.newSlot]

    if not targetSlot then
        item.slot = data.newSlot
        backpackInventory[data.newSlot] = item
    else
        if targetSlot.name == item.name and not item.unique and not targetSlot.unique then
            backpackInventory[data.newSlot].amount = backpackInventory[data.newSlot].amount + item.amount
        else
            item.slot = emptySlot
            backpackInventory[emptySlot] = item
            data.newSlot = emptySlot
        end
    end

    inventory[data.oldSlot] = nil

    ExecuteSql("INSERT INTO codem_new_stash (stashname, inventory) VALUES (@stashname, @inventory) ON DUPLICATE KEY UPDATE stashname = @stashname, inventory = @inventory", {
        stashname = data.backpackname,
        inventory = json.encode(backpackInventory)
    })

    TriggerClientEvent("codem-inventory:client:removeitemtoclientInventory", playerId, data.oldSlot, amount)
    TriggerClientEvent("codem-inventory:client:loadbackpackinventory", playerId, backpackInventory)

    if Config.CashItem and item.name == "cash" then
        local totalCash = GetItemsTotalAmount(playerId, "cash")
        local player = GetPlayer(playerId)
        if Config.Framework == "qb" or Config.Framework == "oldqb" then
            player.Functions.SetMoney("cash", totalCash)
        else
            player.setMoney(tonumber(totalCash))
        end
    else
        SetInventory(playerId)
    end

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Canta Name :" .. data.backpackname .. " " .. Locales[Config.Language].notification.INVENTORYTOBACKPACK
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMS, "green", logData, playerId, "stash")
    end
end)

-- ============================================
-- BACKPACK TO INVENTORY
-- ============================================

RegisterServerEvent("codem-inventory:SwapBackPackToInventory")
AddEventHandler("codem-inventory:SwapBackPackToInventory", function(data)
    local playerId = source
    local identifier = Identifier[playerId]

    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    data.newSlot = tostring(data.newSlot)
    local oldSlot = tostring(data.itemname.slot)
    local backpackName = data.backpackname

    local backpackInventory = ServerStash[backpackName].inventory
    if not backpackInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.BACKPACKINVNOTFOUND)
        return
    end

    local item = backpackInventory[oldSlot]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    if not CheckInventoryWeight(inventory, item.weight * item.amount, Config.MaxWeight) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVENTORYISFULL)
        return
    end

    local emptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    emptySlot = tostring(emptySlot)
    local targetSlot = inventory[data.newSlot]

    if not targetSlot then
        item.slot = data.newSlot
        inventory[data.newSlot] = item
    else
        if targetSlot.name == item.name and not item.unique and not (inventory[data.oldSlot] and inventory[data.oldSlot].unique) then
            inventory[data.newSlot].amount = inventory[data.newSlot].amount + item.amount
        else
            item.slot = emptySlot
            inventory[emptySlot] = item
            data.newSlot = emptySlot
        end
    end

    backpackInventory[oldSlot] = nil

    ExecuteSql("INSERT INTO codem_new_stash (stashname, inventory) VALUES (@stashname, @inventory) ON DUPLICATE KEY UPDATE stashname = @stashname, inventory = @inventory", {
        stashname = backpackName,
        inventory = json.encode(backpackInventory)
    })

    TriggerClientEvent("codem-inventory:client:additem", playerId, tostring(data.newSlot), inventory[tostring(data.newSlot)])
    TriggerClientEvent("codem-inventory:client:loadbackpackinventory", playerId, backpackInventory)

    if Config.CashItem and item.name == "cash" then
        AddMoney(playerId, "cash", item.amount)
    else
        SetInventory(playerId)
    end

    if Config.UseDiscordWebhooks then
        local logData = {
            playername = GetName(playerId) .. "-" .. playerId,
            itemname = item.label,
            amount = item.amount,
            info = item.info or nil,
            reason = "Canta Name :" .. data.backpackname .. " " .. Locales[Config.Language].notification.BACKPACKTOINVENTORY
        }
        TriggerEvent("codem-inventory:CreateLog", Locales[Config.Language].notification.ADDITEMS, "green", logData, playerId, "stash")
    end
end)

-- ============================================
-- SPLIT ITEM FUNCTIONS
-- ============================================

RegisterServerEvent("codem-inventory:server:splitItemTrunk")
AddEventHandler("codem-inventory:server:splitItemTrunk", function(data)
    local playerId = tonumber(source)

    if cooldown[playerId] then
        return
    else
        cooldown[playerId] = true
        SetTimeout(400, function()
            cooldown[playerId] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local trunkInventory = VehicleInventory[data.plate] and VehicleInventory[data.plate].trunk
    if not trunkInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.VEHICLEPLATENOTFOUND)
        return
    end

    local item = trunkInventory[tostring(data.item.slot)]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if tonumber(item.amount) <= 1 then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.CANNOTSPLIT)
        return
    end

    local emptySlot = FindFirstEmptySlot(trunkInventory, data.maxslot)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    emptySlot = tostring(emptySlot)
    local splitAmount = tonumber(data.amount)

    if splitAmount < 1 or splitAmount >= tonumber(item.amount) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVALODAMOUNTSPLIT)
        return
    end

    local newItem = {
        name = item.name,
        label = item.label or item.name,
        weight = item.weight or 0,
        type = item.type or "item",
        amount = splitAmount,
        usable = item.usable or false,
        shouldClose = item.shouldClose or false,
        description = item.description or "",
        slot = emptySlot,
        image = item.image or (item.name .. ".png"),
        unique = item.unique or false,
        info = item.info or nil
    }

    trunkInventory[emptySlot] = newItem
    trunkInventory[tostring(data.item.slot)].amount = tonumber(item.amount) - tonumber(splitAmount)

    UpdateVehicleInventory(data.plate, trunkInventory)
    TriggerClientEvent("codem-inventory:splitItemTrunkClient", -1, data.plate, data.item.slot, trunkInventory[tostring(data.item.slot)].amount, emptySlot, newItem)
end)

RegisterNetEvent("codem-inventory:server:splitItemGloveBox")
AddEventHandler("codem-inventory:server:splitItemGloveBox", function(data)
    local playerId = tonumber(source)

    if cooldown[playerId] then
        return
    else
        cooldown[playerId] = true
        SetTimeout(400, function()
            cooldown[playerId] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local gloveboxInventory = GloveBoxInventory[data.plate] and GloveBoxInventory[data.plate].glovebox
    if not gloveboxInventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.GLOVEBOXINVENTORYNOTFOUND)
        return
    end

    local item = gloveboxInventory[tostring(data.item.slot)]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if tonumber(item.amount) <= 1 then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.CANNOTSPLIT)
        return
    end

    local emptySlot = FindFirstEmptySlot(gloveboxInventory, data.maxslot)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    emptySlot = tostring(emptySlot)
    local splitAmount = tonumber(data.amount)

    if splitAmount < 1 or splitAmount >= tonumber(item.amount) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVALODAMOUNTSPLIT)
        return
    end

    local newItem = {
        name = item.name,
        label = item.label or item.name,
        weight = item.weight or 0,
        type = item.type or "item",
        amount = splitAmount,
        usable = item.usable or false,
        shouldClose = item.shouldClose or false,
        description = item.description or "",
        slot = emptySlot,
        image = item.image or (item.name .. ".png"),
        unique = item.unique or false,
        info = item.info or nil
    }

    gloveboxInventory[emptySlot] = newItem
    gloveboxInventory[tostring(data.item.slot)].amount = tonumber(item.amount) - tonumber(splitAmount)

    UpdateVehicleGlovebox(data.plate, gloveboxInventory)
    TriggerClientEvent("codem-inventory:splitItemGloveboxClient", -1, data.plate, data.item.slot, gloveboxInventory[tostring(data.item.slot)].amount, emptySlot, newItem)
end)

RegisterServerEvent("codem-inventory:server:splitItemStash")
AddEventHandler("codem-inventory:server:splitItemStash", function(data)
    local playerId = tonumber(source)

    if cooldown[playerId] then
        return
    else
        cooldown[playerId] = true
        SetTimeout(400, function()
            cooldown[playerId] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local stashInventory = ServerStash[data.stashId] and ServerStash[data.stashId].inventory
    if not stashInventory then
        return
    end

    local item = stashInventory[tostring(data.item.slot)]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if item.amount <= 1 then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.CANNOTSPLIT)
        return
    end

    local emptySlot = FindFirstEmptySlot(stashInventory, data.maxslot)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    emptySlot = tostring(emptySlot)
    local splitAmount = tonumber(data.amount)

    if splitAmount < 1 or splitAmount >= item.amount then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVALODAMOUNTSPLIT)
        return
    end

    local newItem = {
        name = item.name,
        label = item.label or item.name,
        weight = item.weight or 0,
        type = item.type or "item",
        amount = splitAmount,
        usable = item.usable or false,
        shouldClose = item.shouldClose or false,
        description = item.description or "",
        slot = emptySlot,
        image = item.image or (item.name .. ".png"),
        unique = item.unique or false,
        info = item.info or nil
    }

    stashInventory[emptySlot] = newItem
    stashInventory[tostring(data.item.slot)].amount = tonumber(item.amount) - tonumber(splitAmount)

    UpdateStashDatabase(data.stashId, stashInventory)
    TriggerClientEvent("codem-inventory:UpdateStashItems", playerId, data.stashId, stashInventory)
end)

RegisterServerEvent("codem-inventory:server:splitItem")
AddEventHandler("codem-inventory:server:splitItem", function(data)
    local playerId = tonumber(source)

    if cooldown[playerId] then
        return
    else
        cooldown[playerId] = true
        SetTimeout(400, function()
            cooldown[playerId] = nil
        end)
    end

    local identifier = Identifier[playerId]
    if not identifier then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.IDENTIFIERNOTFOUND)
        return
    end

    local inventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not inventory then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.PLAYERINVENTORYNOTFOUND)
        return
    end

    local item = inventory[tostring(data.item.slot)]
    if not item then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.ITEMNOTFOUNDINGIVENSLOT)
        return
    end

    if tonumber(item.amount) <= 1 then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.CANNOTSPLIT)
        return
    end

    local emptySlot = FindFirstEmptySlot(inventory, Config.MaxSlots)
    if not emptySlot then
        TriggerClientEvent("codem-inventory:client:notification ", playerId, Locales[Config.Language].notification.NOEMPTYSLOTAVILABLEYOUR)
        return
    end

    emptySlot = tostring(emptySlot)
    local splitAmount = tonumber(data.amount)

    if splitAmount < 1 or splitAmount >= tonumber(item.amount) then
        TriggerClientEvent("codem-inventory:client:notification", playerId, Locales[Config.Language].notification.INVALODAMOUNTSPLIT)
        return
    end

    local newItem = {
        name = item.name,
        label = item.label or item.name,
        weight = item.weight or 0,
        type = item.type or "item",
        amount = splitAmount,
        usable = item.usable or false,
        shouldClose = item.shouldClose or false,
        description = item.description or "",
        slot = tonumber(emptySlot),
        image = item.image or (item.name .. ".png"),
        unique = item.unique or false,
        info = item.info or nil
    }

    inventory[emptySlot] = newItem
    inventory[tostring(data.item.slot)].amount = tonumber(item.amount) - splitAmount

    TriggerClientEvent("codem-inventory:client:splitItem", playerId, emptySlot, inventory[emptySlot], data.item.slot, inventory[tostring(data.item.slot)])
    SetInventory(playerId)
end)

-- ============================================
-- END OF SCRIPT
-- ============================================

print("^2========================================^0")
print("^2    CODEM INVENTORY SYSTEM LOADED     ^0")
print("^2========================================^0")
