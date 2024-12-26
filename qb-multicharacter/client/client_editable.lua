QBCore = nil

local function InitializeFrameworkDependentComponents()
    QBCore = exports['qb-core']:GetCoreObject()
end

CreateThread(function()
    InitializeFrameworkDependentComponents()
end)