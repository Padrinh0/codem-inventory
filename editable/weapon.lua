currentWeapon = nil
ClientWeaponData = {}
canShoot = false
local anims = {}
anims[`GROUP_MELEE`] = anims[`GROUP_PISTOL`]
anims[`GROUP_PISTOL`] = { 'reaction@intimidation@cop@unarmed', 'intro', 400, 'reaction@intimidation@cop@unarmed', 'outro', 450 }
anims[`GROUP_STUNGUN`] = anims[`GROUP_PISTOL`]
anims[`GROUP_SMG`] = { 'reaction@intimidation@cop@unarmed', 'intro', 400, 'reaction@intimidation@cop@unarmed', 'outro', 450 }
anims[`GROUP_RIFLE`] = { 'reaction@intimidation@cop@unarmed', 'intro', 400, 'reaction@intimidation@cop@unarmed', 'outro', 450 }

local holsterJob = {
    ['police'] = true,
    ['sheriff'] = true
}

local noanimweapon = {
    ['weapon_switchblade'] = true
}

local changeWeaponCooldown = 3000
local busy = false
RegisterNetEvent('codem-inventory:client:UseWeapon', function(weaponData, shootbool)
    if busy then return end
    busy = true
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    local weaponHash = joaat(weaponData.name)
    if Config.Throwables[weaponName] then
        if weaponName == 'weapon_stickybomb' or weaponName == 'weapon_pipebomb' or weaponName == 'weapon_snowball' or weaponName == 'weapon_smokegrenade' or weaponName == 'weapon_flare' or weaponName == 'weapon_proxmine' or weaponName == 'weapon_ball' or weaponName == 'weapon_molotov' or weaponName == 'weapon_grenade' or weaponName == 'weapon_bzgas' then
            GiveWeaponToPed(ped, weaponHash, 1, false, false)
            SetPedAmmo(ped, weaponHash, 1)
            SetCurrentPedWeapon(ped, weaponHash, true)
            currentWeapon = weaponName
        end
        -- if weaponName == 'weapon_snowball' then
        --     GiveWeaponToPed(ped, weaponHash, 10, false, false)
        --     SetPedAmmo(ped, weaponHash, 10)
        --     SetCurrentPedWeapon(ped, weaponHash, true)
        --     currentWeapon = weaponName
        -- end
        Citizen.Wait(changeWeaponCooldown)
        busy = false
        return
    end
    if currentWeapon == weaponName then
        if noanimweapon[weaponName] then
            RemoveAllPedWeapons(ped, true)
            currentWeapon = nil
            ClientWeaponData = {}
            busy = false
            return
        end
        local coords = GetEntityCoords(ped, true)
        local anim = anims[GetWeapontypeGroup(weaponHash)]
        local holster = jobData.name and holsterJob[jobData.name:lower()]
        if anim == anims[`GROUP_PISTOL`] and not holster then
            anim = nil
        end
        if anim == anims[`GROUP_SMG`] and not holster then
            anim = nil
        end
        if anim == anims[`GROUP_RIFLE`] and not holster then
            anim = nil
        end
        local sleep = anim and anim[6] or 1400

        PlayAnimAdvanced(sleep, anim and anim[4] or 'reaction@intimidation@1h', anim and anim[5] or 'outro',
            coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(ped), 8.0, 3.0, sleep, 50, 0)
        RemoveAllPedWeapons(ped, true)
        currentWeapon = nil
        ClientWeaponData = {}
        NuiMessage('SHOW_BOTTOM_MENU', {
            value = 'weapononbehind',
            image = weaponData.image,
            text = Locales[Config.Language].notification['ONBEHIND']
        })
        Citizen.Wait(changeWeaponCooldown)
        busy = false
    else
        if noanimweapon[weaponName] then
            GiveWeaponToPed(ped, weaponHash, 0, false, false)
            SetCurrentPedWeapon(ped, weaponHash, true)
            currentWeapon = weaponName
            ClientWeaponData = weaponData
            busy = false
            return
        end

        if currentWeapon then
            local coords = GetEntityCoords(ped, true)
            local anim = anims[GetWeapontypeGroup(weaponHash)]
            local holster = jobData.name and holsterJob[jobData.name:lower()]
            if anim == anims[`GROUP_PISTOL`] and not holster then
                anim = nil
            end
            if anim == anims[`GROUP_SMG`] and not holster then
                anim = nil
            end
            if anim == anims[`GROUP_RIFLE`] and not holster then
                anim = nil
            end

            local sleep = anim and anim[6] or 1400

            PlayAnimAdvanced(sleep, anim and anim[4] or 'reaction@intimidation@1h', anim and anim[5] or 'outro',
                coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(ped), 8.0, 3.0, sleep, 50, 0)
        end
        local ammo = tonumber(weaponData.info.ammo) or 0
        if weaponName == 'weapon_petrolcan' or weaponName == 'weapon_fireextinguisher' then
            ammo = 4000
        end
        GiveWeaponToPed(ped, weaponHash, ammo, false, false)
        SetPedAmmo(ped, weaponHash, ammo)
        SetPedCurrentWeaponVisible(ped, true, false, false, false)
        SetCurrentPedWeapon(ped, weaponHash, true)

        if weaponData.info.attachments then
            for _, attachment in pairs(weaponData.info.attachments) do
                GiveWeaponComponentToPed(ped, weaponHash, joaat(attachment.component))
            end
        end

        if weaponData.info.tint then
            SetPedWeaponTintIndex(ped, weaponHash, weaponData.info.tint)
        end
        NuiMessage('SHOW_BOTTOM_MENU', {
            value = 'weapononhand',
            image = weaponData.image,
            text = Locales[Config.Language].notification['ONHAND']
        })
        currentWeapon = weaponName
        ClientWeaponData = weaponData
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed, true)
        local anim = anims[GetWeapontypeGroup(weaponHash)]
        local holster = jobData.name and holsterJob[jobData.name:lower()]
        if anim == anims[`GROUP_PISTOL`] and not holster then
            anim = nil
        end
        if anim == anims[`GROUP_SMG`] and not holster then
            anim = nil
        end
        if anim == anims[`GROUP_RIFLE`] and not holster then
            anim = nil
        end
        local sleep = anim and anim[3] or 1200
        PlayAnimAdvanced(sleep, anim and anim[1] or 'reaction@intimidation@1h', anim and anim[2] or 'intro',
            coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(playerPed), 8.0, 3.0, sleep * 2, 50, 0.1)
        Citizen.Wait(changeWeaponCooldown)
        busy = false
    end
