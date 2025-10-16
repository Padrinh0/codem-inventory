lastCheckTime = {}
function ExecuteSql(query, parameters)
    local IsBusy = true
    local result = nil
    if Config.SQL == "oxmysql" then
        if parameters then
            exports.oxmysql:execute(query, parameters, function(data)
                result = data
                IsBusy = false
            end)
        else
            exports.oxmysql:execute(query, function(data)
                result = data
                IsBusy = false
            end)
        end
    elseif Config.SQL == "ghmattimysql" then
        if parameters then
            exports.ghmattimysql:execute(query, parameters, function(data)
                result = data
                IsBusy = false
            end)
        else
            exports.ghmattimysql:execute(query, {}, function(data)
                result = data
                IsBusy = false
            end)
        end
    elseif Config.SQL == "mysql-async" then
        if parameters then
            MySQL.Async.fetchAll(query, parameters, function(data)
                result = data
                IsBusy = false
            end)
        else
            MySQL.Async.fetchAll(query, {}, function(data)
                result = data
                IsBusy = false
            end)
        end
    end
    while IsBusy do
        Citizen.Wait(0)
    end
    return result
end

function UpdateInventorySql(query, parameters)
    if Config.SQL == "oxmysql" then
        exports.oxmysql:execute(query, parameters)
    elseif Config.SQL == "ghmattimysql" then
        exports.ghmattimysql:execute(query, parameters)
    elseif Config.SQL == "mysql-async" then
        MySQL.Async.fetchAll(query, parameters)
    end
end

function RegisterCallback(name, cbFunc)
    while not Core do
        Wait(0)
    end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        Core.RegisterServerCallback(name, function(source, cb, data)
            cbFunc(source, cb, data)
        end)
    else
        Core.Functions.CreateCallback(name, function(source, cb, data)
            cbFunc(source, cb, data)
        end)
    end
end

function WaitCore()
    while Core == nil do
        Wait(0)
    end
end

function GetPlayer(source)
    local Player = false
    while Core == nil do
        Citizen.Wait(0)
    end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        Player = Core.GetPlayerFromId(source)
    else
        Player = Core.Functions.GetPlayer(source)
    end
    return Player
end

function GetIdentifier(source)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            return Player.getIdentifier()
        else
            return Player.PlayerData.citizenid
        end
    end
end

function GetPlayerByIdentifier(identifier)
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        local player = Core.GetPlayerFromIdentifier(identifier)
        if player then
            return player.source
        else
            return false
        end
    elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
        local player = Core.Functions.GetPlayerByCitizenId(identifier)
        if player then
            return player.PlayerData.source
        else
            return false
        end
    end
end

function GetName(source)
    if Config.Framework == "oldesx" or Config.Framework == "esx" then
        local xPlayer = Core.GetPlayerFromId(tonumber(source))
        if xPlayer then
            return xPlayer.getName()
        else
            return "0"
        end
    elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
        local Player = Core.Functions.GetPlayer(tonumber(source))
        if Player then
            return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        else
            return "0"
        end
    end
end

