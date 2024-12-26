PlayerCharacters = {}
local spawnedPed = nil
local playerSkinData = {}
local cam = nil
local pedCamera = nil
local lastLocation = nil
local spawnCamera =  nil
local camZPlus1 = 1500
local camZPlus2 = 50
local pointCamCoords = 75
local pointCamCoords2 = 0
local cam1Time = 500
local cam2Time = 1000
local cam2 = nil
local skin = {}

CreateThread(function()
    Wait(1000)
    SendNUIMessage({action = 'loadLocale', data = Locales})
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            TriggerServerEvent('qb-multicharacter:server:PlayerJoin')
            return
        end
    end
end)

local function SetCam(campos)
    if not campos.z then campos = json.decode(campos) end
    SetEntityCoords(PlayerPedId(), campos.x, campos.y, campos.z)
    cam2 = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', campos.x, campos.y, campos.z + camZPlus1, 300.00, 0.00, 0.00, 110.00, false, 0)
    PointCamAtCoord(cam2, campos.x, campos.y, campos.z + pointCamCoords)
    SetCamActiveWithInterp(cam2, cam, cam1Time, true, true)
    if DoesCamExist(cam) then
        DestroyCam(cam, true)
    end
    Wait(cam1Time)
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', campos.x, campos.y, campos.z + camZPlus2, 300.00, 0.00, 0.00, 110.00, false, 0)
    PointCamAtCoord(cam, campos.x, campos.y, campos.z + pointCamCoords2)
    SetCamActiveWithInterp(cam, cam2, cam2Time, true, true)
end

ApplySkinToPed = function(ped, skn)
    exports['qb-appearance']:setPedAppearance(ped, skn)
end

RegisterNUICallback('setCam', function(data, cb)
    local location = data.location
    local type = data.type
    DoScreenFadeOut(200)
    Wait(500)
    DoScreenFadeIn(200)
    if DoesCamExist(cam) then DestroyCam(cam, true) end
    if DoesCamExist(cam2) then DestroyCam(cam2, true) end
    if type == 'current' then
        for k, v in pairs(Config.SpawnLocations) do
            if v.lastLoc then
                SetCam(v.coords)
                break
            end
        end
    elseif type == 'location' then
        SetCam(Config.SpawnLocations[location].coords)
    end
    cb('ok')
end)

local function PreSpawnPlayer()
    DoScreenFadeOut(500)
    Wait(2000)
end

local function PostSpawnPlayer(ped)
    FreezeEntityPosition(ped, false)
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    SetCamActive(cam2, false)
    DestroyCam(cam2, true)
    SetEntityVisible(PlayerPedId(), true)
    Wait(500)
    DoScreenFadeIn(250)
end

finished = false

SkinMenu = function()
    local bucketId = math.random(1, 9999)
    local config = Config.AppearanceConfig
    local playerPed = PlayerPedId()
    SetPedAoBlobRendering(playerPed, true)
    ResetEntityAlpha(playerPed)
    SetEntityVisible(playerPed, true)
    TriggerServerEvent('qb-multicharacter:server:SetPlayerBucket', bucketId)
    exports['qb-appearance']:startPlayerCustomization(function(appearance)
        if (appearance) then
            TriggerServerEvent('qb-multicharacter:server:SaveAppearance', appearance)
            finished = true
        else
            local appearance = exports['qb-appearance']:getPedAppearance(playerPed)
            TriggerServerEvent('qb-multicharacter:server:SaveAppearance', appearance)
            finished = true
        end
        TriggerServerEvent('qb-multicharacter:server:SetPlayerBucket', 0)
    end, config)
end

LoadSkin = function(skin)
    exports['qb-appearance']:setPlayerAppearance(skin)
end

GetModel = function(str, othermodel)
    skin.sex = str == 'm' and 0 or 1
    local model = othermodel or skin.sex == 0 and `mp_m_freemode_01` or `mp_f_freemode_01`
    return model
end

SetSkin = function(ped, skn)
    exports['qb-appearance']:setPedAppearance(PlayerPedId(), skn)
end

SetModel = function(model)
	RequestModel(model)
	while not HasModelLoaded(model) do Wait(0) end
	SetPlayerModel(PlayerId(), model)
	SetModelAsNoLongerNeeded(model)
end

local function SetUPCharUI(bool)
    NetworkOverrideClockTime(22, 30, 0)
    SetNuiFocus(bool, bool)
    SendNUIMessage({action = (bool and 'showCHARNUI' or 'hideUI'), playerCharacters = PlayerCharacters, configData = Config})
    Wait(2000)
    DoScreenFadeIn(1000)
end

local function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

