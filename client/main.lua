-- Codem Inventory System - Main Client File
-- Variables
Core = nil
nuiLoaded = false
ClientInventory = {}
ClientGround = {}
VehicleInventory = {}
VehicleGlovebox = {}
OpenInventory = false
currentDrop = nil
currentVehiclePlate = nil
givecount = nil
curvehicle = nil
InGlovebox = nil
openTrunkVehicle = false
robstatus = false
PedScreen = true
ClothingInventory = {}
HotbarItems = {}
AccessInv = false

-- NUI Callbacks
RegisterNUICallback("onlinecheck", function()
    AccessInv = true
end)

RegisterNUICallback("offlinecheck", function()
    SetNuiFocus(false, false)
    TriggerEvent("codem-inventory:client:closeInventory")
    AccessInv = false
end)

-- NUI Message Handler
function NuiMessage(action, payload)
    while not nuiLoaded do
        Wait(0)
    end
    SendNUIMessage({
        action = action,
        payload = payload
    })
end

RegisterNUICallback("LoadedNUI", function(data, cb)
    nuiLoaded = true
    cb("ok")
end)

-- Initialize Core and NUI
CreateThread(function()
    while Core == nil do
        Wait(0)
    end

    while not nuiLoaded do
        if NetworkIsSessionStarted() then
            SendNUIMessage({
                action = "CHECK_NUI"
            })
        end
        Wait(2000)
    end
end)

-- Ped Screen Controls
RegisterNUICallback("DisablePedScreen", function(data, cb)
    PedScreen = false
    Remove2d()
    cb("ok")
end)

RegisterNUICallback("EnablePedScreen", function(data, cb)
    PedScreen = true
    if OpenInventory then
        CreatePedScreen(true)
    end
    cb("ok")
end)

-- Clothing System
RegisterNetEvent("codem-inventory:loadclothingdata", function(data)
    ClothingInventory = data
end)

-- Key System
RegisterNetEvent("codem-inventory:client:setkey", function(key)
    givecount = key
end)

-- Load Client Inventory
RegisterNetEvent("codem-inventory:client:loadClientInventory", function(inventory)
    ClientInventory = inventory or {}
end)

-- Clear Inventory on Death
RegisterNetEvent("codem-inventory:client:clearinventory", function()
    local tempInventory = {}

    for slot, item in pairs(ClientInventory) do
        if Config.NotDeleteItemWhenPlayerDie[item.name] then
            tempInventory[slot] = item
        end
    end

    ClientInventory = tempInventory
    TriggerEvent("codem-inventory:client:RemoveWeaponObject")
    NuiMessage("UPDATE_INVENTORY", ClientInventory)
end)

-- Send Config to NUI
CreateThread(function()
    while Core == nil and not nuiLoaded do
        Wait(0)
    end

    NuiMessage("CONFIG_SETTINGS", {
        playerweight = Config.MaxWeight,
        maxslot = Config.MaxSlots,
        groundslot = Config.GroundSlots,
        configclothing = Config.ItemClothingSystem,
        cashitem = Config.CashItem,
        serverlogo = Config.ServerLogo,
        context = Config.ContextMenuData,
        adjust = Config.AdjustmentsData,
        category = Config.Category,
        configcraft = Config.CraftSystem,
        configcraftitem = Config.CraftItems
    })

    NuiMessage("SET_LOCALES", Locales[Config.Language].frontend)
end)

-- Hotbar System
function ToggleHotbar(open)
    local items = {}
    for i = 1, 5 do
        items[i] = ClientInventory[tostring(i)] or {}
    end
    HotbarItems = items

    NuiMessage("TOGGLE_HOTBAR", {
        open = open,
        items = HotbarItems
    })
end

-- Sort Items
RegisterNUICallback("SortItem", function()
    TriggerServerEvent("codem-inventory:server:sortItems")
end)

RegisterNUICallback("SortItemStash", function(data, cb)
    TriggerServerEvent("codem-inventory:server:sortItemsStash", data)
    cb("ok")
end)

RegisterNetEvent("codem-inventory:client:sortItems", function(inventory)
    if inventory then
        ClientInventory = inventory
        if OpenInventory then
            NuiMessage("UPDATE_INVENTORY", ClientInventory)
        end
    end
end)

-- Ground Items
RegisterNetEvent("codem-inventory:client:loadAllGround", function(ground)
    ClientGround = ground
end)

