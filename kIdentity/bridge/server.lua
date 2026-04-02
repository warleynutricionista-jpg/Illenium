if not IsDuplicityVersion() then return end

BridgeServer = BridgeServer or {}

local IdentifierCache = {}
local PlayerIdentity = {}
local AlreadyRegistered = {}

AddEventHandler("playerDropped", function()
    local src = source
    local identifier = IdentifierCache[src]
    IdentifierCache[src] = nil

    if identifier then
        PlayerIdentity[identifier] = nil
        AlreadyRegistered[identifier] = nil
    end
end)

local function GetLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 8) == "license:" then
            return id
        end
    end
    return GetPlayerIdentifiers(source)[1] or "unknown"
end

function BridgeServer:GetIdentifier(source)
    if IdentifierCache[source] then
        return IdentifierCache[source]
    end

    local identifier = nil

    if Bridge.Framework == "esx" and Bridge.Object then
        local xPlayer = Bridge.Object.GetPlayerFromId(source)
        identifier = xPlayer and xPlayer.identifier

    elseif Bridge.Framework == "qbcore" and Bridge.Object then
        local Player = Bridge.Object.Functions.GetPlayer(source)
        identifier = Player and Player.PlayerData.citizenid

    elseif Bridge.Framework == "qbox" and Bridge.Object then
        local player = Bridge.Object:GetPlayer(source)
        identifier = player and player.PlayerData.citizenid
    end

    identifier = identifier or GetLicense(source)
    IdentifierCache[source] = identifier

    return identifier
end

local function SetESXPlayerData(xPlayer, data)
    local fullName = ("%s %s"):format(data.firstName, data.lastName)
    local source = xPlayer.source or xPlayer.getSource()

    xPlayer.setIdentity({
        firstname = data.firstName,
        lastname = data.lastName,
        dob = data.dateOfBirth,
        sex = data.sex,
        height = data.height
    });


    -- xPlayer.setName(fullName)
    -- xPlayer.set("firstName", data.firstName)
    -- xPlayer.set("lastName", data.lastName)
    -- xPlayer.set("dateofbirth", data.dateOfBirth)
    -- xPlayer.set("sex", data.sex)

    local state = Player(source).state
    state:set("name", fullName, true)
    state:set("firstName", data.firstName, true)
    state:set("lastName", data.lastName, true)
    state:set("dateofbirth", data.dateOfBirth, true)
    state:set("sex", data.sex, true)

    TriggerClientEvent("esx_identity:setPlayerData", source, data)
end

local function OnESXIdentitySaved(source, identifier, identity, sex)
    local xPlayer = Bridge.Object.GetPlayerFromId(source)
    if xPlayer then
        SetESXPlayerData(xPlayer, {
            firstName = identity.firstName,
            lastName = identity.lastName,
            dateOfBirth = identity.dateOfBirth,
            sex = sex
        })
    end

    AlreadyRegistered[identifier] = true
    PlayerIdentity[identifier] = nil

    TriggerClientEvent("esx_identity:setPlayerData", source, {
        firstName = identity.firstName,
        lastName = identity.lastName,
        dateOfBirth = identity.dateOfBirth,
        sex = sex
    })

    print(('[kIdentity] Identity saved successfully for %s %s'):format(identity.firstName, identity.lastName))
end

