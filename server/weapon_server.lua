RegisterServerEvent('codem-inventory:server:removeWeaponAmmo', function(data, amount, weaponslot)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        print('identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    data.slot = tostring(data.slot)
    weaponslot = tostring(weaponslot)
    local itemData = playerInventory[data.slot]
    local weaponData = playerInventory[weaponslot]
    if not itemData and not weaponData and not weaponData.info then
        TriggerClientEvent('codem-inventory:client:notification', src, 'item or item info not found')
        return
    end
    if RemoveItem(src, itemData.name, 1, itemData.slot) then
        weaponData.info.ammo = weaponData.info.ammo + amount
        TriggerClientEvent('codem-inventory:refreshItemsDurability', src, weaponData.slot, weaponData)
        SetInventory(src)
    else
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUND'])
    end
end)


RegisterServerEvent('codem-inventory:server:UpdateWeaponAmmo', function(item, ammo)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        print('identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not item and type(item) == "[]" then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUND'])
    end
    local itemData = playerInventory[tostring(item)]
    if not itemData and not itemData.info then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUNDORINFONOTFOUND'])
        return
    end

    if tonumber(itemData.info.ammo) <= 0 then
        return
    else
        itemData.info.ammo = ammo
        if Config.DurabilitySystem then
            if itemData.info.quality then
                if itemData.info.decay == 'use' then
                    if itemData.info.quality > 0 then
                        itemData.info.quality = itemData.info.quality - itemData.info.durability
                    else
                        itemData.info.quality = 0
                    end
                end
            end
        end
        SetInventory(src)
    end
end)



RegisterServerEvent('weapons:server:RemoveAttachment', function(AttachmentData)
    local src = tonumber(source)
    local allAttachments = WeaponAttachments
    local currentItem = GetItemBySlot(src, AttachmentData.item.slot)
    local AttachmentComponent = allAttachments[AttachmentData.attachment.itemname][currentItem.name]
    if not currentItem then
        return
    end
    local HasAttach, key = HasAttachment(AttachmentComponent, currentItem.info.attachments)
    if HasAttach then
        table.remove(currentItem.info.attachments, key)
        TriggerClientEvent('codem-inventory:RemoveWeaponsAttachments', src, currentItem, AttachmentComponent)
        SetItemBySlot(src, AttachmentData.item.slot, currentItem)
        AddItem(src, AttachmentData.attachment.itemname, 1)
    end
end)




local AmmoTypes = {
    { item = 'pistol_ammo',  ammoType = 'AMMO_PISTOL',      amount = 12 },
    { item = 'rifle_ammo',   ammoType = 'AMMO_RIFLE',       amount = 30 },
    { item = 'smg_ammo',     ammoType = 'AMMO_SMG',         amount = 20 },
    { item = 'shotgun_ammo', ammoType = 'AMMO_SHOTGUN',     amount = 10 },
    { item = 'mg_ammo',      ammoType = 'AMMO_MG',          amount = 30 },
    { item = 'snp_ammo',     ammoType = 'AMMO_SNIPER',      amount = 10 },
    { item = 'emp_ammo',     ammoType = 'AMMO_EMPLAUNCHER', amount = 10 },
}

local function registerUseableItems(ammoList)
    for _, ammo in ipairs(ammoList) do
        if Config.Framework == 'qb' or Config.Framework == 'oldqb' then
            Core.Functions.CreateUseableItem(ammo.item, function(source, item)
                TriggerClientEvent('weapons:client:AddAmmo', source, ammo.ammoType, ammo.amount, item)
            end)
        elseif Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            Core.RegisterUsableItem(ammo.item, function(source, itemname, item)
                TriggerClientEvent('weapons:client:AddAmmo', source, ammo.ammoType, ammo.amount, item)
            end)
        end
    end
end