-- Vehicle Inventory
RegisterNetEvent("codem-inventory:client:loadAllVehicleInventory", function(vehicles)
    VehicleInventory = vehicles
end)

RegisterNetEvent("codem-inventory:client:loadAllVehicleGlovebox", function(gloveboxes)
    VehicleGlovebox = gloveboxes
end)

-- Clothing Swap Functions
RegisterNUICallback("swapClothingToMainInventory", function(data)
    if data then
        local model = GetEntityModel(PlayerPedId())
        local gender = (model == 1885233650) and "man" or "woman"
        TriggerServerEvent("codem-inventory:server:swaprClothingToMainInventory", data, gender)
    end
end)

RegisterNUICallback("swapMainInventoryToClothingInventory", function(data)
    if data then
        TriggerServerEvent("codem-inventory:server:swapInventoryToClothing", data)
    end
end)

-- Inventory Swap Functions
RegisterNUICallback("SwapMainInventory", function(data, cb)
    TriggerServerEvent("codem-inventory:server:checkPlayerItemForSwap", data)
    cb("ok")
end)

RegisterNUICallback("SwapMainInventoryTargetItem", function(data, cb)
    TriggerServerEvent("codem-inventory:server:checkPlayerItemForSwapTargetItem", data)
    cb("ok")
end)

RegisterNUICallback("swapMainInventoryToGround", function(data, cb)
    TriggerServerEvent("codem-inventory:SwapInventoryToGround", data, currentDrop)
    cb("ok")
end)

RegisterNUICallback("swapMainInventoryToStash", function(data, cb)
    TriggerServerEvent("codem-inventory:SwapInventoryToStash", data)
    cb("ok")
end)

RegisterNUICallback("swapMainStashToStash", function(data, cb)
    TriggerServerEvent("codem-inventory:swapStashToStash", data)
    cb("ok")
end)

RegisterNUICallback("swapStashToMainInventory", function(data, cb)
    TriggerServerEvent("codem-inventory:swapStashToInventory", data)
    cb("ok")
end)

-- Vehicle Trunk/Glovebox Functions
RegisterNUICallback("swapMainInventoryToVehicleTrunk", function(data, cb)
    TriggerServerEvent("codem-inventory:SwapInventoryToVehicleTrunk", data, givecount)
    cb("ok")
end)

RegisterNUICallback("swapMainInventoryToVehicleGlovebox", function(data, cb)
    TriggerServerEvent("codem-inventory:SwapInventoryToVehicleGlovebox", data, givecount)
    cb("ok")
end)

RegisterNUICallback("swapVehicleTrunkToMainInventory", function(data, cb)
    TriggerServerEvent("codem-inventory:swapVehicleTrunkToInventory", data)
    cb("ok")
end)

RegisterNUICallback("swapVehicleGloveboxToMainInventory", function(data, cb)
    TriggerServerEvent("codem-inventory:swapVehicleGloveboxToInventory", data)
    cb("ok")
end)

-- Shop System
RegisterNUICallback("swapShopToMainInventory", function(data, cb)
    TriggerServerEvent("codem-inventory:swapShopToInventory", data, jobData)
    cb("ok")
end)

-- Backpack System
RegisterNUICallback("swapMainInventoryToBackpack", function(data, cb)
    TriggerServerEvent("codem-inventory:SwapInventoryToBackPack", data)
    cb("ok")
end)

-- Split Item Functions
RegisterNUICallback("SplitItem", function(data, cb)
    TriggerServerEvent("codem-inventory:server:splitItem", data)
    cb("ok")
end)

RegisterNUICallback("SplitItemStash", function(data, cb)
    TriggerServerEvent("codem-inventory:server:splitItemStash", data)
    cb("ok")
end)

RegisterNUICallback("SplitItemGloveBox", function(data, cb)
    TriggerServerEvent("codem-inventory:server:splitItemGloveBox", data)
    cb("ok")
end)

RegisterNUICallback("SplitItemTrunk", function(data, cb)
    TriggerServerEvent("codem-inventory:server:splitItemTrunk", data)
    cb("ok")
end)

-- Rob Player Functions
RegisterNUICallback("swapRobPlayerToMainInventory", function(data, cb)
    TriggerServerEvent("codem-inventory:server:swaprobplayertomaininventory", data)
    cb("ok")
end)

RegisterNUICallback("swapMainInventoryToRobPlayer", function(data, cb)
    TriggerServerEvent("codem-inventory:server:swapmaininventorytorobplayer", data)
    cb("ok")
end)

