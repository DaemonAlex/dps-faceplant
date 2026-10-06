--[[
    dps-faceplant server/main.lua
    The game side of the website link. The page never talks to the website: it
    asks this file (through the client), and this file calls the website with
    the server-only key and a short website session for that player.

    The website owns every rule (who sees which ticket, limits, the audit log).
    Nothing here decides permissions; it only passes the player's session.
]]

local KEY = GetConvar('dps_faceplant_key', '')
local BASE = Config.PortalUrl
local ORIGIN = 'https://delperrosands.com'

if KEY == '' then
    print('^1[dps-faceplant] dps_faceplant_key is not set (faceplant-secret.cfg). The app will show "offline".^7')
end

-- src -> { token, expires, discord, user, staff, kinds, rank }
local sessions = {}

--- One HTTP call to the website. Returns status, decoded body (or nil).
local function http(method, path, body, token, game)
    if KEY == '' then return 0, nil end
    local headers = { ['Content-Type'] = 'application/json', ['x-dps'] = '1', ['Origin'] = ORIGIN }
    if token then headers['Cookie'] = 'dps_session=' .. token end
    if game then headers['x-dps-game-key'] = KEY end
    local p = promise.new()
    PerformHttpRequest(BASE .. path, function(status, text)
        local ok, decoded = pcall(json.decode, text or '')
        p:resolve({ status or 0, ok and decoded or nil })
    end, method, body and json.encode(body) or '', headers)
    local r = Citizen.Await(p)
    return r[1], r[2]
end

local function errText(status, data)
    if type(data) == 'table' and type(data.error) == 'string' then return data.error end
    if status == 0 then return 'The city link is offline. Try again in a minute.' end
    return 'That did not work. Try again in a moment.'
end

local function discordOf(src)
    return Faceplant.discordFrom(GetPlayerIdentifiers(src))
end

--- The player's website session, made on first use and renewed before it runs out.
local function session(src)
    local s = sessions[src]
    if s and s.expires > os.time() + 60 then return s end
    local d = discordOf(src)
    if not d then return nil, 'nodiscord' end
    local status, data = http('POST', '/game/session', { discord = d, name = GetPlayerName(src) }, nil, true)
    if status ~= 200 or type(data) ~= 'table' or not data.token then return nil, errText(status, data) end
    s = {
        token = data.token, expires = os.time() + (data.hours or 12) * 3600 - 300, discord = d,
        user = data.user, staff = data.staff == true, kinds = data.kinds or {}, rank = data.rank_name or '',
    }
    sessions[src] = s
    return s
end

local function call(src, method, path, body, game)
    local s, why = session(src)
    if not s then return { ok = false, message = why == 'nodiscord' and 'nodiscord' or why } end
    local status, data = http(method, path, body, s.token, game)
    if status == 401 then          -- session ended on the website side: make a new one once
        sessions[src] = nil
        s, why = session(src)
        if not s then return { ok = false, message = why } end
        status, data = http(method, path, body, s.token, game)
    end
    if status ~= 200 then return { ok = false, message = errText(status, data) } end
    return { ok = true, data = data }
end

-- A player can only press so fast; the website has its own limits on top.
local lastAction = {}
local function tooFast(src)
    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < 1500 then return true end
    lastAction[src] = now
    return false
end

