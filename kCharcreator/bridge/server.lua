--[[
    SERVER-SIDE BRIDGE
    Native SQL integration per framework:
    - ESX      -> users.skin
    - QBCore   -> playerskins
    - QBox     -> playerskins
    - Standalone -> skins
]]

if not IsDuplicityVersion() then return end

BridgeServer = BridgeServer or {}

local IdentifierCache = {}

AddEventHandler("playerDropped", function()
    IdentifierCache[source] = nil
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

function BridgeServer:SaveSkin(source, skin, model)
    local identifier = self:GetIdentifier(source)
    local skinJson = json.encode(skin)
    model = model or "mp_m_freemode_01"

    if Bridge.Framework == "esx" then
        MySQL.update("UPDATE users SET skin = ? WHERE identifier = ?", { skinJson, identifier })
    elseif Bridge.Framework == "qbcore" or Bridge.Framework == "qbox" then
        MySQL.query([[
            INSERT INTO playerskins (citizenid, model, skin, active)
            VALUES (?, ?, ?, 1)
            ON DUPLICATE KEY UPDATE model = VALUES(model), skin = VALUES(skin), active = 1
        ]], { identifier, model, skinJson })
    else
        MySQL.query([[
            INSERT INTO skins (license, skin)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE skin = VALUES(skin)
        ]], { identifier, skinJson })
    end
end

function BridgeServer:LoadSkin(source, cb)
    local identifier = self:GetIdentifier(source)

    if Bridge.Framework == "esx" then
        MySQL.query("SELECT skin FROM users WHERE identifier = ?", { identifier }, function(result)
            if result and result[1] and result[1].skin then
                local skin = json.decode(result[1].skin)
                cb(skin, skin and skin.model)
            else
                cb(nil, nil)
            end
        end)
    elseif Bridge.Framework == "qbcore" or Bridge.Framework == "qbox" then
        MySQL.query("SELECT skin, model FROM playerskins WHERE citizenid = ? AND active = 1", { identifier }, function(result)
            if result and result[1] then
                local skin = json.decode(result[1].skin)
                cb(skin, result[1].model)
            else
                cb(nil, nil)
            end
        end)
    else
        MySQL.query("SELECT skin FROM skins WHERE license = ?", { identifier }, function(result)
            if result and result[1] then
                local skin = json.decode(result[1].skin)
                cb(skin, skin and skin.model)
            else
                cb(nil, nil)
            end
        end)
    end
end

function BridgeServer:HasSkin(source, cb)
    local identifier = self:GetIdentifier(source)

    if Bridge.Framework == "esx" then
        MySQL.query("SELECT skin FROM users WHERE identifier = ?", { identifier }, function(result)
            local hasSkin = result and result[1] and result[1].skin ~= nil and result[1].skin ~= "" and result[1].skin ~= "null"
            cb(hasSkin)
        end)
    elseif Bridge.Framework == "qbcore" or Bridge.Framework == "qbox" then
        MySQL.query("SELECT 1 FROM playerskins WHERE citizenid = ? AND active = 1", { identifier }, function(result)
            cb(result and result[1] ~= nil)
        end)
    else
        MySQL.query("SELECT 1 FROM skins WHERE license = ?", { identifier }, function(result)
            cb(result and result[1] ~= nil)
        end)
    end
end

function BridgeServer:GetPlayerSex(source, cb)
    local identifier = self:GetIdentifier(source)

    if Bridge.Framework == "esx" then
        MySQL.query("SELECT identity FROM users WHERE identifier = ?", { identifier }, function(result)
            if result and result[1] and result[1].identity then
                local identity = json.decode(result[1].identity)
                cb(identity and identity.sex or "m")
            else
                cb("m")
            end
        end)
    elseif Bridge.Framework == "qbcore" and Bridge.Object then
        local Player = Bridge.Object.Functions.GetPlayer(source)
        if Player and Player.PlayerData.charinfo then
            cb(Player.PlayerData.charinfo.gender == 1 and "f" or "m")
        else
            cb("m")
        end
    elseif Bridge.Framework == "qbox" and Bridge.Object then
        local player = Bridge.Object:GetPlayer(source)
        if player and player.PlayerData.charinfo then
            cb(player.PlayerData.charinfo.gender == 1 and "f" or "m")
        else
            cb("m")
        end
    else
        cb("m")
    end
end