RegisterNetEvent("codem-inventory:refreshrobplayerinventory", function(inventory)
    NuiMessage("UPDATE_ROB_PLAYER_INVENTORY", inventory)
end)

RegisterNUICallback("ChangePlayerRobStatus", function(data, cb)
    TriggerServerEvent("codem-inventory:server:ChangePlayerRobStatus", data)
    cb("ok")
end)

-- Clothing Updates
RegisterNetEvent("codem-inventory:updateClothingInventory", function(clothing)
    ClothingInventory = clothing
    NuiMessage("UPDATE_CLOTHING_INVENTORY", clothing)
end)

RegisterNetEvent("codem-inventory:loadClothingInventory", function()
    NuiMessage("UPDATE_CLOTHING_INVENTORY", ClothingInventory)
end)

RegisterNUICallback("TakeOffClothes", function(data, cb)
    local model = GetEntityModel(PlayerPedId())
    local gender = (model == 1885233650) and "man" or "woman"
    TriggerServerEvent("codem-inventory:server:TakeOffClothes", data, gender)
    cb("ok")
end)

-- Split Item Client Updates
RegisterNetEvent("codem-inventory:splitItemGloveboxClient", function(plate, slot1, amount, slot2, item)
    slot1 = tostring(slot1)
    slot2 = tostring(slot2)

    if VehicleGlovebox[plate] then
        VehicleGlovebox[plate].glovebox[slot1].amount = tonumber(amount)
        VehicleGlovebox[plate].glovebox[slot2] = item
        VehicleGlovebox[plate].glovebox[slot2].slot = slot2

        if InGlovebox == plate and OpenInventory then
            NuiMessage("UPDATE_GLOVEBOX_INVENTORY", VehicleGlovebox[plate])
        end
    end
end)

RegisterNetEvent("codem-inventory:splitItemTrunkClient", function(plate, slot1, amount, slot2, item)
    slot1 = tostring(slot1)
    slot2 = tostring(slot2)

    if VehicleInventory[plate] then
        VehicleInventory[plate].trunk[slot1].amount = tonumber(amount)
        VehicleInventory[plate].trunk[slot2] = item
        VehicleInventory[plate].trunk[slot2].slot = slot2

        if currentVehiclePlate == plate and OpenInventory then
            NuiMessage("UPDATE_VEHICLE_INVENTORY", VehicleInventory[plate])
        end
    end
end)

-- Item Management
RegisterNetEvent("codem-inventory:refreshiteminfo", function(slot, info)
    slot = tostring(slot)

    if ClientInventory[slot] then
        ClientInventory[slot].info = info
        if OpenInventory then
            NuiMessage("UPDATE_INVENTORY", ClientInventory)
        end
    end
end)

RegisterNetEvent("codem-inventory:client:setitemamount", function(slot, amount)
    slot = tostring(slot)
    amount = tonumber(amount)

    if ClientInventory[slot] then
        ClientInventory[slot].amount = amount
        if OpenInventory then
            NuiMessage("UPDATE_INVENTORY", ClientInventory)
        end
    end
end)

RegisterNetEvent("codem-inventory:refreshItemsDurability", function(slot, itemData)
    slot = tostring(slot)

    if ClientInventory[slot] and itemData.name == ClientInventory[slot].name then
        ClientInventory[slot].info = itemData.info
        if OpenInventory then
            NuiMessage("UPDATE_INVENTORY", ClientInventory)
        end
    end
end)

-- Get Closest Players
RegisterNUICallback("GetClosestPlayers", function(data, cb)
    local players = GetClosestPlayers()
    local result = TriggerCallback("codem-inventory:GetClosestPlayers", players)
    cb(result)
end)

-- Split Item Update
RegisterNetEvent("codem-inventory:client:splitItem", function(slot1, item1, slot2, item2)
    slot1 = tostring(slot1)
    slot2 = tostring(slot2)

    if ClientInventory[slot2] then
        ClientInventory[slot1] = item1
        ClientInventory[slot2] = item2
        NuiMessage("UPDATE_INVENTORY", ClientInventory)
    end
end)

-- Give Item to Player
RegisterNUICallback("GiveItemToPlayer", function(data, cb)
    TriggerServerEvent("codem-inventory:server:giveItemToPlayerNearby", data)
    cb("ok")
end)

