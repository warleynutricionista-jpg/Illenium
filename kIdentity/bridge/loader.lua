Bridge = Bridge or {}

Bridge.Frameworks = {
    ESX = "esx",
    QBCORE = "qbcore",
    QBOX = "qbox",
    STANDALONE = "standalone"
}

local FrameworkResources = {
    qbox = "qbx_core",
    qbcore = "qb-core",
    esx = "es_extended"
}

local FrameworkNames = {
    esx = "^2ESX^0",
    qbcore = "^5QBCore^0",
    qbox = "^6QBox^0",
    standalone = "^3Standalone^0"
}

local function DetectFramework(configFramework)
    if configFramework and configFramework ~= "auto" then
        return configFramework
    end

    for _, fw in ipairs({"qbox", "qbcore", "esx"}) do
        if GetResourceState(FrameworkResources[fw]) == "started" then
            return fw
        end
    end

    return "standalone"
end

local function InitESX()
    local ESX = nil
    pcall(function()
        ESX = exports["gamemode"]:getSharedObject()
    end)
    if not ESX then
        TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
        Wait(100)
    end
    return ESX
end

local function InitQBCore()
    local QBCore = nil
    pcall(function()
        QBCore = exports["qb-core"]:GetCoreObject()
    end)
    return QBCore
end

local function InitQBox()
    local QBX = nil
    pcall(function()
        QBX = exports['qbx_core']:GetCoreObject()
    end)
    if not QBX then
        pcall(function()
            QBX = exports['qbx_core']
        end)
    end
    return QBX
end

function Bridge:Init(configFramework)
    self.Framework = DetectFramework(configFramework)
    self.Object = nil

    if self.Framework == "esx" then
        self.Object = InitESX()
    elseif self.Framework == "qbcore" then
        self.Object = InitQBCore()
    elseif self.Framework == "qbox" then
        self.Object = InitQBox()
    end

    local resourceName = GetCurrentResourceName()
    print(("^5[%s]^0 Bridge loaded: %s"):format(resourceName, FrameworkNames[self.Framework] or "Unknown"))
end

function Bridge:IsReady()
    return self.Framework == "standalone" or self.Object ~= nil
end

function Bridge:AwaitReady()
    while not self:IsReady() do Wait(50) end
end

function Bridge:GetName()
    return FrameworkNames[self.Framework] or "Unknown"
end

CreateThread(function()
    local configFramework = "auto"
    Wait(100)
    if CORE and CORE.Identity and CORE.Identity.Config and CORE.Identity.Config.Framework then
        configFramework = CORE.Identity.Config.Framework
    end
    Bridge:Init(configFramework)
end)
