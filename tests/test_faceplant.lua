-- Tests for shared/faceplant.lua (pure helpers, no game calls).
dofile('shared/faceplant.lua')
local F = Faceplant

T.test('every website ticket type is in the phone menu, harassment included', function()
    for _, k in ipairs({ 'help', 'report', 'harassment', 'bug', 'refund', 'complaint', 'appeal' }) do
        T.truthy(F.isKind(k), k)
    end
end)

T.test('unknown or wrong-type kinds are refused', function()
    T.falsy(F.isKind('ban'), 'ban')
    T.falsy(F.isKind(''), 'empty')
    T.falsy(F.isKind(nil), 'nil')
    T.falsy(F.isKind(3), 'number')
end)

T.test('discord id is found among other identifiers', function()
    T.eq(F.discordFrom({ 'license:abc', 'discord:123456789012345678', 'ip:1.2.3.4' }), '123456789012345678')
end)

T.test('no discord, a bad discord, or no table gives nil', function()
    T.eq(F.discordFrom({ 'license:abc' }), nil, 'none')
    T.eq(F.discordFrom({ 'discord:12' }), nil, 'too short')
    T.eq(F.discordFrom({ 'discord:12345678901234567x' }), nil, 'not digits')
    T.eq(F.discordFrom(nil), nil, 'nil')
end)

T.test('text is trimmed, capped, and empty becomes nil', function()
    T.eq(F.text('  hi  ', 10), 'hi')
    T.eq(F.text('abcdef', 3), 'abc')
    T.eq(F.text('   ', 10), nil, 'blank')
    T.eq(F.text(5, 10), nil, 'number')
end)

T.test('phone photos from the photo host are allowed', function()
    T.truthy(F.isPhonePhoto('https://r2.fivemanage.com/abc/image.png'))
    T.truthy(F.isPhonePhoto('https://fmfile.com/x.webp'))
end)

T.test('anything else is refused as a photo', function()
    T.falsy(F.isPhonePhoto('http://r2.fivemanage.com/a.png'), 'not https')
    T.falsy(F.isPhonePhoto('https://fivemanage.com.evil.com/a.png'), 'lookalike host')
    T.falsy(F.isPhonePhoto('https://evilfivemanage.com/a.png'), 'suffix without dot')
    T.falsy(F.isPhonePhoto('https://10.10.10.30/a.png'), 'raw address')
    T.falsy(F.isPhonePhoto('https://r2.fivemanage.com/' .. string.rep('a', 600)), 'too long')
    T.falsy(F.isPhonePhoto(nil), 'nil')
end)

T.test('ban message: timed and permanent', function()
    local timed = F.banMessage({ reason = 'RDM', ['until'] = '2026-10-09T18:30:00' }, 'https://delperrosands.com/support.html')
    T.truthy(timed:find('until 2026%-10%-09 18:30 %(UTC%)'), timed)
    T.truthy(timed:find('Reason: RDM', 1, true), 'reason')
    T.truthy(timed:find('delperrosands.com/support.html', 1, true), 'appeal link')
    local perm = F.banMessage({ reason = 'Cheating' }, nil)
    T.truthy(perm:find('(permanent)', 1, true), perm)
end)
