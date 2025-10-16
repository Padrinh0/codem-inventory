function HasItem(items, amount)
    local isTable = type(items) == 'table'
    local isArray = isTable and table.type(items) == 'array' or false
    local totalItems = #items or 0
    if totalItems == 0 then return false end
    local count = 0
    local kvIndex = 2
    if isTable and not isArray then
        totalItems = 0
        for _ in pairs(items) do totalItems += 1 end
        kvIndex = 1
    end
    for _, itemData in pairs(ClientInventory) do
        if isTable then
            for k, v in pairs(items) do
                local itemKV = { k, v }
                if itemData and itemData.name == itemKV[kvIndex] and ((amount and itemData.amount >= amount) or (not isArray and itemData.amount >= v) or (not amount and isArray)) then
                    count += 1
                end
            end
            if count == totalItems then
                return true
            end
        else -- Single item as string
            if itemData and itemData.name == items and (not amount or (itemData and amount and itemData.amount >= amount)) then
                return true
            end
        end
    end
    return false
end

exports('HasItem', HasItem)

local SharedWeapons = {}
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

exports('SharedWeapons', function(name)
    if SharedWeapons[name] then
        return SharedWeapons[name]
    end
    return false
end)



function GetItemList()
    return Config.Itemlist
end

exports('GetItemList', GetItemList)


function getUserInventory()
    local items = TriggerCallback('codem-inventory:getUserInventory')
    return items
end

exports('getUserInventory', getUserInventory)

function GetClientPlayerInventory()
    local inventory = ClientInventory
    for k, v in pairs(inventory) do
        if not v.count then
            v.count = v.amount
        end
        v.count = v.amount
    end
    return inventory
end

exports('GetClientPlayerInventory', GetClientPlayerInventory)

function isOpen()
    return OpenInventory
end

exports('isOpen', isOpen)


function ClosePlayerInventory()
    TriggerEvent('codem-inventory:client:closeInventory')
end

exports('CloseInventory', ClosePlayerInventory)

function OpenPlayerInventory()
    TriggerEvent('codem-inventory:openInventory')
end

exports('OpenInventory', OpenPlayerInventory)