end)

function PlayAnimAdvanced(wait, dict, name, posX, posY, posZ, rotX, rotY, rotZ, blendIn, blendOut, duration, flag, time)
    LoadAnimDict(dict)
    TaskPlayAnimAdvanced(PlayerPedId(), dict, name, posX, posY, posZ, rotX, rotY, rotZ, blendIn, blendOut, duration, flag,
        time, 0, 0)
    RemoveAnimDict(dict)

    if wait > 0 then Wait(wait) end
end

RegisterNetEvent('codem-inventory:RemoveWeaponsAttachments', function(weaponData, attachmentData)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weaponData.name)
    if HasPedGotWeapon(ped, weaponHash, false) then
        RemoveWeaponComponentFromPed(ped, weaponHash, attachmentData)
        if ClientWeaponData.name == weaponData.name then
            if ClientWeaponData.info.attachments then
                for i = 1, #ClientWeaponData.info.attachments do
                    if ClientWeaponData.info.attachments[i].component == attachmentData then
                        table.remove(ClientWeaponData.info.attachments, i)
                        break
                    end
                end
            end
        end
    else
        print('The ped does not have the weapon.')
    end
end)


RegisterNetEvent('codem-inventory:client:CheckWeapon', function(weaponName)
    if currentWeapon ~= weaponName:lower() then return end
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    RemoveAllPedWeapons(ped, true)
    currentWeapon = nil
end)

RegisterNetEvent('codem-inventory:client:RemoveWeaponObject', function()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    RemoveAllPedWeapons(ped, true)
    ClientWeaponData = {}
    currentWeapon = nil
end)

RegisterNetEvent('codem-inventory:refreshweaponattachment', function(item)
    if ClientWeaponData then
        if ClientWeaponData.name == item.name then
            ClientWeaponData.info = item.info
        end
    end
end)

RegisterNetEvent('codem-inventory:useattachment', function(item)
    if ClientWeaponData.slot then
        TriggerServerEvent('codem-inventory:server:useattachment', item, ClientWeaponData)
    else
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['WRONGAMMO'])
    end
end)

RegisterNetEvent('codem-inventory:client:useweapontint', function(tintindex, itemname, tint)
    if ClientWeaponData.slot then
        TriggerServerEvent('codem-inventory:server:useweapontint', tintindex, itemname, tint, ClientWeaponData)
    else
        TriggerEvent('codem-inventory:client:notification',
            Locales[Config.Language].notification['WRONGAMMO'])
    end
end)

RegisterNetEvent('codem-inventory:refreshWeaponAttachment', function(slot, attachmentData)
    if ClientWeaponData.slot then
        if tostring(ClientWeaponData.slot) == tostring(slot) then
            if not ClientWeaponData.info then
                ClientWeaponData.info = {}
            end
            ClientWeaponData.info = attachmentData
        end
    end
end)

---------------------------------------------------------------


RegisterNetEvent('weapons:client:EquipTint', function(weapon, tint)
    local player = PlayerPedId()
    SetPedWeaponTintIndex(player, weapon, tint)
end)


local lastShotTime = 0
local shotCooldown = 500

