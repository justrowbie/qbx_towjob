local config = require 'config.server'
local sharedConfig = require 'config.shared'
local Bail = {}

RegisterNetEvent('qb-tow:server:DoBail', function(bool, vehInfo)
    local Player = exports.qbx_core:GetPlayer(source)
    local paymentMethod

    if not bool then
        if not Bail[Player.PlayerData.citizenid] then return end
        Player.Functions.AddMoney('cash', Bail[Player.PlayerData.citizenid], "tow-bail-paid")
        Bail[Player.PlayerData.citizenid] = nil
        exports.qbx_core:Notify(source, locale("success.refund_to_cash", config.bailPrice), 'success')
        return
    end

    if Player.PlayerData.money.cash < config.bailPrice then
        if Player.PlayerData.money.bank < config.bailPrice then
            return exports.qbx_core:Notify(source, locale("error.no_deposit", config.bailPrice), 'error')
        end
        paymentMethod = 'bank'
        Player.Functions.RemoveMoney('bank', config.bailPrice, 'tow-received-bail')
        exports.qbx_core:Notify(source, locale("success.paid_with_" .. paymentMethod, config.bailPrice), 'success')
    else
        paymentMethod = 'cash'
        Player.Functions.RemoveMoney('cash', config.bailPrice, 'tow-received-bail')
        exports.qbx_core:Notify(source, locale("success.paid_with_" .. paymentMethod, config.bailPrice), 'success')
    end

    Bail[Player.PlayerData.citizenid] = config.bailPrice
    TriggerClientEvent('qb-tow:client:SpawnVehicle', source, vehInfo)
end)

RegisterNetEvent('qb-tow:server:PaySlip', function(drops)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if sharedConfig.usingJob then
        if Player.PlayerData.job.name ~= "tow" or #(playerCoords - vec3(sharedConfig.locations.main.coords.x, sharedConfig.locations.main.coords.y, sharedConfig.locations.main.coords.z)) > 6.0 then
            return DropPlayer(source, locale("info.skick"))
        end
    end

    if #(playerCoords - vec3(sharedConfig.locations.main.coords.x, sharedConfig.locations.main.coords.y, sharedConfig.locations.main.coords.z)) > 6.0 then
        return DropPlayer(source, locale("info.skick"))
    end

    drops = tonumber(drops)
    local bonus = 0
    local DropPrice = math.random(150, 170)
    if drops > 5 then
        if drops > 20 then drops = 20 end
        bonus = math.ceil((DropPrice / 10) * ((3 * (drops / 5)) + 2))
    end
    local price = (DropPrice * drops) + bonus
    local taxAmount = math.ceil((price / 100) * config.paymentTax)
    local payment = price - taxAmount

    -- Player.Functions.AddJobReputation(1)
    Player.Functions.AddMoney("bank", payment, "tow-salary")
    exports.qbx_core:Notify(source, locale("success.you_earned", payment), 'success')
end)

RegisterNetEvent('qb-tow:server:PayFare', function(fare)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if sharedConfig.usingJob then
        if Player.PlayerData.job.name ~= "tow" or #(playerCoords - vec3(sharedConfig.locations.dropoff.coords.x, sharedConfig.locations.dropoff.coords.y, sharedConfig.locations.dropoff.coords.z)) > 6.0 then
            return DropPlayer(source, locale("info.skick"))
        end
    end

    if #(playerCoords - vec3(sharedConfig.locations.dropoff.coords.x, sharedConfig.locations.dropoff.coords.y, sharedConfig.locations.dropoff.coords.z)) > 6.0 then
        return DropPlayer(source, locale("info.skick"))
    end

    local amount = math.ceil(fare * config.farePaymentMultiplier)
    Player.Functions.AddMoney("cash", amount, "tow-salary")
    exports.qbx_core:Notify(source, locale("success.you_earned", amount), 'success')
end)

lib.addCommand('npc', {
    help = locale("info.toggle_npc"),
}, function(source)
    TriggerClientEvent("jobs:client:ToggleNpc", source)
end)

lib.addCommand('tow', {
    help = locale("info.tow"),
}, function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if sharedConfig.usingJob then
        if Player.PlayerData.job.name ~= "tow" and Player.PlayerData.job.name ~= "mechanic" then return end
        TriggerClientEvent("qb-tow:client:TowVehicle", source)
    else
        TriggerClientEvent("qb-tow:client:TowVehicle", source)
    end
end)

lib.callback.register('qb-tow:server:spawnVehicle', function(source, model, coords, warp)
    local warpPed = warp and GetPlayerPed(source)
    local netId = qbx.spawnVehicle({model = model, spawnSource = coords, warp = warpPed})
    if not netId or netId == 0 then return end
    return netId
end)
