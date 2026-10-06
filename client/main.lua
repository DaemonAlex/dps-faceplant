--[[
    dps-faceplant client/main.lua
    Registers the app on the lb-phone, answers the page, and does the two things
    only the game can: name where the player is, and set a GPS waypoint.
]]

local APP = Config.AppIdentifier
-- Absolute address: the page and icon load inside the phone's frame, where
-- relative paths do not resolve.
local ICON = 'https://cfx-nui-' .. GetCurrentResourceName() .. '/ui/faceplant-icon.png'

local function registerPhoneApp()
    local ok, err = pcall(function()
        exports['lb-phone']:AddCustomApp({
            identifier = APP,
            name = Config.AppName,
            description = Config.AppDescription,
            developer = Config.AppDeveloper,
            defaultApp = true,
            size = 120,
            ui = GetCurrentResourceName() .. '/ui/index.html',
            icon = ICON,
        })
    end)
    if not ok then print('^1[dps-faceplant] AddCustomApp failed: ' .. tostring(err) .. '^7') end
end

-- Register on start, and again whenever the phone restarts after us, or the
-- icon disappears from the phone until this resource restarts too.
local function registerWhenReady(triesLeft)
    local state = GetResourceState('lb-phone')
    if state == 'started' then
        registerPhoneApp()
    elseif state == 'starting' and triesLeft > 0 then
        SetTimeout(3000, function() registerWhenReady(triesLeft - 1) end)
    end
end
SetTimeout(2000, function() registerWhenReady(5) end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'lb-phone' then return end
    SetTimeout(5000, registerPhoneApp)
end)

-- Tell the open page to start fresh on logout or character switch.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    pcall(function() exports['lb-phone']:SendCustomAppMessage(APP, { action = 'reset' }) end)
    pcall(function() exports['lb-tablet']:SendCustomAppMessage(APP, 'reset', false) end)
end)

local function whereAmI()
    local c = GetEntityCoords(cache.ped)
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(c.x, c.y, c.z))
    if street == '' or street == 'NULL' then street = nil end
    local zone = GetLabelText(GetNameOfZone(c.x, c.y, c.z))
    if zone == '' or zone == 'NULL' then zone = nil end
    if street and zone then return street .. ', ' .. zone end
    return street or zone or 'Unknown area'
end

local function ask(name, fallback, ...)
    local ok, result = pcall(lib.callback.await, name, false, ...)
    if ok and result ~= nil then return result end
    return fallback
end

local OFFLINE = { ok = false, message = 'No answer from the city. Try again in a moment.' }

RegisterNUICallback('state', function(_, cb)
    local s = ask('dps-faceplant:state', { online = false })
    if type(s) == 'table' then s.where = whereAmI() end
    cb(s)
end)

RegisterNUICallback('open', function(data, cb)
    if type(data) == 'table' then data.where = whereAmI() end
    cb(ask('dps-faceplant:open', OFFLINE, data))
end)

RegisterNUICallback('ticket', function(data, cb)
    cb(ask('dps-faceplant:ticket', OFFLINE, type(data) == 'table' and data.id))
end)

RegisterNUICallback('reply', function(data, cb)
    cb(ask('dps-faceplant:reply', OFFLINE, data))
end)

RegisterNUICallback('queue', function(_, cb)
    cb(ask('dps-faceplant:queue', OFFLINE))
end)

RegisterNUICallback('claim', function(data, cb)
    cb(ask('dps-faceplant:claim', OFFLINE, type(data) == 'table' and data.id))
end)

RegisterNUICallback('close', function(data, cb)
    cb(ask('dps-faceplant:close', OFFLINE, data))
end)

RegisterNUICallback('duty', function(data, cb)
    cb(ask('dps-faceplant:duty', OFFLINE, type(data) == 'table' and data.on == true))
end)

-- Staff tab: set a waypoint to where a ticket was sent from.
RegisterNUICallback('gps', function(data, cb)
    local x, y = tonumber(data and data.x), tonumber(data and data.y)
    if not x or not y or math.abs(x) > 10000 or math.abs(y) > 10000 then return cb({ ok = false }) end
    SetNewWaypoint(x + 0.0, y + 0.0)
    cb({ ok = true })
end)