local function SetPedCamera(ped)
    if ped then
        if pedCamera then
            SetCamActive(pedCamera, false)
            DestroyCam(pedCamera, true)
            RenderScriptCams(0, 1, 1000, 1, 1)
        end
        local offset = GetOffsetFromEntityInWorldCoords(ped, -1.0, 4.0, 1.0)
        pedCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(pedCamera, offset.x, offset.y, offset.z)
        PointCamAtEntity(pedCamera, ped, 0.0, 0.0, 0.6, true)
        RenderScriptCams(1, 1, 1000, 1, 1)
        SetCamFov(pedCamera, 25.0)
    else
        if pedCamera then
            SetCamActive(pedCamera, false)
            DestroyCam(pedCamera, true)
            RenderScriptCams(0, 1, 1000, 1, 1)
            pedCamera = nil
        end
    end
end

local function InitializePedModel(model, data)
    CreateThread(function()
        if not model then
            model = Config.RandomPeds[math.random(#Config.RandomPeds)]
        end
        LoadModel(model)
        spawnedPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
        SetPedComponentVariation(spawnedPed, 0, 0, 0, 2)
        FreezeEntityPosition(spawnedPed, false)
        SetEntityInvincible(spawnedPed, true)
        PlaceObjectOnGroundProperly(spawnedPed)
        SetBlockingOfNonTemporaryEvents(spawnedPed, true)
        local anim = Config.RandomPedAnimations[math.random(#Config.RandomPedAnimations)]
        if anim.type == 'sceneario' then
            TaskStartScenarioInPlace(spawnedPed, anim.anim, 0, true)
        else
            local tryCount = 5
            RequestAnimDict(anim.anim)
            while not HasAnimDictLoaded(anim.anim) do
                tryCount = tryCount - 1
                if tryCount == 0 then
                    break
                end
                Wait(500)
            end
            TaskPlayAnim(spawnedPed, anim.anim, anim.dict, 8.0, 8.0, -1, 1, 0, false, false, false)
        end
        SetPedCamera(spawnedPed)
        Wait(1000)
        DoScreenFadeIn(500)
        if data then
            ApplySkinToPed(spawnedPed, data)
        end
    end)
end

RegisterNetEvent('qb-multicharacter:client:SetCharacters', function(plyChars, slots)
    PlayerCharacters = {}
    PlayerCharacters = plyChars
    for k = #Config.LockedSlots, 1, -1 do
        local v = Config.LockedSlots[k]
        for i, j in pairs(slots) do
            v = tonumber(v)
            j = tonumber(j)
            if v == j then
                table.remove(Config.LockedSlots, k)
            end
        end
    end
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityVisible(PlayerPedId(), false)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    SetUPCharUI(true)
end)

RegisterNetEvent('qb-multicharacter:client:CloseUI', function()
    DeleteEntity(spawnedPed)
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoords(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    Wait(500)
    SetEntityVisible(PlayerPedId(), true)
    Wait(500)
    DoScreenFadeIn(250)
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerEvent('qb-appearance:client:CreateFirstCharacter')
end)

RegisterNUICallback('SpawnPed', function(data, cb)
    SetUPCharUI(false)
    local ped = PlayerPedId()
    SetEntityAsMissionEntity(spawnedPed, true, true)
    DeleteEntity(spawnedPed)
    if data.type == 'current' or data.type == nil then
        PreSpawnPlayer()
        QBCore.Functions.GetPlayerData(function(pd)
            ped = PlayerPedId()
            SetEntityCoords(ped, pd.position.x, pd.position.y, pd.position.z)
            SetEntityHeading(ped, pd.position.a)
            FreezeEntityPosition(ped, false)
        end)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        PostSpawnPlayer()
    elseif data.type == 'location' then
        local pos = Config.SpawnLocations[data.location].coords
        PreSpawnPlayer()
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        Wait(500)
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
        SetEntityHeading(ped, pos.w)
        PostSpawnPlayer()
    end
    DestroyCam(spawnCamera, false)
    RenderScriptCams(false, true, 1000, false, false)
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true)
    SetEntityCollision(PlayerPedId(), true, true)
    NetworkSetEntityInvisibleToNetwork(PlayerPedId(), false)
    SetEveryoneIgnorePlayer(PlayerPedId(), false)
    SetNuiFocus(false, false)
    for k, v in pairs(Config.SpawnLocations) do
        if v.lastLoc then
            table.remove(Config.SpawnLocations, k)
            break
        end
    end
    cb('ok')
end)

RegisterNUICallback('CreateCharacter', function(data, cb)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == 'male' then
        cData.gender = 0
    elseif cData.gender == 'female' then
        cData.gender = 1
    end
    SetPedCamera(nil)
    TriggerServerEvent('qb-multicharacter:server:CreateCharacter', cData)
    local spawnCoords = lastLocation ~= nil and lastLocation or Config.DefaultSpawn
    SetUPCharUI(false)
    SetEntityAsMissionEntity(spawnedPed, true, true)
    DeleteEntity(spawnedPed)
    SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.9)
    SetEntityHeading(PlayerPedId(), spawnCoords.w)
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true)
    SetEntityCollision(PlayerPedId(), true, true)
    NetworkSetEntityInvisibleToNetwork(PlayerPedId(), false)
    SetEveryoneIgnorePlayer(PlayerPedId(), false)
    cb('ok')
end)

RegisterNUICallback('PlayGame', function(data, cb)
    local cData = data.data
    DoScreenFadeOut(10)
    TriggerServerEvent('qb-multicharacter:server:LoadUserData', cData)
    SetPedCamera(nil)
    SetEntityAsMissionEntity(spawnedPed, true, true)
    DeleteEntity(spawnedPed)
    SetEntityVisible(PlayerPedId(), true)
    if not Config.UseSpawnSelector then
        local spawnCoords = lastLocation ~= nil and lastLocation or Config.DefaultSpawn
        SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.9)
        SetEntityHeading(PlayerPedId(), spawnCoords.w)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true)
        SetEntityCollision(PlayerPedId(), true, true)
        NetworkSetEntityInvisibleToNetwork(PlayerPedId(), false)
        SetEveryoneIgnorePlayer(PlayerPedId(), false)
        SetNuiFocus(false, false)
    end
    cb('ok')
end)

