--[[
    dps-faceplant shared/faceplant.lua
    Small pure helpers used by the server (and the tests). No game calls here.
]]

Faceplant = Faceplant or {}

-- Ticket types a player can open from the phone, in menu order. The website
-- decides who on staff sees each one; this list only drives the menu.
Faceplant.Kinds = {
    { key = 'help',       label = 'Get help',         hint = 'Stuck, a question, or something else' },
    { key = 'report',     label = 'Report a player',  hint = 'Someone broke the rules' },
    { key = 'harassment', label = 'Harassment',       hint = 'Private: only senior staff see it' },
    { key = 'bug',        label = 'Bug report',       hint = 'Something in the city is broken' },
    { key = 'refund',     label = 'Refund request',   hint = 'Lost items or money' },
    { key = 'complaint',  label = 'Staff complaint',  hint = 'Goes only to the Head Admin and Owner' },
    { key = 'appeal',     label = 'Ban appeal',       hint = 'Ask for a ban to be reviewed' },
}

local kindSet = {}
for i = 1, #Faceplant.Kinds do kindSet[Faceplant.Kinds[i].key] = true end

function Faceplant.isKind(k)
    return type(k) == 'string' and kindSet[k] == true
end

--- The Discord ID from a player's identifiers, or nil.
function Faceplant.discordFrom(identifiers)
    if type(identifiers) ~= 'table' then return nil end
    for i = 1, #identifiers do
        local id = identifiers[i]
        if type(id) == 'string' then
            local d = id:match('^discord:(%d+)$')
            if d and #d >= 15 and #d <= 21 then return d end
        end
    end
    return nil
end

--- Trim and cap free text from the page. Returns nil when nothing is left.
function Faceplant.text(v, max)
    if type(v) ~= 'string' then return nil end
    local s = v:gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return nil end
    if #s > max then s = s:sub(1, max) end
    return s
end

--- Phone photos live on lb-phone's photo host. Anything else is refused here
--- before it reaches the website (which checks again).
function Faceplant.isPhonePhoto(url)
    if type(url) ~= 'string' or #url > 500 then return false end
    local host = url:match('^https://([%w%.%-]+)/')
    if not host then return false end
    host = host:lower()
    local function under(dom)
        return host == dom or host:sub(-(#dom + 1)) == '.' .. dom
    end
    return under('fivemanage.com') or under('fmfile.com')
end

--- What the player sees when the website refuses the join.
function Faceplant.banMessage(r, appeal)
    local untilText = 'permanent'
    local u = r['until']                       -- `until` is a Lua keyword, so no dot access
    if type(u) == 'string' then untilText = 'until ' .. u:gsub('T', ' '):sub(1, 16) .. ' (UTC)' end
    return ('You are banned from DelPerroSands (%s). Reason: %s. You can appeal at %s')
        :format(untilText, tostring(r.reason or 'not given'), appeal or 'delperrosands.com')
end

return Faceplant