local throwWeapons = {
    [GetHashKey('weapon_stickybomb')] = true,
    [GetHashKey('weapon_pipebomb')] = true,
    [GetHashKey('weapon_smokegrenade')] = true,
    [GetHashKey('weapon_flare')] = true,
    [GetHashKey('weapon_proxmine')] = true,
    [GetHashKey('weapon_ball')] = true,
    [GetHashKey('weapon_molotov')] = true,
    [GetHashKey('weapon_grenade')] = true,
    [GetHashKey('weapon_bzgas')] = true
}

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local wait = 500
        local isArmed = IsPedArmed(ped, 7) == 1
        if isArmed then
            wait = 0
            local canshoot = IsPedShooting(ped)
            local weapon = GetSelectedPedWeapon(ped)
            if throwWeapons[weapon] then
                if (IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24)) then
                    Citizen.Wait(1000)
                    TriggerServerEvent('codem-inventory:removethrowableitem', currentWeapon)
                end
            end
            if canshoot then
                local ammo = GetAmmoInPedWeapon(ped, weapon)
                local selectWeaponHash = GetHashKey(ClientWeaponData.name)
                local currentTime = GetGameTimer()
                if weapon == selectWeaponHash and (currentTime - lastShotTime) > shotCooldown then
                    lastShotTime = currentTime
                    if ClientWeaponData.slot and ClientWeaponData.info.ammo > 0 then
                        TriggerServerEvent('codem-inventory:server:UpdateWeaponAmmo', ClientWeaponData.slot,
                            tonumber(ammo))
                        if ClientWeaponData.info and ClientWeaponData.info.ammo then
                            ClientWeaponData.info.ammo = ClientWeaponData.info.ammo - 1
                        end
                        if ClientWeaponData.info.quality and ClientWeaponData.info.quality > 0 then
                            if ClientWeaponData.info.decay == 'use' then
                                ClientWeaponData.info.quality = ClientWeaponData.info.quality -
                                    (ClientWeaponData.info.durability or 0)
                                ClientInventory[tostring(ClientWeaponData.slot)].info = ClientWeaponData.info
                            end
                        end
                    end
                end
                if ammo == 0 then
                    TriggerServerEvent('codem-inventory:server:UpdateWeaponAmmo', ClientWeaponData.slot, tonumber(ammo))
                    if ClientWeaponData.info and ClientWeaponData.info.ammo then
                        ClientWeaponData.info.ammo = 0
                    end
                    if ClientWeaponData.info.quality and ClientWeaponData.info.quality > 0 then
                        if ClientWeaponData.info.decay == 'use' then
                            ClientWeaponData.info.quality = ClientWeaponData.info.quality -
                                (ClientWeaponData.info.durability or 0)
                            ClientInventory[tostring(ClientWeaponData.slot)].info = ClientWeaponData.info
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)




RegisterNetEvent('weapons:client:AddAmmo', function(type, amount, itemData)
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if ClientWeaponData then
        if type == ClientWeaponData.ammotype then
            local total = GetAmmoInPedWeapon(ped, weapon)
            local _, maxAmmo = GetMaxAmmo(ped, weapon)
            if total < maxAmmo then
                Progressbar('taking_bullets', 'Loading Bullets', 2500,
                    false,
                    true, {
                        disableMovement = false,
                        disableCarMovement = false,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function()
                        if ClientWeaponData and ClientWeaponData.slot then
                            AddAmmoToPed(ped, weapon, amount)
                            TaskReloadWeapon(ped)
                            TriggerServerEvent('codem-inventory:server:removeWeaponAmmo', itemData, amount,
                                ClientWeaponData.slot)
                            if ClientWeaponData.info and ClientWeaponData.info.ammo then
                                ClientWeaponData.info.ammo = ClientWeaponData.info.ammo + amount
                            end
                        end
                    end, function()
                        TriggerEvent('codem-inventory:client:notification',
                            Locales[Config.Language].notification['cancelled_prog'])
                    end)
            else
                TriggerEvent('codem-inventory:client:notification',
                    Locales[Config.Language].notification['MAXAMMO'])
            end
        else
            TriggerEvent('codem-inventory:client:notification',
                Locales[Config.Language].notification['WRONGAMMO'])
        end
    end
end)

CreateThread(function()
    SetWeaponsNoAutoswap(true)
end)

Citizen.CreateThread(function()
    RegisterKeyMapping('reloadammo', 'Reload Ammo', 'keyboard', 'R')
    RegisterCommand("reloadammo", function()
        if not CanAccesInventory() then return end
        if ClientWeaponData and ClientWeaponData.slot then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            local total = GetAmmoInPedWeapon(ped, weapon)
            local _, maxAmmo = GetMaxAmmo(ped, weapon)
            if total < maxAmmo then
                TriggerServerEvent('codem-inventory:reloadammopressr', ClientWeaponData)
            else
                TriggerEvent('codem-inventory:client:notification',
                    Locales[Config.Language].notification['MAXAMMO'])
            end
        end
    end)
end)


RegisterNetEvent('codem-inventory:client:removeWeaponPlayerHands', function()
    if ClientWeaponData and ClientWeaponData.slot then
        TriggerServerEvent('codem-inventory:server:removeWeaponHands', ClientWeaponData)
    end
end)