RegisterNUICallback('ChangeGender', function(data, cb)
    local gender = data.gender
    if spawnedPed ~= nil then
        local pedCoords = GetEntityCoords(spawnedPed)
        local pedHeading = GetEntityHeading(spawnedPed)
        SetEntityAsMissionEntity(spawnedPed, true, true)
        DeleteEntity(spawnedPed)
        local model = gender == 'female' and ('mp_f_freemode_01') or ('mp_m_freemode_01')
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(1)
        end
        spawnedPed = CreatePed(2, model, pedCoords.x, pedCoords.y, pedCoords.z-0.98, pedHeading, false, true)
        SetModelAsNoLongerNeeded(model)
        SetPedCamera(spawnedPed)
    end
    cb(true)
end)

RegisterNUICallback('SetPedAction', function(data, cb)
    local currentCharData = data.data
    if spawnedPed ~= nil then
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityAsMissionEntity(spawnedPed, true, true)
        DeleteEntity(spawnedPed)
    end
    if (currentCharData ~= nil) then
        if not (playerSkinData[currentCharData.citizenid]) then
            local temp_model = promise.new()
            local temp_data = promise.new()
            QBCore.Functions.TriggerCallback('qb-multicharacter:server:GetSkin', function(model, data)
                temp_model:resolve(model)
                temp_data:resolve(data)
            end, currentCharData.citizenid)
            local resolved_model = Citizen.Await(temp_model)
            local resolved_data = Citizen.Await(temp_data)
            playerSkinData[currentCharData.citizenid] = { model = resolved_model, data = resolved_data }
        end
        local model = playerSkinData[currentCharData.citizenid].model
        local data = playerSkinData[currentCharData.citizenid].data
        model = model ~= nil and tonumber(model) or false
        if model ~= nil then
            InitializePedModel(model, data)
        else
            InitializePedModel()
        end
        cb('ok')
    else
        InitializePedModel()
        cb('ok')
    end
end)

local function setUPSpawnUI(bool, lastLoc)
    if lastLoc then
        Config.SpawnLocations[#Config.SpawnLocations + 1] = {title = 'Son Konum', description = 'Son konumda devam edebilirsiniz.', coords = lastLoc, lastLoc = true}
    end
    local ped = PlayerPedId()
    SetEntityVisible(ped, false)
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(spawnCamera, false)
    local coords = Config.SpawnLocations[1].coords
    local camX, camY, camZ = coords.x, coords.y, coords.z + 100
    spawnCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(spawnCamera, camX, camY, camZ)
    PointCamAtCoord(spawnCamera, coords.x, coords.y, coords.z)
    RenderScriptCams(true, false, 1500, true, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.98)
    SendNUIMessage({action = (bool and 'openSPAWNUI' or 'hideUI'),})
    DoScreenFadeIn(1000)
    SetNuiFocus(bool, bool)
end

RegisterNetEvent('qb-multicharacter:client:spawn:OpenUI', function(value, lastLoc)
    setUPSpawnUI(value, lastLoc)
end)

RegisterNetEvent('qb-multicharacter:client:spawn:SetupSpawns', function(cData, new, apps)
    Wait(500)
    SendNUIMessage({action = 'setupLocations', locations = Config.SpawnLocations, isNew = new})
end)