function BridgeServer:SaveIdentity(source, identity, cb)
    local identifier = self:GetIdentifier(source)
    local sex = identity.gender == "female" and "f" or "m"

    print(('[kIdentity] SaveIdentity called for source %d, framework: %s'):format(source, Bridge.Framework))
    print(('[kIdentity] Identifier: %s'):format(identifier))
    print(('[kIdentity] Data: %s %s, DOB: %s, Gender: %s'):format(
        identity.firstName or "nil",
        identity.lastName or "nil",
        identity.dateOfBirth or "nil",
        identity.gender or "nil"
    ))

    if Bridge.Framework == "esx" and Bridge.Object then
        print(('[kIdentity] Saving identity for identifier: %s'):format(identifier))

        MySQL.query("SELECT identifier FROM users WHERE identifier = ?", { identifier }, function(result)
            if result and result[1] then
                print('[kIdentity] User exists, updating...')
                MySQL.update([[
                    UPDATE users SET
                        identity = ?
                    WHERE identifier = ?
                ]], {
                    json.encode({
                        firstname = identity.firstName,
                        lastname = identity.lastName,
                        dob = identity.dateOfBirth,
                        sex = (identity.gender == "male" and 0 or 1),
                    }),
                    identifier
                }, function(rowsChanged)
                    print(('[kIdentity] MySQL update result: %d rows changed'):format(rowsChanged or 0))
                    if rowsChanged > 0 then
                        OnESXIdentitySaved(source, identifier, identity, sex)
                    end
                    if cb then cb(rowsChanged > 0) end
                end)
            else
                print('[kIdentity] User does not exist, creating...')

                local ssn = string.format("%03d-%02d-%04d",
                    math.random(100, 999),
                    math.random(10, 99),
                    math.random(1000, 9999)
                )

                MySQL.insert([[
                    INSERT INTO users (
                        identifier, firstname, lastname, dateofbirth, sex, ssn,
                        accounts, `group`, inventory, job, job_grade, loadout, position, skin, status, is_dead
                    ) VALUES (
                        ?, ?, ?, ?, ?, ?,
                        '{"bank":0,"money":500,"black_money":0}', 'user', '{}', 'unemployed', 0, '{}',
                        '{"x":-269.4,"y":-955.3,"z":31.2}', NULL, '{}', 0
                    )
                ]], {
                    identifier,
                    identity.firstName,
                    identity.lastName,
                    identity.dateOfBirth,
                    sex,
                    ssn
                }, function(insertId)
                    print(('[kIdentity] MySQL insert result: id %s'):format(tostring(insertId)))
                    if insertId then
                        OnESXIdentitySaved(source, identifier, identity, sex)
                        if cb then cb(true) end
                    else
                        if cb then cb(false) end
                    end
                end)
            end
        end)

    elseif (Bridge.Framework == "qbcore" or Bridge.Framework == "qbox") and Bridge.Object then
        local Player = Bridge.Framework == "qbox"
            and Bridge.Object:GetPlayer(source)
            or Bridge.Object.Functions.GetPlayer(source)

        if Player then
            local charinfo = Player.PlayerData.charinfo or {}
            charinfo.firstname = identity.firstName
            charinfo.lastname = identity.lastName
            charinfo.birthdate = identity.dateOfBirth
            charinfo.nationality = identity.nationality
            charinfo.gender = identity.gender == "female" and 1 or 0

            if Player.Functions and Player.Functions.SetPlayerData then
                Player.Functions.SetPlayerData("charinfo", charinfo)
            else
                Player.PlayerData.charinfo = charinfo
            end

            local tableName = Bridge.Framework == "qbox" and "players" or "players"
            MySQL.update(("UPDATE %s SET charinfo = ? WHERE citizenid = ?"):format(tableName), {
                json.encode(charinfo),
                identifier
            }, function(rowsChanged)
                if cb then cb((rowsChanged or 0) > 0) end
            end)
        else
            if cb then cb(false) end
        end

    else
        MySQL.query([[
            INSERT INTO player_identity (license, firstname, lastname, dateofbirth, nationality, gender)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                firstname = VALUES(firstname),
                lastname = VALUES(lastname),
                dateofbirth = VALUES(dateofbirth),
                nationality = VALUES(nationality),
                gender = VALUES(gender)
        ]], {
            identifier,
            identity.firstName,
            identity.lastName,
            identity.dateOfBirth,
            identity.nationality,
            identity.gender
        }, function(result)
            if cb then cb(result and result.affectedRows > 0) end
        end)
    end
end

function BridgeServer:LoadIdentity(source, cb)
    local identifier = self:GetIdentifier(source)

    if Bridge.Framework == "esx" and Bridge.Object then
        local xPlayer = Bridge.Object.GetPlayerFromId(source)
        if xPlayer then
            MySQL.query("SELECT identity FROM users WHERE identifier = ?", { identifier }, function(result)
                if result and result[1] and result[1].identity and result[1].identity ~= "" then
                    local identity = json.decode(result[1].identity)
                    cb({
                        firstName = result[1].firstname,
                        lastName = result[1].lastname,
                        dateOfBirth = result[1].dateofbirth,
                        sex = result[1].sex,
                        gender = result[1].sex == "f" and "female" or "male"
                    })
                else
                    cb(nil)
                end
            end)
        else
            cb(nil)
        end

    elseif (Bridge.Framework == "qbcore" or Bridge.Framework == "qbox") and Bridge.Object then
        local Player = Bridge.Framework == "qbox"
            and Bridge.Object:GetPlayer(source)
            or Bridge.Object.Functions.GetPlayer(source)

        if Player and Player.PlayerData.charinfo then
            local charinfo = Player.PlayerData.charinfo
            cb({
                firstName = charinfo.firstname,
                lastName = charinfo.lastname,
                dateOfBirth = charinfo.birthdate,
                nationality = charinfo.nationality,
                gender = charinfo.gender == 1 and "female" or "male"
            })
        else
            cb(nil)
        end

    else
        MySQL.query("SELECT * FROM player_identity WHERE license = ?", { identifier }, function(result)
            if result and result[1] then
                cb({
                    firstName = result[1].firstname,
                    lastName = result[1].lastname,
                    dateOfBirth = result[1].dateofbirth,
                    nationality = result[1].nationality,
                    gender = result[1].gender
                })
            else
                cb(nil)
            end
        end)
    end
