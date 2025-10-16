lastHunger = nil
lastThirst = nil
function SetStatus(type, value)
    NuiMessage("SET_STATUS", {
        type = type,
        value = value,
    })
end

lastHealth = nil
CreateThread(function()
    LoadPlayerInformations()
    while true do
        local playerPed = PlayerPedId()
        local health = GetEntityHealth(playerPed)
        if lastHealth == nil or lastHealth ~= health then
            local val = health - 100
            SetStatus('health', val)
            lastHealth = health
            if lastHealth <= 0 then
                TriggerEvent('codem-inventory:client:closeInventory')
                if Config.DiePlayerRemoveHandsWeaponItem then
                    TriggerEvent('codem-inventory:client:removeWeaponPlayerHands')
                end
            end
        end
        Wait(1600)
    end
end)
function LoadPlayerInformations()
    while Core == nil and not PlayerLoaded do
        Wait(0)
    end
    CreateThread(function()
        local cash = 0
        local bank = 0
        if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
            while Core.GetPlayerData() == nil and Core.GetPlayerData().accounts == nil do
                Wait(0)
            end
            Wait(1000)
            local PlayerData = Core.GetPlayerData()
            if next(PlayerData) == nil then
            else
                local esxCash = TriggerCallback("codem-inventory:GetESXCash")
                local esxBank = TriggerCallback("codem-inventory:GetESXBank")
                bank = esxBank
                cash = esxCash
            end
        else
            while Core.Functions.GetPlayerData() == nil do
                Wait(0)
            end
            local PlayerData = Core.Functions.GetPlayerData()
            if next(PlayerData) == nil then
            else
                cash = PlayerData["money"].cash or 0
                bank = PlayerData["money"].bank or 0
            end
        end
        SetStatus("cash", cash)
        SetStatus("bank", bank)
    end)
end

local lastArmor = nil
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local armor = GetPedArmour(playerPed)
        if not lastArmor or lastArmor ~= armor then
            local val = armor
            SetStatus('armor', val)
            lastArmor = armor
        end
        Wait(1600)
    end
end)
local lastStamina = nil
CreateThread(function()
    while true do
        local value = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
        if lastStamina == nil or lastStamina ~= value then
            SetStatus('stamina', value)
            lastStamina = value
        end
        Wait(1600)
    end
end)

RegisterNetEvent("QBCore:Player:SetPlayerData")
AddEventHandler("QBCore:Player:SetPlayerData", function(data)
    SetStatus("cash", data.money.cash)
    SetStatus("bank", data.money.bank)
end)


RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    if account.name == 'money' then
        account.name = 'cash'
    end
    SetStatus(account.name, account.money)
end)

RegisterNetEvent("es:removedMoney")
AddEventHandler("es:removedMoney", function(a, b, m)
    Wait(1500)
    local PlayerData = Core.GetPlayerData()
    for _, v in pairs(PlayerData.accounts) do
        if v.name == 'bank' then
            SetStatus("bank", v.money)
        end
        if v.name == 'money' then
            SetStatus("cash", v.money)
        end
    end
end)


RegisterNetEvent("es:addedMoney")
AddEventHandler("es:addedMoney", function(a, b, m)
    Wait(1500)
    local PlayerData = Core.GetPlayerData()
    for _, v in pairs(PlayerData.accounts) do
        if v.name == 'bank' then
            SetStatus("bank", v.money)
        end
        if v.name == 'money' then
            SetStatus("cash", v.money)
        end
    end
end)

CreateThread(function()
    while true do
        while Core == nil and not PlayerLoaded do
            Wait(0)
        end
        if Config.Framework == "esx" or Config.Framework == "oldesx" then
            TriggerEvent('esx_status:getStatus', 'hunger', function(hunger)
                TriggerEvent('esx_status:getStatus', 'thirst', function(thirst)
                    local hunger = hunger.getPercent()
                    local thirst = thirst.getPercent()
                    if lastHunger == nil or hunger ~= lastHunger then
                        SetStatus('hunger', hunger)
                        lastHunger = hunger
                    end
                    if lastThirst == nil or thirst ~= lastThirst then
                        SetStatus('thirst', thirst)
                        lastThirst = thirst
                    end
                end)
            end)
        else
            while Core.Functions.GetPlayerData() == nil and Core.Functions.GetPlayerData().metadata == nil do
                Wait(0)
            end
            local PlayerData = Core.Functions.GetPlayerData()
            if next(PlayerData) == nil then

            else
                local hunger = PlayerData.metadata["hunger"]
                local thirst = PlayerData.metadata["thirst"]
                if lastHunger == nil or hunger ~= lastHunger then
                    SetStatus('hunger', hunger)
                    lastHunger = hunger
                end
                if lastThirst == nil or thirst ~= lastThirst then
                    SetStatus('thirst', thirst)
                    lastThirst = thirst
                end
            end
        end
        Wait(6000)
    end
end)
