if not Config.ItemClothingSystem then
    return false
end

local inventoryClotingTableMale = {
    ["pants_1"] = 14,
    ['tshirt_1'] = 15,
    ['torso_1'] = 91,
    ['shoes_1'] = 34,
    ['bproof_1'] = 0,
    ['glasses_1'] = 0,
    ['helmet_1'] = -1,
    ['mask_1'] = 0,
    ['watches_1'] = -1,
    ['bags_1'] = 0,
    ['arms'] = 0,
    ['chain_1'] = 0,
    ['bracelets_1'] = -1,
}

local inventoryClotingTableFemale = {
    ["pants_1"] = 14,
    ['tshirt_1'] = 15,
    ['torso_1'] = 91,
    ['shoes_1'] = 5,
    ['bproof_1'] = 0,
    ['glasses_1'] = 0,
    ['helmet_1'] = -1,
    ['mask_1'] = 0,
    ['watches_1'] = -1,
    ['bags_1'] = 0,
    ['arms'] = 0,
    ['chain_1'] = 0,
    ['bracelets_1'] = -1,
}

RegisterServerEvent('codem-inventory:server:GetPlayerClothing', function(clothingdata, gender)
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end
    local clothinginventory = ClothingInventory[identifier] and ClothingInventory[identifier].inventory or {}
    if not clothinginventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['CLOTHINGINVENTORYNOTFOUND'])
        return
    end
    clothinginventory = {}
    local selectTable = gender == 'man' and inventoryClotingTableMale or inventoryClotingTableFemale
    for k, v in pairs(clothingdata) do
        if inventoryClotingTableMale[k] then
            if v.value ~= selectTable[k] then
                clothinginventory[k] = {
                    name = k,
                    label = Config.Itemlist[k].label,
                    type = 'clothes',
                    image = Config.Itemlist[k].image,
                    weight = Config.Itemlist[k].weight,
                    slot = 1,
                    description = Config.Itemlist[k].description,
                    amount = 1,
                    info = {
                        texture = v.texture,
                        skin = v.value
                    }
                }
            end
        end
    end
    ClothingInventory[identifier].inventory = clothinginventory
    TriggerClientEvent('codem-inventory:updateClothingInventory', src, clothinginventory)
    UpdateClothingSql(identifier, clothinginventory)
end)

RegisterServerEvent('codem-inventory:swaptoInventoryToClothingInventory', function(source, item)
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
        debugprint('DİKKAT ENVANTER BULUNAMADI 144 SATIR')
        return
    end
    local itemData = playerInventory[tostring(item.slot)]
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDINGIVENSLOT'])
        return
    end

    local clothinginventory = ClothingInventory[identifier] and ClothingInventory[identifier].inventory or {}

    if clothinginventory[itemData.name] then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['CLOTHINGSLOTFULL'])
        return
    else
        clothinginventory[itemData.name] = itemData
    end

    TriggerClientEvent('codem-inventory:updateClothingInventory', src, clothinginventory)
    RemoveItem(src, itemData.name, 1, itemData.slot)
    UpdateClothingSql(identifier, clothinginventory)
    Citizen.Wait(2000)
    TriggerClientEvent('RefreshPedScreen', src)
end)
function UpdateClothingSql(identifier, inventory)
    ExecuteSql(
        "INSERT INTO codem_new_clothingsitem (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE identifier = @identifier, inventory = @inventory",
        {
            identifier = identifier,
            inventory = json.encode(inventory)
        }
    )
end

RegisterServerEvent('codem-inventory:server:TakeOffClothes', function(data, gender)
    local src = source
    local identifier = Identifier[src]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end
    local clothinginventory = ClothingInventory[identifier] and ClothingInventory[identifier].inventory or {}
    if not clothinginventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['CLOTHINGINVENTORYNOTFOUND'])
        return
    end
    local itemData = clothinginventory[data.name]
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDINGIVENSLOT'])
        return
    end
    ClothingInventory[identifier].inventory[data.name] = nil
    TriggerClientEvent('codem-inventory:updateClothingInventory', src, ClothingInventory[identifier].inventory)
    AddItem(src, itemData.name, 1, nil, itemData.info)
    local selectTable = gender == 'man' and inventoryClotingTableMale or inventoryClotingTableFemale
    TriggerClientEvent('codem-inventory:client:takeoffClothing', src, itemData.name,
        selectTable[itemData.name])
    UpdateClothingSql(identifier, clothinginventory)

    Citizen.Wait(2000)
    TriggerClientEvent('RefreshPedScreen', src)
end)


RegisterServerEvent('codem-inventory:server:swaprClothingToMainInventory', function(data, gender)
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
        return
    end
    local itemData = data.itemname
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDINGIVENSLOT'])
        return
    end
    local clothinginventory = ClothingInventory[identifier] and ClothingInventory[identifier].inventory
    if not clothinginventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['CLOTHINGINVENTORYNOTFOUND'])
        return
    end
    if not clothinginventory[itemData.name] then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['CLOTHINGINVENTORYNOTFOUND'])
        return
    end
    ClothingInventory[identifier].inventory[itemData.name] = nil
    TriggerClientEvent('codem-inventory:updateClothingInventory', src, ClothingInventory[identifier].inventory)
    AddItem(src, itemData.name, 1, nil, itemData.info)
    local selectTable = gender == 'man' and inventoryClotingTableMale or inventoryClotingTableFemale
    TriggerClientEvent('codem-inventory:client:takeoffClothing', src, itemData.name,
        selectTable[itemData.name])
    SetInventory(src)
    UpdateClothingSql(identifier, clothinginventory)
    Citizen.Wait(2000)
    TriggerClientEvent('RefreshPedScreen', src)
end)

RegisterServerEvent('codem-inventory:server:swapInventoryToClothing', function(data)
    if data.itemname.type ~= 'clothes' then
        return
    end
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
        return
    end
    local itemData = data.itemname
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDINGIVENSLOT'])
        return
    end
    local clothinginventory = ClothingInventory[identifier] and ClothingInventory[identifier].inventory
    if not clothinginventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['CLOTHINGINVENTORYNOTFOUND'])
        return
    end
    if playerInventory[tostring(itemData.slot)] then
        if clothinginventory[itemData.name] then
            TriggerClientEvent('codem-inventory:client:notification', src,
                Locales[Config.Language].notification['CLOTHINGSLOTFULL'])
            return
        else
            clothinginventory[itemData.name] = itemData
        end
        TriggerClientEvent('codem-inventory:updateClothingInventory', src, clothinginventory)
        TriggerClientEvent('codem-appereance:UseOutfit', src, itemData)
        RemoveItem(src, itemData.name, 1, itemData.slot)
        UpdateClothingSql(identifier, clothinginventory)
        Citizen.Wait(2000)
        TriggerClientEvent('RefreshPedScreen', src)
    end
end)
