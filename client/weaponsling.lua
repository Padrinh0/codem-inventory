-- Weapon Sling System
-- Allows players to carry weapons on their back/front

-- Check if system is enabled
if not Config.SlingWeapon then
    return
end

-- Variables
local attachedWeapons = {}
local hotbarItems = {}
local slingPosition = "Back"

-- Main thread to manage weapon attachments
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local weaponFound = false

        if ClientInventory ~= nil then
            -- Get hotbar items (slots 1-5)
            hotbarItems = {
                [1] = ClientInventory["1"],
                [2] = ClientInventory["2"],
                [3] = ClientInventory["3"],
                [4] = ClientInventory["4"],
                [5] = ClientInventory["5"]
            }

            -- Check each hotbar slot for weapons
            for slot, item in pairs(hotbarItems) do
                if item ~= nil and item.type == "weapon" then
                    local weaponConfig = Config.WeaponSling.compatable_weapon_hashes[item.name]

                    if weaponConfig ~= nil then
                        -- Check if weapon is already attached
                        for _, attachedWeapon in pairs(attachedWeapons) do
                            if attachedWeapon then
                                weaponFound = true
                            end
                        end

                        -- Attach weapon if not already attached
                        if not weaponFound then
                            local weaponModel = weaponConfig.model
                            local weaponHash = weaponConfig.hash

                            if not attachedWeapons[weaponModel] then
                                local currentWeapon = GetSelectedPedWeapon(ped)

                                -- Only attach if weapon is not currently equipped
                                if currentWeapon ~= weaponHash then
                                    local pos = Config.WeaponSling.Positions[slingPosition]

                                    AttachWeapon(
                                        weaponModel,
                                        weaponHash,
                                        pos.bone,
                                        pos.x,
                                        pos.y,
                                        pos.z,
                                        pos.x_rotation,
                                        pos.y_rotation,
                                        pos.z_rotation
                                    )
                                end
                            end
                        end
                    end
                end
            end

            -- Remove weapons that are no longer in hotbar or are equipped
            for model, weaponData in pairs(attachedWeapons) do
                local currentWeapon = GetSelectedPedWeapon(ped)

                -- Remove if weapon is equipped or not in hotbar
                if currentWeapon ~= weaponData.hash then
                    if not inHotbar(weaponData.hash) then
                        DeleteObject(weaponData.handle)
                        attachedWeapons[model] = nil
                    end
                else
                    -- Remove if currently equipped
                    DeleteObject(weaponData.handle)
                    attachedWeapons[model] = nil
                end
            end
        end

        Wait(1500)
    end
end)

-- Check if weapon is in hotbar
function inHotbar(weaponHash)
    for slot, item in pairs(hotbarItems) do
        if item ~= nil and item.type == "weapon" then
            local weaponConfig = Config.WeaponSling.compatable_weapon_hashes[item.name]

            if weaponConfig ~= nil then
                local itemHash = GetHashKey(item.name)
                if weaponHash == itemHash then
                    return true
                end
            end
        end
    end

    return false
end

-- Attach weapon to player
function AttachWeapon(model, hash, bone, x, y, z, xRot, yRot, zRot)
    local ped = PlayerPedId()
    local boneIndex = GetPedBoneIndex(ped, bone)

    -- Request model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end

    -- Create weapon object
    local weaponObject = CreateObject(
        GetHashKey(model),
        1.0, 1.0, 1.0,
        true, true, false
    )

    -- Store weapon data
    attachedWeapons[model] = {
        hash = hash,
        handle = weaponObject
    }

    -- Attach to player
    AttachEntityToEntity(
        weaponObject,
        ped,
        boneIndex,
        x, y, z,
        xRot, yRot, zRot,
        1, 1, 0, 0, 2, 1
    )
end

-- Command to toggle weapon position (back/front)
RegisterCommand(Config.Commands.slingweapon, function()
    if slingPosition == "Back" then
        slingPosition = "Front"

        -- Remove all attached weapons
        for model, weaponData in pairs(attachedWeapons) do
            DeleteObject(weaponData.handle)
            attachedWeapons[model] = nil
        end
    else
        slingPosition = "Back"

        -- Remove all attached weapons
        for model, weaponData in pairs(attachedWeapons) do
            DeleteObject(weaponData.handle)
            attachedWeapons[model] = nil
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local ped = PlayerPedId()

        -- Remove all attached weapons
        for model, weaponData in pairs(attachedWeapons) do
            DeleteObject(weaponData.handle)
            attachedWeapons[model] = nil
        end

        -- Clean up ground items
        for dropId, drop in pairs(ClientGround) do
            if drop.inventory then
                for slot, item in pairs(drop.inventory) do
                    if item.object then
                        DeleteObject(item.object)
                    end
                end
            end
        end
    end
end)