GetRandomString = function()
    local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local randomString = ""
    for i = 1, 11 do
        local randomIndex = math.random(1, #characters)
        local randomChar = characters:sub(randomIndex, randomIndex)
        randomString = randomString .. randomChar
    end
    return randomString
end

function FindFirstEmptySlot(inventory, slot)
    for i = 1, slot do
        if not inventory[tostring(i)] then
            return tostring(i)
        end
    end
    return nil
end

function CheckInventoryWeight(inventory, newitemweight, MaxWeight)
    local currentWeight = 0
    newitemweight = tonumber(newitemweight)
    MaxWeight = tonumber(MaxWeight)
    for slot, item in pairs(inventory) do
        if item.weight and item.weight > 0 then
            item.weight = tonumber(item.weight)
            item.amount = tonumber(item.amount)
            currentWeight = currentWeight + (item.weight * item.amount)
        end
    end
    if currentWeight + newitemweight > MaxWeight then
        return false
    else
        return true
    end
end

function RemoveMoney(source, type, value)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            if type == 'bank' then
                Player.removeAccountMoney('bank', value)
            end
            if type == 'cash' then
                Player.removeMoney(value)
            end
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            if type == 'bank' then
                Player.Functions.RemoveMoney('bank', value)
            end
            if type == 'cash' then
                Player.Functions.RemoveMoney('cash', value)
            end
        end
    end
end

function AddMoney(source, type, value)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            if type == 'bank' then
                Player.addAccountMoney('bank', value)
            end
            if type == 'cash' then
                Player.addMoney(value)
            end
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            if type == 'bank' then
                Player.Functions.AddMoney('bank', value)
            end
            if type == 'cash' then
                Player.Functions.AddMoney('cash', value)
            end
        end
    end
end

function GetPlayerMoney(source, value)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            if value == 'bank' then
                return Player.getAccount('bank').money
            end
            if value == 'cash' then
                return Player.getMoney()
            end
        elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            if value == 'bank' then
                return Player.PlayerData.money['bank']
            end
            if value == 'cash' then
                return Player.Functions.GetMoney('cash')
            end
        end
    end
end

Citizen.CreateThread(function()
    while Core == nil do
        Citizen.Wait(0)
    end
    if (Config.Framework == "qb" or Config.Framework == "oldqb") then
        Core.Commands.Add(Config.Commands['giveitem'], "Give An Item (Admin Only)",
            { { name = "id",   help = "Player ID" }, { name = "item", help = "Name of the item (not a label)" },
                { name = "amount", help = "Amount of items" } }, false, function(source, args)
                local id = tonumber(args[1])
                local Player = Core.Functions.GetPlayer(id)
                local amount = tonumber(args[3]) or 1
                local itemname = tostring(args[2]):lower()
                local itemData = Config.Itemlist[itemname]
                if Player then
                    if itemData then
                        if itemData.name == 'cash' then
                            AddMoney(Player.PlayerData.source, 'cash', amount)
                            --  AddItem(Player.PlayerData.source, 'cash', amount)
                        else
                            AddItem(Player.PlayerData.source, itemData.name, amount)
                        end
                        if Config.UseDiscordWebhooks then
                            local discorddata = {
                                playername = GetName(Player.PlayerData.source),
                                itemname = itemData.label,
                                amount = amount,
                                reason = 'ADMIN : ' ..
                                    GetName(source) .. ' ' .. Locales[Config.Language].notification['ADDITEMCOMMAND']
                            }
                            TriggerEvent("codem-inventory:CreateLog",
                                Locales[Config.Language].notification['ADDITEMCOMMAND'], "green",
                                discorddata, Player.PlayerData.source)
                        end
                    else
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['ITEMNOTFOUND'])
                    end
                else
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['PLAYERNOTFOUND'])
                end
            end, "admin")


        Core.Commands.Add(Config.Commands['clearinv'], "Clear Player Inventory (Admin Only)",
            { { name = "id", help = "Player ID" } }, false, function(source, args)
                local id = tonumber(args[1])
                local Player = Core.Functions.GetPlayer(id)
                if Player then
                    local identifier = Identifier[tonumber(id)]
                    if not identifier then
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
                        return
                    end
                    ClearInventory(Player.PlayerData.source)
                else
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['PLAYERNOTFOUND'])
                end
            end, "admin")
        Core.Commands.Add(Config.Commands['openinventoryplayer'], "Open Player Inventory (Admin Only)",
            { { name = "id", help = "Player ID" } }, false, function(source, args)
                local id = tonumber(args[1])
                local Player = Core.Functions.GetPlayer(id)
                if Player then
                    local identifier = Identifier[tonumber(id)]
                    if not identifier then
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
                        return
                    end
                    local inventory = PlayerServerInventory[identifier].inventory
                    if not inventory then
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
                        return
                    end
                    TriggerClientEvent('codem-inventory:client:openplayerinventory', source, tonumber(id))
                else
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['PLAYERNOTFOUND'])
                end
            end, "admin")
        Core.Commands.Add(Config.Commands['openstash'], "Open Stash (Admin Only)",
            { { name = "stashname", help = "stash ID" } }, false, function(source, args)
                local stashname = args[1]
                local stash = ServerStash[stashname]
                if stash then
                    local stashInventory = stash and stash.inventory
                    local stashData = {
                        inventory = stashInventory,
                        slot = 500,
                        maxweight = 50000000,
                        stashId = stashname,
                        label = 'STASH'
                    }
                    TriggerClientEvent('codem-inventory:client:openstash', source, stashData)
                else
                    print('stash not found')
                end
            end, "admin")
    end
    if (Config.Framework == "esx" or Config.Framework == "oldesx") then
        RegisterCommand(Config.Commands['giveitem'], function(source, args)
            local src = source
            if not CheckIfAdmin(src) then return end
            local id = tonumber(args[1])
            local item = args[2]
            local itemData = Config.Itemlist[tostring(item):lower()]
            local amount = args[3]
            local Player = Core.GetPlayerFromId(id)
            if Player then
                if itemData then
                    if itemData.name == 'cash' then
                        Player.addMoney(amount)
                    else
                        AddItem(Player.source, itemData.name, amount)
                    end
                    if Config.UseDiscordWebhooks then
                        local discorddata = {
                            playername = GetName(Player.source),
                            itemname = itemData.label,
                            amount = amount,
                            reason = 'ADMIN : ' ..
                                GetName(source) .. ' ' .. Locales[Config.Language].notification['ADDITEMCOMMAND']
                        }
                        TriggerEvent("codem-inventory:CreateLog",
                            Locales[Config.Language].notification['ADDITEMCOMMAND'], "green",
                            discorddata, Player.source)
                    end
                else
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['ITEMNOTFOUND'])
                end
            else
                TriggerClientEvent('codem-inventory:client:notification', source,
                    Locales[Config.Language].notification['PLAYERNOTFOUND'])
            end
        end)
        RegisterCommand(Config.Commands['clearinv'], function(source, args)
            local src = source
            if not CheckIfAdmin(src) then return end
            local id = tonumber(args[1])
            local Player = Core.GetPlayerFromId(id)
            if Player then
                local identifier = Identifier[tonumber(id)]
                if not identifier then
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
                    return
                end
                ClearInventory(tonumber(id))
            else
                TriggerClientEvent('codem-inventory:client:notification', source,
                    Locales[Config.Language].notification['PLAYERNOTFOUND'])
            end
        end)
        RegisterCommand(Config.Commands['openinventoryplayer'], function(source, args)
            local src = source
            if not CheckIfAdmin(src) then return end
            local id = tonumber(args[1])
            local Player = Core.GetPlayerFromId(id)
            if Player then
                local identifier = Identifier[tonumber(id)]
                if not identifier then
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
                    return
                end
                local inventory = PlayerServerInventory[identifier].inventory
                if not inventory then
                    TriggerClientEvent('codem-inventory:client:notification', source,
                        Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
                    return
                end
                TriggerClientEvent('codem-inventory:client:openplayerinventory', source, tonumber(id))
            else
                TriggerClientEvent('codem-inventory:client:notification', source,
                    Locales[Config.Language].notification['PLAYERNOTFOUND'])
            end
        end)
        RegisterCommand(Config.Commands['openstash'], function(source, args)
            local src = source
            if not CheckIfAdmin(src) then return end
            local stashname = args[1]
            local stash = ServerStash[stashname]
            if stash then
                local stashInventory = stash and stash.inventory
                local stashData = {
                    inventory = stashInventory,
                    slot = 500,
                    maxweight = 50000000,
                    stashId = stashname,
                    label = 'STASH'
                }
                TriggerClientEvent('codem-inventory:client:openstash', source, stashData)
            else
                print('stash not found')
            end
        end)
    end
end)

