-- Throwable Weapons System
-- Check if system is enabled
if not Config.ThrowablesSystem then
    return
end

-- Variables
throwingWeapon = nil

-- Convert rotation to direction vector
function GetDirectionFromRotation(rotation)
    local radiansPerDegree = math.pi / 180

    local x = -math.sin(rotation.z * radiansPerDegree) * math.abs(math.cos(rotation.x * radiansPerDegree))
    local y = math.cos(rotation.z * radiansPerDegree) * math.abs(math.cos(rotation.x * radiansPerDegree))
    local z = math.sin(rotation.x * radiansPerDegree)

    return vector3(x, y, z)
end

-- Apply physics to thrown object
function PerformPhysics(entity)
    local throwForce = 25

    FreezeEntityPosition(entity, false)

    local ped = PlayerPedId()
    local camRotation = GetGameplayCamRot(2)
    local direction = GetDirectionFromRotation(camRotation)

    -- Set entity heading
    SetEntityHeading(entity, camRotation.z + 90.0)

    -- Apply velocity
    SetEntityVelocity(
        entity,
        direction.x * throwForce,
        direction.y * throwForce,
        direction.z * throwForce
    )
end

-- Get weapon name from hash
function GetWeaponString(weaponHash)
    for i = 1, #Config.WeaponsThrow do
        local weaponName = Config.WeaponsThrow[i]
        if weaponHash == GetHashKey(weaponName) then
            return weaponName
        end
    end
    return nil
end

-- Main throw weapon function
function ThrowCurrentWeapon()
    if throwingWeapon then
        return
    end

    local ped = PlayerPedId()
    local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
    local weaponName = GetWeaponString(weaponHash)

    if not hasWeapon or not weaponName then
        return
    end

    throwingWeapon = true

    -- Play throw animation
    CreateThread(function()
        PlayAnim(
            ped,
            "weapons@projectile@grenade_str",
            "throw_h_fb_backward",
            8.0,
            -8.0,
            -1,
            0
        )
        Wait(600)
        ClearPedTasks(ped)
    end)

    Wait(550)

    -- Get position in front of player
    local throwPosition = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 1.0)

    -- Get weapon object
    local weaponObject = GetWeaponObjectFromPed(ped, true)
    local weaponModel = GetEntityModel(weaponObject)

    -- Remove weapon from player
    RemoveWeaponFromPed(ped, weaponHash)
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
    DeleteEntity(weaponObject)

    -- Create prop at throw position
    local prop = CreateProp(
        weaponModel,
        throwPosition.x,
        throwPosition.y,
        throwPosition.z,
        true,
        false,
        true
    )

    -- Position and orient the prop
    SetEntityCoords(prop, throwPosition.x, throwPosition.y, throwPosition.z)
    SetEntityHeading(prop, GetEntityHeading(ped) + 90.0)

    -- Apply physics
    PerformPhysics(prop)

    -- Store weapon data and trigger server event
    local weaponData = ClientWeaponData
    TriggerServerEvent("codem-inventory:removeWeaponItem", weaponData)
    ClientWeaponData = nil

    -- Wait for weapon to land
    Citizen.Wait(4000)

    -- Get final position and notify server
    local finalPosition = GetEntityCoords(prop)
    TriggerServerEvent("codem-inventory:server:throwweapon", weaponData, finalPosition, prop)

    throwingWeapon = nil
end

-- Register keybind and command
Citizen.CreateThread(function()
    -- Register key mapping
    RegisterKeyMapping(
        "throwweapon",
        "Throw Weapon",
        "keyboard",
        Config.KeyBinds.ThrowWeapon
    )

    -- Register command
    RegisterCommand("throwweapon", function()
        local ped = PlayerPedId()
        local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
        local weaponName = GetWeaponString(weaponHash)

        if not hasWeapon or not weaponName then
            return
        end

        ThrowCurrentWeapon()
    end)
end)

-- Helper function to create props
function CreateProp(model, ...)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(0)
    end

    local prop = CreateObject(model, ...)
    SetModelAsNoLongerNeeded(model)

    return prop
end

-- Helper function to play animations
function PlayAnim(ped, animDict, ...)
    RequestAnimDict(animDict)

    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

    TaskPlayAnim(ped, animDict, ...)
end
