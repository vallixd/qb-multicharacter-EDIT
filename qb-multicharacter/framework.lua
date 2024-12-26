QBCore = exports['qb-core']:GetCoreObject()

function GetPlayerFromId(src)
	self = {}
	self.src = src
	xPlayer = QBCore.Functions.GetPlayer(self.src)
	xPlayer.identifier = xPlayer.citizenid
	if not xPlayer then return end
	return xPlayer
end

GetCharacters = function(source, data, slots)
	local characters = {}
	local license = QBCore.Functions.GetIdentifier(source, 'license')
	local result = MySQL.query.await('SELECT * FROM players WHERE license = ?', {license})
	if result and #result > 0 then
		for i = 1, (#result), 1 do
			local skin = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {result[i].citizenid, 1})
			local info = json.decode(result[i].charinfo)
			local money = json.decode(result[i].money)
			local job = json.decode(result[i].job)
			local gang = json.decode(result[i].gang)
			local firstname = info.firstname or 'No name'
			local lastname = info.lastname or 'No Lastname'
			local playerskin = skin and skin[1] and json.decode(skin[1].skin) or {}
			playerskin.model = skin and skin[1] and tonumber(skin[1].model)
			characters[result[i].cid] = {slot = result[i].cid, name = firstname..' '..lastname, job = job.label..' - '..job.grade.name, gang = gang.label..' - '..job.grade.name, dateofbirth = info.birthdate or '', cash = money.cash, bank = money.bank, citizenid = result[i].citizenid, identifier = result[i].citizenid, skin = playerskin, sex = info.gender == 0 and 'm' or 'f', position = result[i].position and result[i].position ~= '' and json.decode(result[i].position) or vec3(280.03, -584.29, 43.29), extras = GetExtras(result[i].citizenid)}
		end
	end
	return {characters = characters , slots = slots}
end

LoadPlayer = function(source)
	local source = source
	local ts = 0
	while not GetPlayerFromId(source) and ts < 1000 do ts += 1 Wait(0) end
	local ply = Player(source).state
	local identifier = GetPlayerFromId(source).identifier
	if identifier then
		ply:set('identifier',GetPlayerFromId(source).identifier, true)
	end
	return true
end

Login = function(source, data, new)
	local source = source
	if new then
		new.cid = data
		new.charinfo = {firstname = new.firstname, lastname = new.lastname, birthdate = new.birthdate or new.dateofbirth, gender = new.sex == 'm' and 0 or 1, nationality = new.nationality}
	end
	local ply = Player(source).state
	ply:set('identifier', data, true)
	QBCore.Commands.Refresh(source)
	if new then GiveStarterItems(source) end
	return true
end

SaveSkin = function(source, skin)
	local Player = QBCore.Functions.GetPlayer(source)
	if skin.model ~= nil and skin ~= nil then
		MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', {Player.PlayerData.citizenid}, function()
			MySQL.insert('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)', {Player.PlayerData.citizenid, skin.model, json.encode(skin), 1})
		end)
	end
	return true
end

GetExtras = function(id, group)
	local status = GlobalState.PlayerStates or {}
	local admin = group ~= nil and group ~= 'user'
	if admin then if not status[id] then status[id] = {} end status[id]['admin'] = true end
	return status[id] or {}
end

UpdateSlot = function(src, id, slot)
	local slots = json.decode(GetResourceKvpString('char_slots') or '[]') or {}
	local license = GetIdentifiers(id)
	if license == nil then return end
	slots[license] = tonumber(slot) or Config.Slots
	SetResourceKvp('char_slots', json.encode(slots))
	return true
end

QBCore.Commands.Add('addslot', 'Add Character Slot', {{name = 'id', help = 'ID'}, {name = 'slots', help = 'Slot Number'}}, false, function(source, args)
	UpdateSlot(source, args[1], args[2])
end, 'admin')

GlobalState.PlayerStates = json.decode(GetResourceKvpString('char_status') or '[]') or {}

GiveStarterItems = function(source)
	local starter = json.decode(GetResourceKvpString('starteritems') or '[]') or {}
	Citizen.CreateThreadNow(function()
		local src = source
		local Player = QBCore.Functions.GetPlayer(src)
		if starter[Player.PlayerData.citizenid] then return end
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
		starter[Player.PlayerData.citizenid] = true
		SetResourceKvp('starteritems', json.encode(starter))
	end)
	Wait(2000)
end