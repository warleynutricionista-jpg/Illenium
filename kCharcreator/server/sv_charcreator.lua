--[[
    kCharcreator - Server Events

    Plug & Play: Uses native framework tables automatically
    - ESX      -> users.skin
    - QBCore   -> playerskins
    - QBox     -> playerskins
    - Standalone -> skins
]]

-- Routing bucket (Instance isolation)
RegisterNetEvent("kCharcreator:setInstance", function(inCreator)
    local src = source
    if inCreator then
        SetPlayerRoutingBucket(src, src)
    else
        SetPlayerRoutingBucket(src, 0)
    end
end)

-- Check skin (Auto-open logic)
RegisterNetEvent("kCharcreator:checkSkin", function()
    local src = source

    BridgeServer:HasSkin(src, function(hasSkin)
        if hasSkin then
            BridgeServer:LoadSkin(src, function(skin, model)
                TriggerClientEvent("kCharcreator:checkSkin:response", src, true, skin, model, nil)
            end)
        else
            BridgeServer:GetPlayerSex(src, function(sex)
                TriggerClientEvent("kCharcreator:checkSkin:response", src, false, nil, nil, sex)
            end)
        end
    end)
end)

-- Load skin (Manual load when autoOpen is disabled)
RegisterNetEvent("kCharcreator:loadSkin", function()
    local src = source

    BridgeServer:LoadSkin(src, function(skin, model)
        if skin then
            TriggerClientEvent("kCharcreator:loadSkin:response", src, skin, model)
        end
    end)
end)

-- Save skin (After character creation)
RegisterNetEvent("kCharcreator:saveSkin", function(skin, model)
    local src = source
    if not skin then return end

    BridgeServer:SaveSkin(src, skin, model)
end)

-- Legacy events (Backwards compatibility)
RegisterNetEvent("CORE.UI:charcreator:save_character", function(data)
    if not data or not data.skin then return end
    local src = source

    BridgeServer:SaveSkin(src, data.skin, data.model)
end)

RegisterNetEvent("CORE.UI:charcreator:load_character", function()
    local src = source

    BridgeServer:LoadSkin(src, function(skin, model)
        if skin then
            TriggerClientEvent("CORE.UI:charcreator:load_character", src, skin)
        end
    end)
end)
