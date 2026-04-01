RegisterNetEvent('kIdentity:checkIdentity', function()
    local src = source

    BridgeServer:HasIdentity(src, function(hasIdentity)
        if hasIdentity then
            BridgeServer:LoadIdentity(src, function(identity)
                TriggerClientEvent('kIdentity:checkIdentity:response', src, true, identity)
            end)
        else
            TriggerClientEvent('kIdentity:checkIdentity:response', src, false, nil)
        end
    end)
end)

RegisterNetEvent('kIdentity:saveIdentity', function(data)
    local src = source
    if not data then return end

    if not data.firstName or data.firstName == "" then
        print('[kIdentity] Error: First name is required')
        return
    end

    if not data.lastName or data.lastName == "" then
        print('[kIdentity] Error: Last name is required')
        return
    end

    local dob = nil
    if data.dateOfBirth then
        dob = string.format('%04d-%02d-%02d',
            data.dateOfBirth.year or 2000,
            data.dateOfBirth.month or 1,
            data.dateOfBirth.day or 1
        )
    end

    local identity = {
        firstName = data.firstName,
        lastName = data.lastName,
        dateOfBirth = dob,
        nationality = data.nationality or 0,
        gender = data.gender or "male"
    }

    BridgeServer:SaveIdentity(src, identity, function(success)
        if success then
            print(('[kIdentity] Identity saved for player %d: %s %s'):format(src, identity.firstName, identity.lastName))

            local sex = identity.gender == "female" and "f" or "m"

            TriggerClientEvent("esx_identity:completedRegistration", src)

            TriggerEvent("esx_identity:completedRegistration", src, {
                firstname = identity.firstName,
                lastname = identity.lastName,
                dateofbirth = identity.dateOfBirth,
                sex = sex
            })

            TriggerClientEvent('kIdentity:identitySaved', src, identity)
        else
            print(('[kIdentity] Failed to save identity for player %d'):format(src))
            TriggerClientEvent('kIdentity:identitySaveFailed', src)
        end
    end)
end)

RegisterNetEvent('kIdentity:loadIdentity', function()
    local src = source

    BridgeServer:LoadIdentity(src, function(identity)
        if identity then
            TriggerClientEvent('kIdentity:identityLoaded', src, identity)
        end
    end)
end)

exports('GetPlayerIdentity', function(src)
    local identity = nil
    BridgeServer:LoadIdentity(src, function(data)
        identity = data
    end)
    local timeout = 50
    while identity == nil and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end
    return identity
end)

exports('HasPlayerIdentity', function(src)
    local hasIdentity = nil
    BridgeServer:HasIdentity(src, function(result)
        hasIdentity = result
    end)
    local timeout = 50
    while hasIdentity == nil and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end
    return hasIdentity or false
end)
