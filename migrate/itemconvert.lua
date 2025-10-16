RegisterCommand('migrateoxitemlist', function(source)
    if source > 0 then
        return
    end
    MigrateOxInventoryItemList()
end)


function MigrateOxInventoryItemList()
    local filePathOx = 'data/items.lua'
    local fileContentOx = LoadResourceFile('ox_inventory', filePathOx)
    if not fileContentOx then
        print("ERROR: Unable to read the ox_inventory items.lua file content.")
        return
    end
    itemcount = 0
    local weaponFilePath = 'migrate/weaponlist.lua'
    local weaponFileContent = LoadResourceFile('codem-inventory', weaponFilePath)
    if not weaponFileContent then
        print("ERROR: Unable to read the codem-inventory weaponlist.lua file content.")
        return
    end

    local func = loadstring or load
    local itemsOx, errorOx = func(fileContentOx)()
    if errorOx then
        print("ERROR compiling ox_inventory items: ", errorOx)
        return
    end

    local itemsWeapons, errorWeapons = func(weaponFileContent)()
    if errorWeapons then
        print("ERROR compiling codem-inventory weapons: ", errorWeapons)
        return
    end

    for key, value in pairs(itemsWeapons) do
        itemsOx[key] = value
    end

    local itemsContent = "Config.Itemlist = {\n"
    for key, value in pairs(itemsOx) do
        local formattedKey = string.format('["%s"]', key)
        itemsContent = itemsContent .. string.format(
            '    %s = {\n        name = "%s",\n        label = "%s",\n        weight = %d,\n        shouldClose = %s,\n        description = "%s",\n        unique = %s,\n        type = "%s",\n        image = "%s",\n        useable = %s,\n    },\n',
            formattedKey,
            value.name or key,
            value.label or "Unknown",
            value.weight or 0,
            tostring(value.shouldClose or false),
            value.description or "No description",
            tostring(value.unique or false),
            value.type or 'item',
            value.image or 'placeholder.png',
            tostring(value.useable or false)
        )
        itemcount = itemcount + 1
    end
    itemsContent = itemsContent .. "}"

    local CodemFilePath = 'config/itemlist.lua'
    SaveResourceFile('codem-inventory', CodemFilePath, itemsContent, -1)
    print('Item list has been successfully migrated to Codem Inventory count :x', itemcount)
end

RegisterCommand('migrateoldcodemitemlist', function(source)
    if source > 0 then
        return
    end
    MigrateOldCodemInventoryItemList()
end)


function MigrateOldCodemInventoryItemList()
    local filePathOx = 'shared/itemlist.lua'
    local fileContentOx = LoadResourceFile('codem-inventory2', filePathOx)

    if not fileContentOx then
        print("ERROR: Unable to read the ox_inventory items.lua file content.")
        return
    end
    itemcount = 0
    local weaponFilePath = 'migrate/weaponlist.lua'
    local weaponFileContent = LoadResourceFile('codem-inventory', weaponFilePath)
    if not weaponFileContent then
        print("ERROR: Unable to read the codem-inventory weaponlist.lua file content.")
        return
    end

    local func = loadstring or load
    local itemsOx, errorOx = func(fileContentOx)()
    if errorOx then
        print("ERROR compiling ox_inventory items: ", errorOx)
        return
    end

    local itemsWeapons, errorWeapons = func(weaponFileContent)()
    if errorWeapons then
        print("ERROR compiling codem-inventory weapons: ", errorWeapons)
        return
    end

    for key, weaponItem in pairs(itemsWeapons) do
        itemsOx[key] = weaponItem
    end

    local itemsContent = "Config.Itemlist = {\n"
    for key, value in pairs(itemsOx) do
        local formattedKey = string.format('["%s"]', key)
        local ammotypeLine = value.ammotype and string.format('        ammotype = "%s",\n', value.ammotype) or ''
        itemsContent = itemsContent .. string.format(
            '    %s = {\n        name = "%s",\n        label = "%s",\n        weight = %d,\n        shouldClose = %s,\n        description = "%s",\n        unique = %s,\n        type = "%s",\n        image = "%s",\n        useable = %s,\n%s    },\n',
            formattedKey,
            value.name or key,
            value.label or "Unknown",
            value.weight or 0,
            tostring(value.shouldClose or false),
            value.description or "No description",
            tostring(value.unique or false),
            value.type or 'item',
            value.image or value.name .. '.png',
            tostring(value.useable or false),
            ammotypeLine -- Add the ammotype line here, it will be an empty string if ammotype doesn't exist
        )
        itemcount = itemcount + 1
    end

    itemsContent = itemsContent .. "}"

    local CodemFilePath = 'config/itemlist.lua'
    SaveResourceFile('codem-inventory', CodemFilePath, itemsContent, -1)
    print('Item list has been successfully migrated to Codem Inventory count :x', itemcount)