local function handlePlayerUnload(playerId)
    playerId = tonumber(playerId)
    SavePlayerInventory(playerId)

    ServerPlayerKey[playerId] = nil
    local identifier = Identifier[playerId]
    if not identifier then
        return
    end

    PlayerServerInventory[identifier] = nil
    Identifier[playerId] = nil
    lastCheckTime[playerId] = nil
    cooldown[playerId] = nil
end

RegisterServerEvent('codem-inventory:server:onplayerunload', function()
    handlePlayerUnload(source)
end)

AddEventHandler('playerDropped', function()
    handlePlayerUnload(source)
end)
function SavePlayerInventory(id)
    local identifier = Identifier[tonumber(id)]
    if not identifier then
        return
    end
    local itemList = {}
    local playerInventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not playerInventory then
        print('DİKKAT ENVANTER BULUNAMADI 411 SATIR')
        return
    end
    for k, v in pairs(playerInventory) do
        itemList[k] = {
            name = v.name,
            amount = v.amount,
            info = v.info,
        }
    end
    ExecuteSql(
        "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE identifier = @identifier, inventory = @inventory",
        { identifier = identifier, inventory = json.encode(itemList) }
    )
end

function CheckPermissions(permission)
    for _, v in pairs(GetPermission()) do
        if v == permission then
            return true
        end
    end
    return false
end

function CheckIfAdmin(source)
    local src = source
    local Player = GetPlayer(src)
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        return CheckPermissions(Player.getGroup())
    end
    return false
end

function GetPermission()
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        return {
            "superadmin",
            "admin",
            "mod",
        }
    end
end

function GetJob(source)
    local Player = GetPlayer(source)
    if Player then
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            return Player.getJob().name
        else
            return Player.PlayerData.job.name
        end
    end
    return false
end