Citizen.CreateThread(function()
    while Core == nil do
        Citizen.Wait(1)
    end
    RegisterCallback('weapons:server:GetConfig', function(_, cb)
        cb(Config.WeaponRepairPoints)
    end)

    registerUseableItems(AmmoTypes)


    for i = 0, 7 do
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            Core.RegisterUsableItem('weapontint_' .. i, function(source, itemname, item)
                TriggerClientEvent('codem-inventory:client:useweapontint', source, i, item.name, false)
            end)
        else
            Core.Functions.CreateUseableItem('weapontint_' .. i, function(source, item)
                TriggerClientEvent('codem-inventory:client:useweapontint', source, i, item.name, false)
            end)
        end
    end
    for i = 0, 32 do
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            Core.RegisterUsableItem('weapontint_mk2_' .. i, function(source, itemname, item)
                TriggerClientEvent('codem-inventory:client:useweapontint', source, i, item.name, true)
            end)
        else
            Core.Functions.CreateUseableItem('weapontint_mk2_' .. i, function(source, item)
                TriggerClientEvent('codem-inventory:client:useweapontint', source, i, item.name, true)
            end)
        end
    end
    for attachmentItem in pairs(WeaponAttachments) do
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            Core.RegisterUsableItem(attachmentItem, function(source, itemname, item)
                TriggerClientEvent('codem-inventory:useattachment', source, item)
            end)
        else
            Core.Functions.CreateUseableItem(attachmentItem, function(source, item)
                TriggerClientEvent('codem-inventory:useattachment', source, item)
            end)
        end
    end
end)
function GetWeaponSlotByName(source, weaponName)
    local identifier = Identifier[source]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', source,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end
    local playerInventory = PlayerServerInventory[identifier] and PlayerServerInventory[identifier].inventory
    if not playerInventory then
        TriggerClientEvent('codem-inventory:client:notification', source,
            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
        debugprint('DİKKAT ENVANTER BULUNAMADI 700 SATIR')
        return
    end
    for index, item in pairs(playerInventory) do
        if item.name == weaponName then
            return item, index
        end
    end
    return nil, nil
end

RegisterServerEvent('codem-inventory:server:useattachment', function(attachment, ClientWeaponData)
    local src = source
    EquipWeaponAttachment(src, attachment, ClientWeaponData)
end)


function EquipWeaponAttachment(src, item, ClientWeaponData)
    local shouldRemove = false
    local ped = GetPlayerPed(src)
    local selectedWeaponHash = GetSelectedPedWeapon(ped)
    if selectedWeaponHash == `WEAPON_UNARMED` then return end
    local weaponName = SharedWeaponsfunc(selectedWeaponHash)
    if not weaponName then return end
    local attachmentComponent = DoesWeaponTakeWeaponComponent(item.name, weaponName.name)
    if not attachmentComponent then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['SELECTEDWEAPON'])
        return
    end
    local Player = GetPlayer(src)
    if not Player then return end
    local weaponSlot, weaponSlotIndex = ClientWeaponData, ClientWeaponData.slot
    if not weaponSlot then return end
    weaponSlot.info.attachments = weaponSlot.info.attachments or {}
    local hasAttach, attachIndex = HasAttachment(attachmentComponent, weaponSlot.info.attachments)
    print(hasAttach, attachIndex)
    if hasAttach then
        RemoveWeaponComponentFromPed(ped, selectedWeaponHash, attachmentComponent)
        -- AddItem(src, weaponSlot.info.attachments[attachIndex].itemname, 1, nil, nil)
        -- RemoveItem(src, item.name, 1)
        table.remove(weaponSlot.info.attachments, attachIndex)
        --AddItem(src, item.name, 1, nil, nil)
        TriggerClientEvent('codem-inventory:refreshweaponattachment', src, weaponSlot)
    else
        weaponSlot.info.attachments[#weaponSlot.info.attachments + 1] = {
            label = item.label,
            component = attachmentComponent,
            itemname = item.name
        }
        GiveWeaponComponentToPed(ped, selectedWeaponHash, attachmentComponent)
        shouldRemove = true
    end
    SetItemMetadata(src, weaponSlotIndex, weaponSlot.info)
    if shouldRemove then
        RemoveItem(src, item.name, 1)
    end
end

function HasAttachment(component, attachments)
    for k, v in pairs(attachments) do
        print(json.encode(v.component), json.encode(component))
        if v.component == component then
            return true, k
        end
    end
    return false, nil
end

function DoesWeaponTakeWeaponComponent(item, weaponName)
    if WeaponAttachments[item] and WeaponAttachments[item][weaponName] then
        return WeaponAttachments[item][weaponName]
    end
    return false
end

RegisterServerEvent('codem-inventory:server:removeTint', function(item)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    if not item.slot then return end
    local weapon = item.info
    if not weapon then return end
    local tintIndex = 'weapontint_' .. weapon.tint
    weapon.tint = 0
    AddItem(src, tintIndex, 1, nil, nil)
    local ped = GetPlayerPed(src)
    local selectedWeaponHash = GetSelectedPedWeapon(ped)
    if selectedWeaponHash then
        TriggerClientEvent('weapons:client:EquipTint', src, selectedWeaponHash, 0)
    end
    SetItemBySlot(src, item.slot, item)
end)

RegisterServerEvent('codem-inventory:server:useweapontint', function(tintIndex, item, isMK2, clientWeaponData)
    local src = source
    EquipWeaponTint(src, tintIndex, item, isMK2, clientWeaponData)
end)
local function IsMK2Weapon(weaponname)
    return string.find(weaponname, 'mk2') ~= nil