end

RegisterCommand('migrateqbitemlist', function(source)
    if source > 0 then
        return
    end
    MigrateQBInventoryItemList()
end)

function MigrateQBInventoryItemList()
    local filePathQB = 'shared/items.lua'
    local fileContentQB = LoadResourceFile('qb-core', filePathQB)
    if not fileContentQB then
        print("ERROR: Unable to read the qb-core items.lua file content.")
        return
    end
    itemcount = 0

    local weaponFilePath = 'migrate/weaponlist.lua'
    local weaponFileContent = LoadResourceFile('codem-inventory', weaponFilePath)
    if not weaponFileContent then
        print("ERROR: Unable to read the codem-inventory weaponlist.lua file content.")
        return
    end

    local func = loadstring or load
    local itemsQB, errorQB = func(fileContentQB)()
    if errorQB then
        print("ERROR compiling qb-core items: ", errorQB)
        return
    end

    local itemsContent = "Config.Itemlist = {\n"
    for key, value in pairs(itemsQB) do
        local formattedKey = string.format('["%s"]', key)
        itemsContent = itemsContent .. string.format(
            '    %s = {\n        name = "%s",\n        label = "%s",\n        weight = %d,\n        type = "%s",\n        image = "%s",\n        unique = %s,\n        useable = %s,\n        shouldClose = %s,\n        description = "%s",\n    },\n',
            formattedKey,
            value.name or key,
            value.label or "Unknown",
            value.weight or 0,
            value.type or 'item',
            value.image or 'placeholder.png',
            tostring(value.unique or false),
            tostring(value.useable or false),
            tostring(value.shouldClose or false),
            value.description or "No description"
        )
        itemcount = itemcount + 1
    end
    itemsContent = itemsContent .. "}"

    local CodemFilePath = 'config/itemlist.lua'
    SaveResourceFile('codem-inventory', CodemFilePath, itemsContent, -1)
    print('QBCORE - Item list has been successfully migrated to Codem Inventory count :x', itemcount)
end

RegisterCommand('migrateqbsqlitems', function(source)
    if source > 0 then
        return
    end
    MigrateQBSQLItems()
end)


function MigrateQBSQLItems()
    local playerItems = {}
    local result = ExecuteSql("SELECT * FROM `players`")
    for _, playerData in pairs(result) do
        local items = json.decode(playerData.inventory) or {}
        local citizenid = playerData.citizenid
        if not playerItems[citizenid] then
            playerItems[citizenid] = {}
        end
        for itemSlot, item in pairs(items) do
            if item then
                local initializedInfo = InitInfo(item.name, item.info or {}) -- Ensure item.info is a table or an empty table
                item.info = initializedInfo
                item.slot = tostring(itemSlot)
                local invTable = {
                    name = item.name,
                    amount = item.amount or 1,
                    info = (type(item.info) == 'table' and next(item.info) ~= nil) and item.info or nil, -- Check if item.info is a table
                }
                playerItems[citizenid][tostring(itemSlot)] = invTable
                print('Migrating item: ' .. item.name .. ' for citizenid: ' .. citizenid)
            end
        end
    end

    for citizenid, items in pairs(playerItems) do
        local encodedItems = json.encode(items)
        ExecuteSql(
            "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE inventory = @inventory",
            { identifier = citizenid, inventory = encodedItems }
        )
        print('Migrating items for citizenid: ' .. citizenid)
    end
    print("End migration")
