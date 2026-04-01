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

if not IsDuplicityVersion() then
    RegisterNetEvent("esx_identity:showRegisterIdentity", function()
        IdentityChecked = true
        TriggerEvent("esx_skin:resetFirstSpawn")
        Wait(100)
        TriggerEvent("kIdentity:openForm")
    end)

    RegisterNetEvent("esx_identity:alreadyRegistered", function()
        IdentityChecked = true
        TriggerEvent("kIdentity:identityLoaded")

        if GetResourceState("kCharcreator") ~= "started" and
           GetResourceState("qb-clothing") ~= "started" and
           GetResourceState("illenium-appearance") ~= "started" and
           GetResourceState("fivem-appearance") ~= "started" then
            if GetResourceState("esx_skin") == "started" then
                TriggerEvent("esx_skin:playerRegistered")
            end
        end
    end)

    RegisterNetEvent("esx_identity:setPlayerData", function(data)
        if Bridge.Framework == "esx" and Bridge.Object then
            SetTimeout(1, function()
                Bridge.Object.SetPlayerData("name", ("%s %s"):format(data.firstName, data.lastName))
                Bridge.Object.SetPlayerData("firstName", data.firstName)
                Bridge.Object.SetPlayerData("lastName", data.lastName)
                Bridge.Object.SetPlayerData("dateofbirth", data.dateOfBirth)
                Bridge.Object.SetPlayerData("sex", data.sex)
            end)
        end
    end)
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
        TriggerEvent("esx_identity:alreadyRegistered")

        print('[kIdentity] Player already has identity, triggering alreadyRegistered')
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
        PlayerLoaded = data and data.job ~= nil
    elseif Bridge.Framework == "qbcore" and Bridge.Object then
        local data = Bridge.Object.Functions.GetPlayerData()
        PlayerLoaded = data and data.citizenid ~= nil
    elseif Bridge.Framework == "qbox" and Bridge.Object then
        local data = Bridge.Object:GetPlayerData()
        PlayerLoaded = data and data.citizenid ~= nil
    end

    BridgeClient:OnPlayerLoaded(function()
        if Bridge.Framework == "esx" then
            Wait(2000)
        else
            Wait(1000)
        end
        CheckIdentityAndOpen()
    end)
end)