-- Set Item Metadata
RegisterNetEvent("codem-inventory:client:setitemmetadata", function(slot, metadata)
    slot = tostring(slot)

    if ClientInventory[slot] and ClientInventory[slot].info then
        ClientInventory[slot].info = metadata
        if OpenInventory then
            NuiMessage("UPDATE_INVENTORY", ClientInventory)
        end
    end
end)

-- Vehicle Trunk/Glovebox Open
RegisterNetEvent("codem-inventory:client:openVehicleTrunk", function(data)
    NuiMessage("LOAD_VEHICLE_INVENTORY", data)
end)

RegisterNetEvent("codem-inventory:client:openVehicleGlovebox", function(data)
    NuiMessage("LOAD_VEHICLE_GLOVEBOX", data)
end)

-- Ground to Inventory
RegisterNuiCallback("swapGroundToMainInventory", function(data, cb)
    if not currentDrop then
        return
    end
    TriggerServerEvent("codem-inventory:SwapGroundToInventory", data, currentDrop)
    cb("ok")
end)

-- Weapon Attachments
RegisterNUICallback("removeAttachment", function(data, cb)
    TriggerServerEvent("weapons:server:RemoveAttachment", data)
    cb("ok")
end)

-- Backpack to Inventory
RegisterNUICallback("swapBackpackToIventory", function(data, cb)
    TriggerServerEvent("codem-inventory:SwapBackPackToInventory", data)
    cb("ok")
end)

-- Remove Item from Inventory
RegisterNetEvent("codem-inventory:client:removeitemtoclientInventory", function(slot, amount)
    slot = tostring(slot)

    if ClientInventory[slot] then
        ClientInventory[slot].amount = tonumber(ClientInventory[slot].amount)
        amount = tonumber(amount)

        if amount >= ClientInventory[slot].amount then
            -- Remove weapon if equipped
            if currentWeapon == ClientInventory[slot].name then
                TriggerEvent("codem-inventory:client:RemoveWeaponObject")
                currentWeapon = nil
            end

            -- Remove backpack UI if needed
            if ClientInventory[slot].type == "bag" then
                NuiMessage("REMOVE_BACKPACK")
            end

            -- Show notification
            if ClientInventory[slot].name ~= "cash" then
                NuiMessage("SHOW_BOTTOM_MENU", {
                    value = "itemremoved",
                    image = ClientInventory[slot].image,
                    amount = amount,
                    text = Locales[Config.Language].notification.ITEMREMOVED
                })
            end

            ClientInventory[slot] = nil
        else
            ClientInventory[slot].amount = ClientInventory[slot].amount - amount

            if ClientInventory[slot].name ~= "cash" then
                NuiMessage("SHOW_BOTTOM_MENU", {
                    value = "itemremoved",
                    image = ClientInventory[slot].image,
                    amount = amount,
                    text = Locales[Config.Language].notification.ITEMREMOVED
                })
            end
        end

        NuiMessage("UPDATE_INVENTORY", ClientInventory)
    else
        TriggerEvent("codem-inventory:client:notification",
            Locales[Config.Language].notification.ITEMNOTFOUND)
    end
end)

-- Set Item by Slot
RegisterNetEvent("codem-inventory:client:setitembyslot", function(slot, item)
    slot = tostring(slot)

    if ClientInventory[slot] then
        ClientInventory[slot] = item
        if ClientWeaponData and ClientWeaponData.slot == slot then
            ClientWeaponData = item
        end
    end
end)

-- Swap Item Position
RegisterNetEvent("codem-inventory:client:ChangeSwapItem", function(fromSlot, toSlot)
    fromSlot = tostring(fromSlot)
    toSlot = tostring(toSlot)

    if ClientInventory[fromSlot] then
        -- Remove weapon if equipped
        if ClientWeaponData and ClientWeaponData.name == ClientInventory[fromSlot].name then
            TriggerEvent("codem-inventory:client:RemoveWeaponObject")
            ClientWeaponData = nil
            currentWeapon = nil
        end

        ClientInventory[toSlot] = ClientInventory[fromSlot]
        ClientInventory[toSlot].slot = toSlot
        ClientInventory[fromSlot] = nil

        NuiMessage("UPDATE_INVENTORY", ClientInventory)
    end
end)