end

function EquipWeaponTint(source, tintIndex, item, isMK2, clientWeaponData)
    local Player = GetPlayer(source)
    if not Player then return end
    local ped = GetPlayerPed(source)
    local selectedWeaponHash = GetSelectedPedWeapon(ped)
    if selectedWeaponHash == `WEAPON_UNARMED` then
        TriggerClientEvent('codem-inventory:client:notification', source,
            Locales[Config.Language].notification['youhavenoweaponselected'])
        return
    end
    local weaponName = SharedWeaponsfunc(selectedWeaponHash)
    if not weaponName then return end
    if isMK2 and not IsMK2Weapon(clientWeaponData.name) then
        TriggerClientEvent('codem-inventory:client:notification', source,
            Locales[Config.Language].notification['onlymk2weapons'])
        return
    end
    local weaponSlot, weaponSlotIndex = clientWeaponData, clientWeaponData.slot
    if not weaponSlot then return end
    if weaponSlot.info.tint == tintIndex then
        TriggerClientEvent('codem-inventory:client:notification', source,
            Locales[Config.Language].notification['ALREADYWEAPONTINT'])
        return
    end
    if weaponSlot.info.tint > 0 then
        local tintItem = 'weapontint_' .. weaponSlot.info.tint
        AddItem(source, tintItem, 1, nil, nil)
    end
    weaponSlot.info.tint = tintIndex
    RemoveItem(source, item, 1)
    TriggerClientEvent('weapons:client:EquipTint', source, selectedWeaponHash, tintIndex)
    SetItemBySlot(source, weaponSlotIndex, weaponSlot)
end

RegisterServerEvent('codem-inventory:reloadammopressr', function(weapondata)
    local src = source
    local identifier = Identifier[src]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
        debugprint('DİKKAT ENVANTER BULUNAMADI 700 SATIR')
        return
    end
    local slot = tostring(weapondata.slot)
    local weaponItem = playerInventory[slot]
    if not weaponItem then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUND'])
        return
    end
    local weaponAmmoType = weaponItem.ammotype
    local selectAmmoType = nil
    for k, v in pairs(AmmoTypes) do
        if weaponAmmoType == v.ammoType then
            selectAmmoType = v
        end
    end

    if not selectAmmoType then
        TriggerClientEvent('codem-inventory:client:notification', src, 'Ammo type not found')
        return
    end
    local foundAmmo = false
    for k, v in pairs(playerInventory) do
        if v.name == selectAmmoType.item then
            foundAmmo = true
            TriggerClientEvent('weapons:client:AddAmmo', src, selectAmmoType.ammoType, selectAmmoType.amount, v)
            break
        end
    end
    if not foundAmmo then
        TriggerClientEvent('codem-inventory:client:notification', src, 'Ammo not found')
    end
end)


RegisterNetEvent('codem-inventory:server:removeWeaponHands', function(data)
    local src = tonumber(source)
    local identifier = Identifier[src]
    if not identifier then
        print('identifier not found')
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    data.slot = tostring(data.slot)
    local itemData = playerInventory[data.slot]
    if not itemData then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUND'])
        return
    end
    if RemoveItem(src, itemData.name, 1, itemData.slot) then
        local groundId = GenerateGroundId()
        local coords = GetEntityCoords(GetPlayerPed(src))
        itemData.object = nil
        ServerGround[groundId] = { inventory = { ["1"] = itemData }, coord = coords, id = groundId }
        itemData.slot = "1"
        itemData.amount = 1
        TriggerClientEvent('codem-inventory:client:SetGroundTable', -1, groundId, coords,
            ServerGround[groundId].inventory)
    else
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['ITEMNOTFOUND'])
    end
end)


RegisterServerEvent('codem-inventory:removethrowableitem', function(clientweapon)
    local src = source
    local identifier = Identifier[src]
    if not identifier then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['IDENTIFIERNOTFOUND'])
        return
    end
    local playerInventory = PlayerServerInventory[identifier].inventory
    if not playerInventory then
        TriggerClientEvent('codem-inventory:client:notification', src,
            Locales[Config.Language].notification['PLAYERINVENTORYNOTFOUND'])
        debugprint('DİKKAT ENVANTER BULUNAMADI 700 SATIR')
        return
    end

    for k, v in pairs(playerInventory) do
        if v.name == clientweapon then
            if RemoveItem(src, v.name, 1, v.slot) then
                TriggerClientEvent('codem-inventory:client:notification', src, 'Item removed')
            else
                TriggerClientEvent('codem-inventory:client:notification', src, 'Item not found')
            end
            break
        end
    end
end)