local function photos(list)
    local out = {}
    if type(list) ~= 'table' then return out end
    for i = 1, math.min(#list, Config.MaxPhotos) do
        if Faceplant.isPhonePhoto(list[i]) then out[#out + 1] = list[i] end
    end
    return out
end

local function attach(src, tid, list)
    local failed = 0
    for _, url in ipairs(list) do
        local r = call(src, 'POST', ('/game/tickets/%d/photo'):format(tid), { url = url }, true)
        if not r.ok then failed = failed + 1 end
    end
    return failed
end

-- ------------------------------------------------------------------ page requests
lib.callback.register('dps-faceplant:state', function(src)
    local s, why = session(src)
    if not s then
        -- No Discord linked in FiveM: the link works, but we can't tell who this is.
        local noDiscord = why == 'nodiscord'
        return { online = noDiscord, linked = not noDiscord, message = not noDiscord and why or nil }
    end
    local mine = call(src, 'GET', '/tickets/mine')
    local news = call(src, 'GET', '/news')
    local out = {
        online = true, linked = true, website = Config.WebsiteUrl,
        user = { name = s.user and s.user.name or GetPlayerName(src), level = s.user and s.user.level },
        kinds = Faceplant.Kinds, maxPhotos = Config.MaxPhotos,
        tickets = mine.ok and mine.data.items or {}, ban = mine.ok and mine.data.ban or nil,
        news = news.ok and news.data.items or {},
        staff = false,
    }
    if s.staff then
        local me = call(src, 'GET', '/staff/me')
        out.staff = { rank = s.rank, kinds = s.kinds, duty = me.ok and me.data.duty or nil }
    end
    return out
end)

lib.callback.register('dps-faceplant:open', function(src, input)
    if type(input) ~= 'table' or tooFast(src) then return { ok = false, message = 'Slow down a moment.' } end
    if not Faceplant.isKind(input.kind) then return { ok = false, message = 'Pick what the ticket is about.' } end
    local subject = Faceplant.text(input.subject, 140)
    local body = Faceplant.text(input.body, 3600)
    if not subject or not body then return { ok = false, message = 'Give it a short title and the details.' } end
    local where = Faceplant.text(input.where, 120)
    local c = GetEntityCoords(GetPlayerPed(src))
    -- The location line is read by the Staff tab's "Set GPS" button: keep its shape.
    body = body .. ('\n\n📍 %s · %.1f, %.1f\nSent from the Faceplant app in the city.'):format(where or 'Unknown area', c.x, c.y)
    local r = call(src, 'POST', '/tickets', {
        kind = input.kind, subject = subject, about = Faceplant.text(input.about, 120), body = body,
    })
    if not r.ok then return r end
    local failed = attach(src, r.data.id, photos(input.photos))
    return { ok = true, id = r.data.id, photoFailed = failed }
end)

lib.callback.register('dps-faceplant:ticket', function(src, id)
    id = tonumber(id)
    if not id then return { ok = false } end
    return call(src, 'GET', ('/tickets/%d'):format(id))
end)

lib.callback.register('dps-faceplant:reply', function(src, input)
    if type(input) ~= 'table' or tooFast(src) then return { ok = false, message = 'Slow down a moment.' } end
    local id = tonumber(input.id)
    if not id then return { ok = false } end
    local text = Faceplant.text(input.body, 4000)
    local list = photos(input.photos)
    if not text and #list == 0 then return { ok = false, message = 'Write a reply or add a photo.' } end
    if text then
        local r = call(src, 'POST', ('/tickets/%d/messages'):format(id), { body = text, internal = input.internal == true })
        if not r.ok then return r end
    end
    return { ok = true, photoFailed = attach(src, id, list) }
end)

-- ------------------------------------------------------------------ staff tab (the website checks the rank)
lib.callback.register('dps-faceplant:queue', function(src)
    return call(src, 'GET', '/staff/tickets?status=active')
end)

lib.callback.register('dps-faceplant:claim', function(src, id)
    id = tonumber(id)
    if not id or tooFast(src) then return { ok = false } end
    return call(src, 'POST', ('/tickets/%d/claim'):format(id), {})
end)

lib.callback.register('dps-faceplant:close', function(src, input)
    if type(input) ~= 'table' or tooFast(src) then return { ok = false } end
    local id = tonumber(input.id)
    if not id then return { ok = false } end
    return call(src, 'POST', ('/tickets/%d/status'):format(id), { action = 'close', outcome = Faceplant.text(input.outcome, 400) })
end)

lib.callback.register('dps-faceplant:duty', function(src, on)
    if tooFast(src) then return { ok = false, message = 'Slow down a moment.' } end
    return call(src, 'POST', '/staff/duty', { on = on == true })
end)

-- ------------------------------------------------------------------ bans: join check + sync
AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    if KEY == '' then return end
    local d = discordOf(src)
    if not d then return end                       -- whitelisting is a separate decision
    deferrals.defer()
    Wait(0)
    deferrals.update('Checking your DelPerroSands record...')
    local done = false
    SetTimeout(Config.JoinCheckTimeoutMs, function()
        if not done then done = true; deferrals.done() end   -- website slow: let them in
    end)
    local status, data = http('POST', '/game/check', { discord = d }, nil, true)
    if done then return end
    done = true
    if status == 200 and type(data) == 'table' and data.banned then
        deferrals.done(Faceplant.banMessage(data, data.appeal))
    else
        deferrals.done()
    end
end)

CreateThread(function()
    if KEY == '' then return end
    while true do
        Wait(Config.SyncSeconds * 1000)
        local online, bySrc = {}, {}
        for _, id in ipairs(GetPlayers()) do
            local d = discordOf(id)
            if d then online[#online + 1] = d; bySrc[d] = id end
        end
        local status, data = http('POST', '/game/sync', { online = online }, nil, true)
        if status == 200 and type(data) == 'table' and type(data.banned) == 'table' then
            for _, b in ipairs(data.banned) do
                local id = bySrc[b.discord]
                if id then DropPlayer(id, Faceplant.banMessage(b, data.appeal)) end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local s = sessions[src]
    sessions[src] = nil
    lastAction[src] = nil
    if s and s.staff then
        CreateThread(function() http('POST', '/game/duty-off', { discord = s.discord }, nil, true) end)
    end
end)