-- Swap Items Between Slots
RegisterNetEvent("codem-inventory:client:ChangeSwapItemTargetItem", function(slot1, slot2)
    slot1 = tostring(slot1)
    slot2 = tostring(slot2)

    local item1 = ClientInventory[slot1]
    local item2 = ClientInventory[slot2]

    if item1 and item2 then
        -- Remove weapons if equipped
        if ClientWeaponData then
            if ClientWeaponData.name == item1.name or ClientWeaponData.name == item2.name then
                TriggerEvent("codem-inventory:client:RemoveWeaponObject")
                ClientWeaponData = nil
                currentWeapon = nil
            end
        end

        ClientInventory[slot1] = item2
        ClientInventory[slot1].slot = slot1
        ClientInventory[slot2] = item1
        ClientInventory[slot2].slot = slot2

        NuiMessage("UPDATE_INVENTORY", ClientInventory)
    end
end)

-- Merge Similar Items
RegisterNetEvent("codem-inventory:client:ChangeSwapItemSimilarItem", function(slot1, slot2)
    slot1 = tostring(slot1)
    slot2 = tostring(slot2)

    local item1 = ClientInventory[slot1]
    local item2 = ClientInventory[slot2]

    if item1 and item2 then
        ClientInventory[slot2].amount = ClientInventory[slot2].amount + item1.amount
        ClientInventory[slot1] = nil
        NuiMessage("UPDATE_INVENTORY", ClientInventory)
    end
end)

-- Vehicle Plate Management
RegisterNetEvent("codem-inventory:client:newVehiclePlateInsert", function(plate, maxweight, slots)
    if not VehicleInventory[plate] then
        VehicleInventory[plate] = {
            glovebox = {},
            plate = plate,
            trunk = {},
            maxweight = maxweight,
            slot = slots
        }
    else
        VehicleInventory[plate] = {
            glovebox = {},
            plate = plate,
            trunk = {},
            maxweight = maxweight,
            slot = slots
        }
    end
end)

RegisterNetEvent("codem-inventory:client:newVehicleGloveboxPlateInsert", function(plate, maxweight, slots)
    if not VehicleGlovebox[plate] then
        VehicleGlovebox[plate] = {
            glovebox = {},
            plate = plate,
            trunk = {},
            maxweight = maxweight,
            slot = slots
        }
    else
        VehicleGlovebox[plate] = {
            glovebox = {},
            plate = plate,
            trunk = {},
            maxweight = maxweight,
            slot = slots
        }
    end
end)

-- Update Vehicle Items
RegisterNetEvent("codem-inventory:client:updateVehiclePlate", function(plate, slot, item)
    slot = tostring(slot)

    if VehicleGlovebox[plate] then
        VehicleGlovebox[plate].glovebox[slot] = item

        if InGlovebox == plate and OpenInventory then
            NuiMessage("UPDATE_GLOVEBOX_INVENTORY", VehicleGlovebox[plate])
        end
    end
end)

RegisterNetEvent("codem-inventory:client:updateVehicleTrunkItem", function(plate, slot, item)
    slot = tostring(slot)

    if VehicleInventory[plate] then
        VehicleInventory[plate].trunk[slot] = item

        if currentVehiclePlate == plate and OpenInventory then
            NuiMessage("UPDATE_VEHICLE_INVENTORY", VehicleInventory[plate])
        end
    end
end)

RegisterNetEvent("codem-inventory:client:updateVehicleGloveBoxItem", function(plate, slot, item)
    slot = tostring(slot)

    if VehicleGlovebox[plate] then
        VehicleGlovebox[plate].glovebox[slot] = item
        InGlovebox = customToLower2(InGlovebox)

        if InGlovebox == plate and OpenInventory then
            NuiMessage("UPDATE_GLOVEBOX_INVENTORY", VehicleGlovebox[plate])
        end
    end
end)

-- Remove Vehicle Items
RegisterNetEvent("codem-inventory:client:RemoveVehicleTrunkItem", function(plate, slot, amount)
    slot = tostring(slot)

    if VehicleInventory[plate] and VehicleInventory[plate].trunk[slot] then
        VehicleInventory[plate].trunk[slot] = nil

        if currentVehiclePlate == plate and OpenInventory then
            NuiMessage("UPDATE_VEHICLE_INVENTORY", VehicleInventory[plate])
        end
    end
end)

