CORE = CORE or {}
CORE.Teleport = CORE.Teleport or {}

function CORE.Teleport:TeleportToWp(ped, pos, heading, safeModeDisabled, func)
    if not safeModeDisabled then
        local pPed = ped or PlayerPedId()
        local veh = IsPedInAnyVehicle(pPed, false) and GetVehiclePedIsIn(pPed, false) or nil
        local inVehicle = veh ~= nil and GetPedInVehicleSeat(veh, -1) == pPed or false

        local z = pos.z + 1.0

        local vehicleRestoreVisibility = inVehicle and IsEntityVisible(veh)
        local pedRestoreVisibility = IsEntityVisible(pPed)

        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        if inVehicle then
            FreezeEntityPosition(veh, true)
            if IsEntityVisible(veh) then
                NetworkFadeOutEntity(veh, true, false)
            end
        else
            ClearPedTasksImmediately(pPed)
            FreezeEntityPosition(pPed, true)
            if IsEntityVisible(pPed) then
                NetworkFadeOutEntity(pPed, true, false)
            end
        end

        if func then
            func()
        end

        local pId = pPed and PlayerId() or nil

        if pId then
            StartPlayerTeleport(PlayerId(), pos.x, pos.y, pos.z, heading, inVehicle, true, true)

            while IsPlayerTeleportActive() do
                Wait(0)
            end
        else
            local groundZ = 850.0
            local found = false

            RequestCollisionAtCoord(pos.x, pos.y, z)
            NewLoadSceneStart(pos.x, pos.y, z, pos.x, pos.y, z, 50.0, 0)

            local tempTimer = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - tempTimer > 1000 then
                    print("Waiting for the scene to load is taking too long (more than 1s). Breaking from wait loop.")
                    break
                end
                Wait(0)
            end

            if inVehicle then
                SetEntityCoords(veh, pos.x, pos.y, z, false, false, false, true)
            else
                SetEntityCoords(pPed, pos.x, pos.y, z, false, false, false, true)
            end

            tempTimer = GetGameTimer()
            while not HasCollisionLoadedAroundEntity(pPed) do
                if GetGameTimer() - tempTimer > 1000 then
                    print("Waiting for the collision to load is taking too long (more than 1s). Breaking from wait loop.")
                    break
                end
                Wait(0)
            end

            found, groundZ = GetGroundZCoordWithOffsets(pos.x, pos.y, z)
            tempTimer = GetGameTimer()
            if not found then
                z = 950
            end
            while not found do
                z = z - 25.0
                found, groundZ = GetGroundZCoordWithOffsets(pos.x, pos.y, z)
                Wait(0)

                if z < 0.0 then
                    break
                end
            end

            if found then
                print("Ground coordinate found: " .. groundZ)
                if inVehicle then
                    SetEntityCoords(veh, pos.x, pos.y, groundZ, false, false, false, true)
                    FreezeEntityPosition(veh, false)
                    SetVehicleOnGroundProperly(veh)
                    FreezeEntityPosition(veh, true)
                else
                    SetEntityCoords(pPed, pos.x, pos.y, groundZ, false, false, false, true)
                end
            else
                local safePos = pos
                GetNthClosestVehicleNode(pos.x, pos.y, pos.z, 0, safePos, 0, 0, 0)

                print("Could not find a safe ground coord. Placing you on the nearest road instead.")

                if inVehicle then
                    SetEntityCoords(veh, safePos.x, safePos.y, safePos.z, false, false, false, true)
                    FreezeEntityPosition(veh, false)
                    SetVehicleOnGroundProperly(veh)
                    FreezeEntityPosition(veh, true)
                else
                    SetEntityCoords(pPed, safePos.x, safePos.y, safePos.z, false, false, false, true)
                end
            end

            if heading then
                if inVehicle then
                    SetEntityHeading(veh, heading)
                else
                    SetEntityHeading(pPed, heading)
                end
            end
        end

        if inVehicle then
            if vehicleRestoreVisibility then
                NetworkFadeInEntity(veh, true)
                if not pedRestoreVisibility then
                    SetEntityVisible(pPed, false, false)
                end
            end
            FreezeEntityPosition(veh, false)
        else
            if pedRestoreVisibility then
                NetworkFadeInEntity(pPed, true)
            end
            FreezeEntityPosition(pPed, false)
        end

        DoScreenFadeIn(500)
        SetGameplayCamRelativePitch(0.0, 1.0)

        return true
    else
        local pPed = ped or PlayerPedId()

        RequestCollisionAtCoord(pos.x, pos.y, pos.z);

        SetEntityCoords(pPed, pos.x, pos.y, pos.z, false, false, false, true);

        if heading then
            SetEntityHeading(pPed, heading)
        end

        if func then
            func()
        end

        return true
    end
end
