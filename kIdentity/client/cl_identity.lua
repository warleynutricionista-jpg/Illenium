local isIdentityOpen = false
local savedPosition = nil
local identityCamera = nil

local PED_BASE_HEIGHT = 0.9

-- ============================================
-- HELPERS
-- ============================================

local function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function FreezePlayer(freeze)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, freeze)
    SetEntityInvincible(ped, freeze)
    SetEntityCollision(ped, not freeze, true)
end

local function TeleportPlayer(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.h or coords.w or 0.0)
end

-- ============================================
-- PED MODEL
-- ============================================

local function SetupDefaultPed()
    local config = CORE.Identity.Config
    local modelName = config.defaultPedMale or "mp_m_freemode_01"
    local model = GetHashKey(modelName)

    RequestModel(model)
    local timeout = GetGameTimer()
    while not HasModelLoaded(model) do
        if GetGameTimer() - timeout > 5000 then break end
        Wait(0)
    end

    if HasModelLoaded(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        SetPedDefaultComponentVariation(PlayerPedId())
    end
end

-- ============================================
-- CAMERA SYSTEM
-- ============================================

local function CreateIdentityCamera()
    local config = CORE.Identity.Config
    local pos = config.player_position
    local cam = config.camera or { distance = 1.8, height = 0.3, fov = 50.0 }

    local angleRad = math.rad(pos.w)
    local baseZ = pos.z + PED_BASE_HEIGHT

    identityCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(identityCamera,
        pos.x + (cam.distance * math.sin(-angleRad)),
        pos.y + (cam.distance * math.cos(-angleRad)),
        baseZ + cam.height
    )
    PointCamAtCoord(identityCamera, pos.x, pos.y, baseZ + cam.height)
    SetCamFov(identityCamera, cam.fov)
    SetCamActive(identityCamera, true)
    RenderScriptCams(true, false, 0, true, false)
end

local function DestroyIdentityCamera()
    if identityCamera and DoesCamExist(identityCamera) then
        DestroyCam(identityCamera, false)
        RenderScriptCams(false, false, 0, true, false)
        identityCamera = nil
    end
end

-- ============================================
-- STAND STILL THREAD
-- ============================================

CreateThread(function()
    while true do
        if isIdentityOpen then
            local pPed = PlayerPedId()
            TaskStandStill(pPed, 1000)
            SetPedCanHeadIk(pPed, false)
            BlockWeaponWheelThisFrame()
            DisableAllControlActions(0)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ============================================
-- OPEN / CLOSE
-- ============================================

-- ============================================

AddEventHandler("LIB:PLAYER_LOADED", function ()
    PLAYER_IS_READY = true;
end)

local function OpenIdentityForm()
    -- wait until a player spawn and if no skin put like a mp_freeroam_
    
    while not PLAYER_IS_READY do
        Wait(1000)
    end

    while (exports["web"]:arrivalIsShowing()) do
        Wait(2000);
    end

    if isIdentityOpen then return end
    isIdentityOpen = true

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    savedPosition = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = GetEntityHeading(ped)
    }

    -- Fade out
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    -- Setup default freemode ped
    SetupDefaultPed()

    -- Teleport to identity position (same method as kCharcreator)
    local pos = CORE.Identity.Config.player_position
    if pos then
        local pPed = PlayerPedId()

        -- Teleport with interior/scene loading
        SetEntityCoords(pPed, pos.x, pos.y, pos.z, false, false, false, false)
        -- StartPlayerTeleport(PlayerId(), pos.x, pos.y, pos.z, pos.w or 0.0, false, true, true)
        -- while IsPlayerTeleportActive() do Wait(0) end

        SetEntityVisible(pPed, true, true)

        -- Load scene and collision
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        NewLoadSceneStart(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z, 50.0, 0)

        local timeout = GetGameTimer()
        while IsNetworkLoadingScene() do
            if GetGameTimer() - timeout > 2000 then break end
            Wait(0)
        end

        timeout = GetGameTimer()
        while not HasCollisionLoadedAroundEntity(pPed) do
            if GetGameTimer() - timeout > 2000 then break end
            Wait(0)
        end

        SetEntityHeading(pPed, pos.w or 0.0)
    end

    -- Freeze player
    FreezePlayer(true)

    -- Create camera
    CreateIdentityCamera()

    -- Show NUI
    SetNuiFocus(true, true)
    SendReactMessage('setVisible', true)
    SendReactMessage('setPage', { page = 'identity' })

    local config = CORE.Identity.Config
    SendReactMessage('setColor', config.backgroundGlass and { color = config.color or "gold", backgroundGlass = config.backgroundGlass } or (config.color or "gold"))

    Wait(100)
    local nuiConfig = CORE.Identity.GetNUIConfig()
    SendReactMessage('setIdentity', {
        config = nuiConfig
    })

    if nuiConfig.music and nuiConfig.music.enabled then
        SendReactMessage('setMusicConfig', nuiConfig.music)
    end

    -- Fade in
    DoScreenFadeIn(500)
end

local function CloseIdentityForm(cancelled)
    if not isIdentityOpen then return end
    isIdentityOpen = false

    -- Close NUI
    SendReactMessage('setVisible', false)
    SetNuiFocus(false, false)

    -- Fade out
    if not IsScreenFadedOut() then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
    end

    -- Cleanup camera
    DestroyIdentityCamera()
    FreezePlayer(false)

    if cancelled then
        -- Cancelled: teleport back to saved position and fade in
        if savedPosition then
            TeleportPlayer(savedPosition)
        end
        savedPosition = nil
        DoScreenFadeIn(500)
    else
        -- Saved: leave screen faded out for seamless transition to character creator
        -- Don't teleport - let the next system handle positioning
        savedPosition = nil

        -- Safety: if nothing picks up within 5 seconds, fade in
        CreateThread(function()
            Wait(5000)
            if IsScreenFadedOut() then
                local spawn = CORE.Identity.Config.spawn_position
                if spawn then
                    TeleportPlayer(spawn)
                end
                DoScreenFadeIn(500)
            end
        end)
    end
end

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback('identity:getIdentity', function(data, cb)
    SendReactMessage('setIdentity', {
        config = CORE.Identity.GetNUIConfig()
    })
    cb({})
end)

RegisterNUICallback('identity:createCharacter', function(data, cb)
    if not data then
        cb({ success = false })
        return
    end

    if not data.firstName or data.firstName == "" then
        cb({ success = false, error = "First name is required" })
        return
    end

    if not data.lastName or data.lastName == "" then
        cb({ success = false, error = "Last name is required" })
        return
    end

    if not data.dateOfBirth then
        cb({ success = false, error = "Date of birth is required" })
        return
    end

    TriggerServerEvent('kIdentity:saveIdentity', {
        firstName = data.firstName,
        lastName = data.lastName,
        dateOfBirth = data.dateOfBirth,
        nationality = data.nationality or 0,
        gender = data.gender or "male"
    })

    CloseIdentityForm(false)

    cb({ success = true })
end)

RegisterNUICallback('identity:cancel', function(data, cb)
    CloseIdentityForm(true)
    cb({})
end)

-- ============================================
-- EVENTS
-- ============================================

AddEventHandler('kIdentity:openForm', function()
    OpenIdentityForm()
end)

local CharacterCreatorTriggers = {
    ["kCharcreator"] = function()
        TriggerEvent("esx_identity:completedRegistration")
    end,
    ["qb-clothing"] = function()
        TriggerEvent("qb-clothing:client:CreateFirstCharacter")
    end,
    ["illenium-appearance"] = function()
        TriggerEvent("illenium-appearance:client:openClothingShop")
    end,
    ["fivem-appearance"] = function()
        exports["fivem-appearance"]:startPlayerCustomization()
    end,
    ["esx_skin"] = function()
        TriggerEvent("esx_skin:playerRegistered")
    end
}

local function TriggerCharacterCreator()
    local config = CORE.Identity.Config

    if config.characterCreatorEvent and config.characterCreatorEvent ~= "" then
        print(('[kIdentity] Triggering custom event: %s'):format(config.characterCreatorEvent))
        TriggerEvent(config.characterCreatorEvent)
        return true
    end

    if config.characterCreator and config.characterCreator ~= "" then
        if GetResourceState(config.characterCreator) == "started" then
            local trigger = CharacterCreatorTriggers[config.characterCreator]
            if trigger then
                print(('[kIdentity] Triggering configured: %s'):format(config.characterCreator))
                trigger()
                return true
            end
        end
    end

    local supportedList = config.supportedCreators or {
        "kCharcreator", "qb-clothing", "illenium-appearance", "fivem-appearance", "esx_skin"
    }

    for _, creator in ipairs(supportedList) do
        if GetResourceState(creator) == "started" then
            local trigger = CharacterCreatorTriggers[creator]
            if trigger then
                print(('[kIdentity] Auto-detected and triggering: %s'):format(creator))
                trigger()
                return true
            end
        end
    end

    return false
end

RegisterNetEvent('kIdentity:identitySaved', function(identity)
    print('[kIdentity] Identity saved successfully')

    if CORE and CORE.Identity then
        CORE.Identity.CurrentIdentity = identity
    end

    if not TriggerCharacterCreator() then
        print('[kIdentity] No compatible character creator found')
    end
end)

RegisterNetEvent('kIdentity:open', function()
    OpenIdentityForm()
end)

RegisterNetEvent('kIdentity:close', function()
    CloseIdentityForm(false)
end)
exports('OpenIdentityForm', OpenIdentityForm)
exports('CloseIdentityForm', CloseIdentityForm)
exports('IsIdentityOpen', function() return isIdentityOpen end)