RegisterNetEvent("codem-inventory:client:RemoveVehicleGloveboxItem", function(plate, slot, amount)
    slot = tostring(slot)

    if VehicleGlovebox[plate] and VehicleGlovebox[plate].glovebox[slot] then
        VehicleGlovebox[plate].glovebox[slot] = nil
        InGlovebox = customToLower2(InGlovebox)

        if InGlovebox == plate and OpenInventory then
            NuiMessage("UPDATE_GLOVEBOX_INVENTORY", VehicleGlovebox[plate])
        end
    end
end)

-- Helper Function for Turkish Character Handling
function customToLower2(str)
    if str == nil then
        return
    end
    str = str:gsub("İ", "i")
    str = str:gsub("I", "i")
    return str:lower()
end

-- Update Item Amount
RegisterNetEvent("codem-inventory:updateitemamount", function(slot, newAmount, addedAmount)
    slot = tostring(slot)

    if ClientInventory[slot] then
        ClientInventory[slot].amount = newAmount

        NuiMessage("SHOW_BOTTOM_MENU", {
            value = "itemadded",
            image = ClientInventory[slot].image,
            amount = addedAmount,
            text = Locales[Config.Language].notification.ITEMADDED
        })

        if OpenInventory then
            NuiMessage("UPDATE_INVENTORY", ClientInventory)
        end
    end
end)

-- Add Item
RegisterNetEvent("codem-inventory:client:additem", function(slot, item)
    slot = tostring(slot)

    ClientInventory[slot] = item
    NuiMessage("UPDATE_INVENTORY", ClientInventory)
    NuiMessage("SHOW_BOTTOM_MENU", {
        value = "itemadded",
        image = ClientInventory[slot].image,
        amount = ClientInventory[slot].amount,
        text = Locales[Config.Language].notification.ITEMADDED
    })
end)

-- Open Stash
RegisterNetEvent("codem-inventory:client:openstash", function(inventory, slots, maxweight, label)
    NuiMessage("LOAD_INVENTORY", ClientInventory)
    SetNuiFocus(true, true)
    OpenInventory = true

    if PedScreen then
        CreatePedScreen()
    end

    NuiMessage("OPEN_STASH", {
        inventory = inventory,
        slot = slots,
        maxweight = maxweight,
        label = label
    })
end)

-- Open Player Inventory
RegisterNetEvent("codem-inventory:client:OpenPlayerInventory", function(inventory, playerId, playerName)
    NuiMessage("LOAD_INVENTORY", ClientInventory)
    SetNuiFocus(true, true)
    OpenInventory = true

    if PedScreen then
        CreatePedScreen()
    end

    NuiMessage("OPEN_PLAYER_INVENTORY", {
        inventory = inventory,
        playerid = playerId,
        playername = playerName
    })
end)

RegisterNetEvent("codem-inventory:client:openplayerinventory", function(targetId)
    TriggerServerEvent("codem-inventory:server:openplayerinventory", targetId)
end)

-- Weapon Tint
RegisterNUICallback("tintItem", function(data, cb)
    TriggerServerEvent("codem-inventory:server:removeTint", data)
    cb("ok")
end)

-- Update Stash
RegisterNetEvent("codem-inventory:UpdateStashItems", function(stashId, inventory)
    if OpenInventory then
        NuiMessage("UPDATE_STASH", {
            stashid = stashId,
            inventory = inventory
        })
    end
end)

-- Notifications
RegisterNetEvent("codem-inventory:client:notification", function(message)
    if OpenInventory then
        NuiMessage("NOTIFICATION", message)
    else
        Config.Notification(message, "error", false)
    end
end)

RegisterNUICallback("craftnotification", function(message)
    if OpenInventory then
        NuiMessage("NOTIFICATION", message)
    else
        Config.Notification(message, "error", false)
    end
end)

-- Backpack System
RegisterNetEvent("codem-inventory:useBackpackItem", function(item)
    TriggerServerEvent("codem-inventory:openbackpack", item)
end)

RegisterNetEvent("codem-inventory:GetBackPackItem", function(backpack)
    NuiMessage("OPEN_BACKPACK", backpack)
end)

RegisterNetEvent("codem-inventory:client:loadbackpackinventory", function(inventory)
    if inventory then
        NuiMessage("LOAD_BACKPACK", inventory)
    end
end)

-- Crafting System
RegisterNUICallback("CraftItem", function(data, cb)
    local result = TriggerCallback("codem-inventory:CraftItem", data)
    cb(result)
end)

RegisterNUICallback("FinishCraftItem", function(data, cb)
    TriggerServerEvent("codem-inventory:server:FinishCraftItem", data)
end)
