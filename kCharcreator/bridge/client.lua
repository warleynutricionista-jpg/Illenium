--[[
    CLIENT-SIDE BRIDGE
    Auto-detect player loaded & auto-open charcreator

    ESX + esx_identity: Waits for identity completion before opening
    QBCore/QBox/Standalone: Opens directly after player loaded
]]

if IsDuplicityVersion() then return end

BridgeClient = BridgeClient or {}

local PlayerLoaded = false
local SkinChecked = false
local IdentityCompleted = false

local PlayerLoadedEvents = {
    esx = "esx:playerLoaded",
    qbcore = "QBCore:Client:OnPlayerLoaded",
    qbox = "QBX:Client:OnPlayerLoaded"
}

-- Check if an identity resource is running (esx_identity or kIdentity)
local function IsEsxIdentityRunning()
    return GetResourceState("esx_identity") == "started" or GetResourceState("kIdentity") == "started"
end

function BridgeClient:IsPlayerLoaded()
    return PlayerLoaded
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

local function CheckSkinAndOpen()
    if SkinChecked then return end
    SkinChecked = true

    if not CORE or not CORE.Charcreator or not CORE.Charcreator.Config then
        return
    end

    local config = CORE.Charcreator.Config

    if config.autoOpen == false then
        if config.autoloadskin then
            TriggerServerEvent("kCharcreator:loadSkin")
        end
        return
    end

    TriggerServerEvent("kCharcreator:checkSkin")
end

-- Called when we're ready to check skin (either directly or after identity)
local function OnReadyToCheckSkin()
    Wait(500)
    CheckSkinAndOpen()
end

RegisterNetEvent("kCharcreator:checkSkin:response", function(hasSkin, skin, model, sex)
    if hasSkin and skin then
        if CORE and CORE.Skin and CORE.Skin.SetSkin then
            CORE.Skin.SetSkin(skin, PlayerPedId(), true)
        end
    else
        if CORE and CORE.Charcreator then
            CORE.Charcreator.PlayerSex = sex or "m"
            TriggerEvent("CORE.Charcreator:Open")
        end
    end
end)

RegisterNetEvent("kCharcreator:loadSkin:response", function(skin, model)
    if skin and CORE and CORE.Skin and CORE.Skin.SetSkin then
        CORE.Skin.SetSkin(skin, PlayerPedId(), true)
    end
end)

--[[
    ESX Identity Integration
    Listen for esx_identity events to open charcreator AFTER identity creation
]]

-- New player finished creating identity -> open charcreator
RegisterNetEvent("esx_identity:completedRegistration", function()
    if Bridge.Framework ~= "esx" then return end
    if IdentityCompleted then return end
    IdentityCompleted = true

    print("^5[kCharcreator]^0 Identity completed, opening character creator...")
    OnReadyToCheckSkin()
end)

RegisterNetEvent('esx_skin:playerRegistered', function(src, registered)
    if Bridge.Framework ~= "esx" then return end
    if IdentityCompleted then return end

    
    print("^5[kCharcreator]^0 Identity completed, opening character creator...")
    OnReadyToCheckSkin()
end)
    

-- Existing player already has identity -> load skin directly
RegisterNetEvent("esx_identity:alreadyRegistered", function()
    if Bridge.Framework ~= "esx" then return end
    if IdentityCompleted then return end
    IdentityCompleted = true

    OnReadyToCheckSkin()
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
        -- ESX with esx_identity: wait for identity events instead
        if Bridge.Framework == "esx" and IsEsxIdentityRunning() then
            print("^5[kCharcreator]^0 esx_identity detected, waiting for identity completion...")

            return
        end

        -- QBCore, QBox, Standalone, or ESX without esx_identity: proceed directly
        Wait(1000)
        CheckSkinAndOpen()
    end)
end)
