QBCore = nil

local function InitializeFrameworkDependentComponents()
    QBCore = exports['qb-core']:GetCoreObject()
end

CreateThread(function()
    InitializeFrameworkDependentComponents()
end)

function getPlayerIdentifier(src)
    return QBCore.Functions.GetIdentifier(src, 'license')
end

CreateThread(function()
    Wait(1000)
    QBCore.Commands.Add('logout', 'Logout', {}, false, function(source)
        local src = source
        local license = QBCore.Functions.GetIdentifier(src, 'license')
        SetPlayerRoutingBucket(source, math.random(99, 999))
        local plyChars = {}
        local availableSlots = {}
        if Config.LockTheSlots then
            local unlockedSlots = MySQL.query.await('SELECT * FROM multicharacter WHERE license = ?', {license})
            if unlockedSlots[1] ~= nil then
                availableSlots = json.decode(unlockedSlots[1].slots)
            end
        end
        local player = QBCore.Functions.GetPlayer(src)
        QBCore.Player.Logout(player)
        MySQL.query('SELECT * FROM players WHERE license = ?', {license}, function(result)
            for i = 1, (#result), 1 do
                result[i].charinfo = json.decode(result[i].charinfo)
                result[i].money = json.decode(result[i].money)
                result[i].job = json.decode(result[i].job)
                result[i].gang = json.decode(result[i].gang)
                plyChars[#plyChars + 1] = result[i]
            end
            TriggerClientEvent('qb-multicharacter:client:SetCharacters', src, plyChars, availableSlots)
        end)
    end, 'admin')
end)