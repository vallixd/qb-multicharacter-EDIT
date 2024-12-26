local hasDonePreloading = {}

RegisterServerEvent('qb-multicharacter:server:SetPlayerBucket', function(bucket)
    local src = source
    SetPlayerRoutingBucket(src, bucket)
end)

RegisterServerEvent('qb-multicharacter:server:SaveAppearance', function(skin)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if skin.model ~= nil and skin ~= nil then
        MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', {Player.PlayerData.citizenid}, function()
            MySQL.insert('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)', {Player.PlayerData.citizenid, skin.model, json.encode(skin), 1})
        end)
    end
	return true
end)

local function GiveStarterItems(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    for _, v in pairs(QBCore.Shared.StarterItems) do
        local info = {}
        if v.item == 'id_card' then
            info.citizenid = Player.PlayerData.citizenid
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.gender = Player.PlayerData.charinfo.gender
            info.nationality = Player.PlayerData.charinfo.nationality
        elseif v.item == 'driver_license' then
            info.firstname = Player.PlayerData.charinfo.firstname
            info.lastname = Player.PlayerData.charinfo.lastname
            info.birthdate = Player.PlayerData.charinfo.birthdate
            info.type = 'Class C Driver License'
        end
        Player.Functions.AddItem(v.item, v.amount, false, info)
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    Wait(1000)
    hasDonePreloading[Player.PlayerData.source] = true
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    hasDonePreloading[src] = false
end)

RegisterServerEvent('qb-multicharacter:server:PlayerJoin', function()
    local src = source
    local license = getPlayerIdentifier(src)
    SetPlayerRoutingBucket(source, math.random(99, 999))
    local plyChars = {}
    local availableSlots = {}
    if Config.LockTheSlots then
        local unlockedSlots = MySQL.query.await('SELECT * FROM multicharacter WHERE license = ?', {license})
        if unlockedSlots[1] ~= nil then
            availableSlots = json.decode(unlockedSlots[1].slots)
        end
    end
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
end)

RegisterNetEvent('qb-multicharacter:server:CreateCharacter', function(data)
    local src = source
    local newData = {}
    newData.cid = data.cid or 1
    newData.charinfo = data
    SetPlayerRoutingBucket(src, 0)
    if QBCore.Player.Login(src, false, newData) then
        while not hasDonePreloading[src] do
            Wait(10)
        end
        QBCore.Commands.Refresh(src)
        GiveStarterItems(src)
        QBCore.Commands.Refresh(src)
        TriggerClientEvent('qb-multicharacter:client:CloseUI', src)
    end
end)

function GetPlayerFromId(src)
	self = {}
	self.src = src
    xPlayer = QBCore.Functions.GetPlayer(self.src)
    xPlayer.identifier = xPlayer.citizenid
    if not xPlayer then return end
    return xPlayer
end

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for v in pairs(GetPlayers()) do
            v = tonumber(v)
            local player = QBCore.Functions.GetPlayer(v)
            if player then
                QBCore.Player.Logout(player)
            end
        end
    end
end)

RegisterNetEvent('qb-multicharacter:server:LoadUserData', function(cData)
    local src = source
    SetPlayerRoutingBucket(src, 0)
    if QBCore.Player.Login(src, cData.citizenid) then
        repeat
            Wait(10)
        until hasDonePreloading[src]
        QBCore.Commands.Refresh(src)
        TriggerClientEvent('qb-multicharacter:client:spawn:SetupSpawns', src, cData, false, nil)
        TriggerClientEvent('qb-multicharacter:client:spawn:OpenUI', src, true, coords)
    end
end)

CreateThread(function()
    Wait(1000)
    QBCore.Functions.CreateCallback('qb-multicharacter:server:GetSkin', function(_, cb, cid)
        local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {cid, 1})
        if result[1] ~= nil then
            cb(result[1].model, json.decode(result[1].skin))
        else
            cb(nil)
        end
    end)
end)