end

RegisterCommand('migrateqbsqlstashs', function(source)
    if source > 0 then
        return
    end
    MigrateQBSQLStashs()
end)

function MigrateQBSQLStashs()
    local playerItems = {}
    local result = ExecuteSql("SELECT * FROM `stashitems`")
    for _, stashData in pairs(result) do
        local items = json.decode(stashData.items) or {}
        local stashname = stashData.stash
        if not playerItems[stashname] then
            playerItems[stashname] = {}
        end
        for itemSlot, item in pairs(items) do
            if item then
                local initializedInfo = InitInfo(item.name, item.info)
                item.info = initializedInfo
                item.slot = tostring(itemSlot)
                playerItems[stashname][tostring(itemSlot)] = item
                print('Migrating item: ' .. item.name .. ' for citizenid: ' .. stashname)
            end
        end
    end

    for stashname, items in pairs(playerItems) do
        local encodedItems = json.encode(items)
        ExecuteSql(
            "INSERT INTO codem_new_stash (stashname, inventory) VALUES (@stashname, @inventory) ON DUPLICATE KEY UPDATE inventory = @inventory",
            { stashname = stashname, inventory = encodedItems }
        )
        print('Migrating items for citizenid (stash) : ' .. stashname)
    end
    print("End migration")
end

RegisterCommand('migrateqbsqltrunkandglovebox', function(source)
    if source > 0 then
        return
    end
    MigrateQBSQLTrunkandGlovebox()
end)


local function isEmpty(t)
    return next(t) == nil
end

function MigrateQBSQLTrunkandGlovebox()
    local trunkItems = {}
    local trunkResult = ExecuteSql("SELECT * FROM `trunkitems`")
    for _, trunkData in pairs(trunkResult) do
        local items = json.decode(trunkData.items) or {}
        local plate = trunkData.plate
        if not isEmpty(items) then
            trunkItems[plate] = trunkItems[plate] or {}
            for itemSlot, item in pairs(items) do
                if item then
                    local initializedInfo = InitInfo(item.name, item.info)
                    item.info = initializedInfo
                    trunkItems[plate][tostring(itemSlot)] = item
                    print('Migrating trunk item: ' .. item.name .. ' for plate: ' .. plate)
                end
            end
        end
    end

    for plate, items in pairs(trunkItems) do
        local lowerCasePlate = plate:lower()
        ExecuteSql(
            "INSERT INTO codem_new_vehicleandglovebox (plate, trunk) VALUES (@plate, @trunk) ON DUPLICATE KEY UPDATE trunk = @trunk",
            { plate = lowerCasePlate, trunk = json.encode(items) }
        )
    end

    local gloveboxItems = {}
    local gloveboxResult = ExecuteSql("SELECT * FROM `gloveboxitems`")
    for _, gloveboxData in pairs(gloveboxResult) do
        local items = json.decode(gloveboxData.items) or {}
        local plate = gloveboxData.plate
        if not isEmpty(items) then
            gloveboxItems[plate] = gloveboxItems[plate] or {}
            for itemSlot, item in pairs(items) do
                if item then
                    local initializedInfo = InitInfo(item.name, item.info)
                    item.info = initializedInfo
                    gloveboxItems[plate][tostring(itemSlot)] = item
                    print('Migrating glovebox item: ' .. item.name .. ' for plate: ' .. plate)
                end
            end
        end
    end

    for plate, items in pairs(gloveboxItems) do
        local lowerCasePlate = plate:lower()
        ExecuteSql(
            "INSERT INTO codem_new_vehicleandglovebox (plate, glovebox) VALUES (@plate, @glovebox) ON DUPLICATE KEY UPDATE glovebox = @glovebox",
            { plate = lowerCasePlate, glovebox = json.encode(items) }
        )
    end

    print("Migration for trunk and glovebox has ended.")