Citizen.CreateThread(function()
    while not next(Config.Itemlist) do
        Wait(0)
    end
    while Core == nil do
        Wait(0)
    end
    for k, v in pairs(Config.Itemlist) do
        if v.type == "weapon" then
            if (Config.Framework == "qb" or Config.Framework == "oldqb") then
                Core.Functions.CreateUseableItem(v.name, function(source, item)
                    if (item and item.info) then
                        if Config.DurabilitySystem then
                            if (item.info.quality and item.info.quality <= 0) then
                                TriggerClientEvent('codem-inventory:client:notification', source,
                                    Locales[Config.Language].notification['CANTUSEITEM'])
                                return
                            end
                        end

                        if not item.ammotype then
                            item.ammotype = Config.Itemlist[item.name].ammotype or nil
                        end
                        TriggerClientEvent('codem-inventory:client:UseWeapon', source, item)
                        CheckDupliceteItems(source)
                    else
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['ITEMINFONOTFOUND'])
                    end
                end)
            elseif Config.Framework == "esx" or Config.Framework == 'oldesx' then
                Core.RegisterUsableItem(v.name, function(source, itemname, item)
                    if (item and item.info) then
                        if Config.DurabilitySystem then
                            if (item.info.quality and item.info.quality <= 0) then
                                TriggerClientEvent('codem-inventory:client:notification', source,
                                    Locales[Config.Language].notification['CANTUSEITEM'])
                                return
                            end
                        end

                        if not item.ammotype then
                            item.ammotype = Config.Itemlist[item.name].ammotype or nil
                        end
                        TriggerClientEvent('codem-inventory:client:UseWeapon', source, item)
                    else
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['ITEMINFONOTFOUND'])
                    end
                end)
            end
        end

        if v.type == 'bag' then
            if (Config.Framework == "qb" or Config.Framework == "oldqb") then
                Core.Functions.CreateUseableItem(v.name, function(source, item)
                    if (item and item.info and item.info.series) then
                        TriggerClientEvent('codem-inventory:useBackpackItem', source, item)
                    else
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['ITEMINFONOTFOUND'])
                    end
                end)
            elseif (Config.Framework == "esx") then
                Core.RegisterUsableItem(v.name, function(source, itemname, item)
                    if (item and item.info and item.info.series) then
                        TriggerClientEvent('codem-inventory:useBackpackItem', source, item)
                    else
                        TriggerClientEvent('codem-inventory:client:notification', source,
                            Locales[Config.Language].notification['ITEMINFONOTFOUND'])
                    end
                end)
            end
        end
    end
end)


RegisterServerEvent('codem-inventory:server:UseItem', function(slot, name)
    local src = source
    local identifier = Identifier[tonumber(src)]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end

    local playerInventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not playerInventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
        debugprint('DİKKAT ENVANTER BULUNAMADI 1415 SATIR')
        return
    end
    local itemData = playerInventory[tostring(slot)]
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDINGIVENSLOT'])
        return
    end
    if itemData.name == name then
        if itemData.shouldClose then
            TriggerClientEvent('codem-inventory:client:closeInventory', src)
        end
        if Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            UseItem(itemData.name, src, itemData)
        else
            Core.UseItem(src, itemData.name, itemData)
        end
    end
end)



Citizen.CreateThread(function()
    if Config.VersionChecker then
        local resource_name = 'codem_inventory'
        local current_version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
        PerformHttpRequest('https://raw.githubusercontent.com/Aiakos232/versionchecker/main/version.json',
            function(error, result, headers)
                if not result then
                    print('^1Version check disabled because github is down.^0')
                    return
                end
                local result = json.decode(result)
                if tonumber(result[resource_name]) ~= nil then
                    if tonumber(result[resource_name]) > tonumber(current_version) then
                        print('\n')
                        print('^1======================================================================^0')
                        print('^1' .. resource_name ..
                            ' is outdated, new version is available: ' .. result[resource_name] .. '^0')
                        print('^1======================================================================^0')
                        print('\n')
                    elseif tonumber(result[resource_name]) == tonumber(current_version) then
                        print('^2' .. resource_name .. ' is up to date! -  ^4 Thanks for choose CodeM ^4 ^0')
                    elseif tonumber(result[resource_name]) < tonumber(current_version) then
                        print('^3' .. resource_name .. ' is a higher version than the official version!^0')
                    end
                else
                    print('^1' .. resource_name .. ' is not in the version database^0')
                end
            end, 'GET')
    end
end)


Citizen.CreateThread(function()
    local niltable = {}
    local result = ExecuteSql("SELECT * FROM codem_new_stash")
    for k, v in pairs(result) do
        for i, j in pairs(json.decode(v.inventory)) do
            if i == 'nil' or i == nil then
                table.insert(niltable, v.stashname)
            end
        end
    end

    for k, v in pairs(niltable) do
        print('ERROR : nil item index pls check : ' .. v)
    end
end)