end

function BridgeServer:HasIdentity(source, cb)
    local identifier = self:GetIdentifier(source)

    if Bridge.Framework == "esx" and Bridge.Object then
        MySQL.query("SELECT identity FROM users WHERE identifier = ?", { identifier }, function(result)
            local hasIdentity = result and result[1] and result[1].identity ~= nil and result[1].identity ~= ""
            cb(hasIdentity)
        end)

    elseif (Bridge.Framework == "qbcore" or Bridge.Framework == "qbox") and Bridge.Object then
        local Player = Bridge.Framework == "qbox"
            and Bridge.Object:GetPlayer(source)
            or Bridge.Object.Functions.GetPlayer(source)

        if Player and Player.PlayerData.charinfo then
            local charinfo = Player.PlayerData.charinfo
            local hasIdentity = charinfo.firstname ~= nil and charinfo.firstname ~= ""
            cb(hasIdentity)
        else
            cb(false)
        end

    else
        MySQL.query("SELECT 1 FROM player_identity WHERE license = ?", { identifier }, function(result)
            cb(result and result[1] ~= nil)
        end)
    end
end

CreateThread(function()
    while not Bridge or not Bridge.Framework do
        Wait(100)
    end

    if Bridge.Framework ~= "esx" then return end

    RegisterNetEvent("esx:playerLoaded", function(playerId, xPlayer)
        local src = playerId or source

        if type(playerId) == "table" then
            xPlayer = playerId
            src = source
        end

        if not xPlayer then
            xPlayer = Bridge.Object.GetPlayerFromId(src)
        end

        if not xPlayer or not src or src == 0 then return end

        local identifier = xPlayer.identifier

        MySQL.query("SELECT identity FROM users WHERE identifier = ?", { identifier }, function(result)
            if result and result[1] and result[1].identity and result[1].identity ~= "" then
                local identity = json.decode(result[1].identity)
                PlayerIdentity[identifier] = {
                    firstName = result[1].firstname,
                    lastName = result[1].lastname,
                    dateOfBirth = result[1].dateofbirth,
                    sex = result[1].sex
                }
                AlreadyRegistered[identifier] = true

                local xPlayerObj = Bridge.Object.GetPlayerFromId(src)
                if xPlayerObj then
                    SetESXPlayerData(xPlayerObj, PlayerIdentity[identifier])
                end

                TriggerClientEvent("esx_identity:alreadyRegistered", src)

                PlayerIdentity[identifier] = nil
            else
                PlayerIdentity[identifier] = nil
                AlreadyRegistered[identifier] = false
                TriggerClientEvent("esx_identity:showRegisterIdentity", src)
            end
        end)
    end)

    Bridge.Object.RegisterServerCallback("esx_identity:registerIdentity", function(source, cb, data)
        local xPlayer = Bridge.Object.GetPlayerFromId(source)
        if not xPlayer then
            return cb(false)
        end

        local identifier = xPlayer.identifier

        if AlreadyRegistered[identifier] then
            TriggerClientEvent("esx:showNotification", source, "Vous êtes déjà enregistré", "error")
            return cb(false)
        end

        if not data.firstname or data.firstname == "" then
            TriggerClientEvent("esx:showNotification", source, "Prénom invalide", "error")
            return cb(false)
        end

        if not data.lastname or data.lastname == "" then
            TriggerClientEvent("esx:showNotification", source, "Nom invalide", "error")
            return cb(false)
        end

        local function formatName(name)
            return name:gsub("^%l", string.upper):gsub("%s+%l", string.upper)
        end

        local identity = {
            firstName = formatName(data.firstname),
            lastName = formatName(data.lastname),
            dateOfBirth = data.dateofbirth,
            sex = data.sex or "m",
            gender = data.sex == "f" and "female" or "male"
        }

        BridgeServer:SaveIdentity(source, identity, function(success)
            if success then
                TriggerClientEvent("esx_identity:completedRegistration", source)
            end
            cb(success)
        end)
    end)
end)