end

RegisterCommand("migrateoldtonewplayer", function()
    local playerItems = {}
    local result = ExecuteSql("SELECT * FROM `codem_invdata` WHERE `type` = 'player'")
    for _, playerData in pairs(result) do
        local items = json.decode(playerData.items) or {}
        local citizenid = playerData.name
        if not playerItems[citizenid] then
            playerItems[citizenid] = {}
        end
        if not isEmpty(items) then
            for itemSlot, item in pairs(items) do
                if item then
                    local initializedInfo = InitInfo(item.name, item.info[1], item.type)
                    item.info = initializedInfo
                    item.slot = tostring(itemSlot)
                    local invTable = {
                        name = item.name,
                        amount = item.amount or 1,
                        info = initializedInfo
                    }
                    playerItems[citizenid][tostring(itemSlot)] = invTable
                    print('Migrating item: ' .. item.name .. ' for citizenid: ' .. citizenid)
                end
            end
        end
    end

    for citizenid, items in pairs(playerItems) do
        local encodedItems = json.encode(items)
        ExecuteSql(
            "INSERT INTO codem_new_inventory (identifier, inventory) VALUES (@identifier, @inventory) ON DUPLICATE KEY UPDATE inventory = @inventory",
            { identifier = citizenid, inventory = encodedItems }
        )
        print('Migrating items for citizenid: ' .. citizenid)
    end
    print("End migration")
end)


