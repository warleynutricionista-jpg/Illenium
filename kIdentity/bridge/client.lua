if IsDuplicityVersion() then return end

BridgeClient = BridgeClient or {}

local PlayerLoaded = false
local IdentityChecked = false

local PlayerLoadedEvents = {
    esx = "esx:playerLoaded",
    qbcore = "QBCore:Client:OnPlayerLoaded",
    qbox = "QBX:Client:OnPlayerLoaded"
}

local PlayerUnloadedEvents = {
    esx = "esx:onPlayerLogout",
    qbcore = "QBCore:Client:OnPlayerUnload",
    qbox = "QBX:Client:OnPlayerUnload"
}

function BridgeClient:IsPlayerLoaded()
    return PlayerLoaded
end

function BridgeClient:AwaitPlayerLoaded()
    while not PlayerLoaded do Wait(100) end
end

function BridgeClient:OnPlayerLoaded(cb)
    if Bridge.Framework == "standalone" then
        CreateThread(function()
            while not NetworkIsSessionStarted() do Wait(100) end
            PlayerLoaded = true
            cb()
        end)
    else
        local eventName = PlayerLoadedEvents[Bridge.Framework]
        if eventName then
            RegisterNetEvent(eventName, function()
                PlayerLoaded = true
                cb()
            end)
        end
    end

    if PlayerLoaded then cb() end
end

function BridgeClient:OnPlayerUnloaded(cb)
    local eventName = PlayerUnloadedEvents[Bridge.Framework]
    if eventName then
        RegisterNetEvent(eventName, function()
            PlayerLoaded = false
            IdentityChecked = false
            cb()
        end)
    end
end

local function CheckIdentityAndOpen()
    if IdentityChecked then return end

    IdentityChecked = true

    if not CORE or not CORE.Identity or not CORE.Identity.Config then
        return
    end

    local config = CORE.Identity.Config

    if config.autoOpen == false then
        return
    end

    TriggerServerEvent("kIdentity:checkIdentity")
end

RegisterNetEvent("kIdentity:checkIdentity:response", function(hasIdentity, identity)
    if hasIdentity and identity then
        if CORE and CORE.Identity then
            CORE.Identity.CurrentIdentity = identity
        end

        TriggerEvent("kIdentity:identityLoaded", identity)
    else
        TriggerEvent("kIdentity:openForm")
    end
end)

CreateThread(function()
    Bridge:AwaitReady()

    if Bridge.Framework == "standalone" then
        PlayerLoaded = NetworkIsSessionStarted()
    elseif Bridge.Framework == "esx" and Bridge.Object then
        local data = Bridge.Object.GetPlayerData()
        PlayerLoaded = data and data.identifier ~= nil
    elseif Bridge.Framework == "qbcore" and Bridge.Object then
        local data = Bridge.Object.Functions.GetPlayerData()
        PlayerLoaded = data and data.citizenid ~= nil
    elseif Bridge.Framework == "qbox" then
        PlayerLoaded = LocalPlayer and LocalPlayer.state and (LocalPlayer.state.isLoggedIn or false) or false
    end

    BridgeClient:OnPlayerLoaded(function()
        Wait(1000)
        CheckIdentityAndOpen()
    end)
end)
