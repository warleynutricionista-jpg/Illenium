local opened_modules = {}

RegisterNetEvent("kIdentity:UI:ClearOpenedModules")
AddEventHandler("kIdentity:UI:ClearOpenedModules", function() opened_modules = {} end)

local function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local function OpenUI(show, page, data, props, block)
    data = data or {}
    props = props or {}

    SetNuiFocus(show, show)
    SendReactMessage('setVisible', show)

    if page then
        SendReactMessage('setPage', {page = page, props = props})
    end

    if block then
        SendReactMessage('setBlocked', block)
    end

    if data and data.event then
        if not opened_modules[page] then
            opened_modules[page] = true
            Wait(500)
        end
        SendReactMessage(data.event.message, data.event.data)
    end
end

RegisterNetEvent("kIdentity:UI:Open")
AddEventHandler("kIdentity:UI:Open", function(page, data, props, block)
    OpenUI(true, page, data, props, block)
end)

RegisterNetEvent("kIdentity:UI:SendReactMessage")
AddEventHandler("kIdentity:UI:SendReactMessage", function(data)
    SendReactMessage(data.event, data.data)
end)

RegisterNetEvent("kIdentity:UI:Close")
AddEventHandler("kIdentity:UI:Close", function()
    OpenUI(false)
end)

RegisterNetEvent("kIdentity:UI:setPage")
AddEventHandler("kIdentity:UI:setPage", function(page)
    OpenUI(true, page)
end)

RegisterNetEvent('kIdentity:UI:hideFrame', function()
    OpenUI(false)
end)

RegisterNUICallback('NUICALLBACK', function(data, cb)
    TriggerEvent('kIdentity:UI:' .. data.event, data.data)
    cb({})
end)