RegisterCommand("migrateoldtonewtrunkandglovebox", function()
    local trunkItems = {}
    local trunkResult = ExecuteSql("SELECT * FROM `codem_invdata` WHERE `type` = 'Trunk'")
    for _, trunkData in pairs(trunkResult) do
        local items = json.decode(trunkData.items) or {}
        local plate = trunkData.name
        if not isEmpty(items) then
            trunkItems[plate] = trunkItems[plate] or {}
            for itemSlot, item in pairs(items) do
                if item then
                    local initializedInfo = InitInfo(item.name, item.info[1], item.type)
                    item.info = initializedInfo
                    trunkItems[plate][tostring(itemSlot)] = item
                    trunkItems[plate][tostring(itemSlot)].slot = tostring(itemSlot)
                    trunkItems[plate][tostring(itemSlot)].amount = tonumber(item.count) or 1
                    if trunkItems[plate][tostring(itemSlot)].image == nil then
                        if Config.Itemlist[item.name] and Config.Itemlist[item.name].image then
                            trunkItems[plate][tostring(itemSlot)].image = Config.Itemlist[item.name].image
                        else
                            trunkItems[plate][tostring(itemSlot)].image = item.name .. '.png'
                        end
                    end
                    if trunkItems[plate][tostring(itemSlot)].usable == nil then
                        if Config.Itemlist[item.name] and Config.Itemlist[item.name].usable then
                            trunkItems[plate][tostring(itemSlot)].usable = true
                        else
                            trunkItems[plate][tostring(itemSlot)].usable = true
                        end
                    end
                    if Config.Itemlist[item.name] then
                        if trunkItems[plate][tostring(itemSlot)].ammotype then
                            trunkItems[plate][tostring(itemSlot)].ammotype = Config.Itemlist[item.name].ammotype or nil
                        end
                    end
                    if trunkItems[plate][tostring(itemSlot)].closeafteruse ~= nil then
                        trunkItems[plate][tostring(itemSlot)].shouldClose = trunkItems[plate][tostring(itemSlot)]
                            .closeafteruse
                        trunkItems[plate][tostring(itemSlot)].closeafteruse = nil
                    end
                    print('Migrating trunk item: ' .. item.name .. ' for plate: ' .. plate)
                end
            end
        end
    end

    for plate, items in pairs(trunkItems) do
        local lowerCasePlate = plate:lower()
        ExecuteSql(
            "INSERT INTO codem_new_vehicleandglovebox (plate, trunk) VALUES (@plate, @trunk) ON DUPLICATE KEY UPDATE trunk = @trunk",
            { plate = lowerCasePlate, trunk = json.encode(items) }
        )
    end

    local gloveboxItems = {}
    local gloveboxResult = ExecuteSql("SELECT * FROM `codem_invdata` WHERE `type` = 'Glovebox'")
    for _, gloveboxData in pairs(gloveboxResult) do
        local items = json.decode(gloveboxData.items) or {}
        local plate = gloveboxData.name
        if not isEmpty(items) then
            gloveboxItems[plate] = gloveboxItems[plate] or {}
            for itemSlot, item in pairs(items) do
                if item then
                    local initializedInfo = InitInfo(item.name, item.info[1], item.type)
                    item.info = initializedInfo
                    gloveboxItems[plate][tostring(itemSlot)] = item
                    gloveboxItems[plate][tostring(itemSlot)].slot = tostring(itemSlot)
                    gloveboxItems[plate][tostring(itemSlot)].amount = tonumber(item.count) or 1
                    if gloveboxItems[plate][tostring(itemSlot)].image == nil then
                        if Config.Itemlist[item.name] and Config.Itemlist[item.name].image then
                            gloveboxItems[plate][tostring(itemSlot)].image = Config.Itemlist[item.name].image
                        else
                            gloveboxItems[plate][tostring(itemSlot)].image = item.name .. '.png'
                        end
                    end

                    if gloveboxItems[plate][tostring(itemSlot)].usable == nil then
                        if Config.Itemlist[item.name] and Config.Itemlist[item.name].usable then
                            gloveboxItems[plate][tostring(itemSlot)].usable = true
                        else
                            gloveboxItems[plate][tostring(itemSlot)].usable = true
                        end
                    end

                    if gloveboxItems[plate][tostring(itemSlot)].ammotype then
                        gloveboxItems[plate][tostring(itemSlot)].ammotype = Config.Itemlist[item.name].ammotype or nil
                    end

                    if gloveboxItems[plate][tostring(itemSlot)].closeafteruse ~= nil then
                        gloveboxItems[plate][tostring(itemSlot)].shouldClose = gloveboxItems[plate][tostring(itemSlot)]
                            .closeafteruse
                        gloveboxItems[plate][tostring(itemSlot)].closeafteruse = nil
                    end
                    print('Migrating glovebox item: ' .. item.name .. ' for plate: ' .. plate)
                end
            end
        end
    end

    for plate, items in pairs(gloveboxItems) do
        local lowerCasePlate = plate:lower()
        ExecuteSql(
            "INSERT INTO codem_new_vehicleandglovebox (plate, glovebox) VALUES (@plate, @glovebox) ON DUPLICATE KEY UPDATE glovebox = @glovebox",
            { plate = lowerCasePlate, glovebox = json.encode(items) }
        )
    end

    print("Migration for trunk and glovebox has ended.")
end)



