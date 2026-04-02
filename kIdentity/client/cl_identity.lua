local isIdentityOpen = false
local savedPosition = nil
local identityCamera = nil
local PLAYER_IS_READY = false

local PED_BASE_HEIGHT = 0.9

local function SendReactMessage(action, data)
    SendNUIMessage({ action = action, data = data })
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

local function WaitPlayerReady()
    if PLAYER_IS_READY then return end

    local timeout = GetGameTimer() + 20000
    while GetGameTimer() < timeout do
        if NetworkIsSessionStarted() and DoesEntityExist(PlayerPedId()) then
            PLAYER_IS_READY = true
            return
        end
        Wait(100)
    end

    PLAYER_IS_READY = true
end

local function SetupDefaultPed(gender)
    local config = CORE.Identity.Config
    local modelName = (gender == "female" and config.defaultPedFemale) or config.defaultPedMale or "mp_m_freemode_01"
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

local function OpenIdentityForm()
    WaitPlayerReady()

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

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    SetupDefaultPed(CORE.Identity.CurrentIdentity and CORE.Identity.CurrentIdentity.gender)

    local pos = CORE.Identity.Config.player_position
    if pos then
        local pPed = PlayerPedId()

        SetEntityCoords(pPed, pos.x, pos.y, pos.z, false, false, false, false)
        SetEntityVisible(pPed, true, true)

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

    FreezePlayer(true)
    CreateIdentityCamera()

    SetNuiFocus(true, true)
    SendReactMessage('setVisible', true)
    SendReactMessage('setPage', { page = 'identity' })

    local config = CORE.Identity.Config
    SendReactMessage('setColor', config.backgroundGlass and { color = config.color or "gold", backgroundGlass = config.backgroundGlass } or (config.color or "gold"))

    Wait(100)
    local nuiConfig = CORE.Identity.GetNUIConfig()
    SendReactMessage('setIdentity', { config = nuiConfig })

    if nuiConfig.music and nuiConfig.music.enabled then
        SendReactMessage('setMusicConfig', nuiConfig.music)
    end

    DoScreenFadeIn(500)
end

local function CloseIdentityForm(cancelled)
    if not isIdentityOpen then return end
    isIdentityOpen = false

    SendReactMessage('setVisible', false)
    SetNuiFocus(false, false)

    if not IsScreenFadedOut() then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
    end

    DestroyIdentityCamera()
    FreezePlayer(false)

    if cancelled then
        if savedPosition then
            TeleportPlayer(savedPosition)
        end
        savedPosition = nil
        DoScreenFadeIn(500)
        return
    end

    savedPosition = nil

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

RegisterNUICallback('identity:getIdentity', function(_, cb)
    SendReactMessage('setIdentity', { config = CORE.Identity.GetNUIConfig() })
    cb({})
end)

RegisterNUICallback('identity:createCharacter', function(data, cb)
    if not data then
        cb({ success = false, error = 'Invalid data' })
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

RegisterNUICallback('identity:cancel', function(_, cb)
    CloseIdentityForm(true)
    cb({})
end)

AddEventHandler('kIdentity:openForm', OpenIdentityForm)

RegisterNetEvent('kIdentity:identitySaved', function(identity)
    if CORE and CORE.Identity then
        CORE.Identity.CurrentIdentity = identity
    end

    if identity and GetResourceState('kCharcreator') == 'started' then
        TriggerEvent('kCharcreator:setSex', identity.gender == 'female' and 'f' or 'm')
        TriggerEvent('CORE.Charcreator:Open')
    end
end)

RegisterNetEvent('kIdentity:open', OpenIdentityForm)
RegisterNetEvent('kIdentity:close', function() CloseIdentityForm(false) end)

exports('OpenIdentityForm', OpenIdentityForm)
exports('CloseIdentityForm', CloseIdentityForm)
exports('IsIdentityOpen', function() return isIdentityOpen end)