RegisterCommand("migrateoldtonewstash", function()
    local playerItems = {}
    local result = ExecuteSql("SELECT * FROM `codem_invdata` WHERE `type` = 'Stash'")
    for _, stashData in pairs(result) do
        local items = json.decode(stashData.items) or {}
        local stashname = stashData.name
        if not playerItems[stashname] then
            playerItems[stashname] = {}
        end
        if not isEmpty(items) then
            for itemSlot, item in pairs(items) do
                if item then
                    local initializedInfo = InitInfo(item.name, item.info[1], item.type)
                    item.info = initializedInfo
                    item.slot = tostring(itemSlot)
                    playerItems[stashname][tostring(itemSlot)] = item
                    playerItems[stashname][tostring(itemSlot)].slot = tostring(itemSlot)
                    playerItems[stashname][tostring(itemSlot)].amount = item.count or 1
                    if playerItems[stashname][tostring(itemSlot)].image == nil then
                        if Config.Itemlist[item.name] and Config.Itemlist[item.name].image then
                            playerItems[stashname][tostring(itemSlot)].image = Config.Itemlist[item.name].image
                        else
                            playerItems[stashname][tostring(itemSlot)].image = item.name .. '.png'
                        end
                    end

                    if playerItems[stashname][tostring(itemSlot)].usable == nil then
                        if Config.Itemlist[item.name] and Config.Itemlist[item.name].usable then
                            playerItems[stashname][tostring(itemSlot)].usable = true
                        else
                            playerItems[stashname][tostring(itemSlot)].usable = true
                        end
                    end

                    if playerItems[stashname][tostring(itemSlot)].ammotype then
                        playerItems[stashname][tostring(itemSlot)].ammotype = Config.Itemlist[item.name].ammotype or nil
                    end

                    if playerItems[stashname][tostring(itemSlot)].closeafteruse ~= nil then
                        playerItems[stashname][tostring(itemSlot)].shouldClose = playerItems[stashname]
                            [tostring(itemSlot)]
                            .closeafteruse
                        playerItems[stashname][tostring(itemSlot)].closeafteruse = nil
                    end


                    print('Migrating item: ' .. item.name .. ' for citizenid: ' .. stashname)
                end
            end
        end
    end

    for stashname, items in pairs(playerItems) do
        local encodedItems = json.encode(items)
        ExecuteSql(
            "INSERT INTO codem_new_stash (stashname, inventory) VALUES (@stashname, @inventory) ON DUPLICATE KEY UPDATE inventory = @inventory",
            { stashname = stashname, inventory = encodedItems }
        )
        print('Migrating items for citizenid (stash) : ' .. stashname)
    end
    print("End migration")
end)



InitInfo = function(name, info, itemtype)
    if info == nil then
        info = {}
    end
    local info = next(info) and info or {}
    local itemData = Config.Itemlist[name]
    if itemData == nil then
        if itemtype ~= nil and itemtype == "ammo" or not Config.DurabilityItems[name] then
            info = nil
        end
        return info
    end
    if itemData.name == 'id_card' then
        if Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            return info
        end
    end
    if itemData.type == 'weapon' then
        if Config.Throwables[itemData.name] then
            if info then
                info = {}
            end
            info.series = GetRandomString()
        else
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

            info.ammo = info.ammo or 0
            info.series = GetRandomString()
            info.attachments = {}
            info.tint = 0
        end
    end
    if itemData.type == 'bag' then
        info.series = GetRandomString()
        info.slot = itemData.slot
        info.weight = itemData.backpackweight or 0
    end
    if itemtype ~= nil and itemtype == "ammo" or not Config.DurabilityItems[itemData.name] then
        info = nil
    end
    return info
end


RegisterCommand('setmigrateweapon', function()
    local result = ExecuteSql("SELECT * FROM `codem_new_inventory`")
    for _, playerData in pairs(result) do
        local items = json.decode(playerData.inventory) or {}
        local citizenid = playerData.identifier
        local inventoryChanged = false

        for itemSlot, item in pairs(items) do
            local itemcheck = Config.Itemlist[item.name]
            if itemcheck and itemcheck.type == 'weapon' and not item.info then
                item.info = {
                    ammo = 0,
                    series = GetRandomString(10),
                    attachments = {},
                    tint = 0
                }
                inventoryChanged = true
                print('Migrating weapon: ' .. item.name .. ' for citizenid: ' .. citizenid)
            end
        end

        if inventoryChanged then
            local newInventoryJson = json.encode(items)
            local updateQuery = "UPDATE `codem_new_inventory` SET `inventory` = '" ..
                newInventoryJson .. "' WHERE `identifier` = '" .. citizenid .. "'"
            ExecuteSql(updateQuery)
        end
    end
    print("Weapon migration completed.")
end)
