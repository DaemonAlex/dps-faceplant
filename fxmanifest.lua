fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dps-faceplant'
author 'DelPerroSands'
description 'Faceplant: city help, reports and staff tools on the lb-phone and lb-tablet, linked to delperrosands.com'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/faceplant.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

-- Served into the phone and tablet frames; never a ui_page of its own.
files {
    'ui/index.html',
    'ui/faceplant-logo.svg',
    'ui/faceplant-icon.png',
}

-- lb-tablet is NOT listed: every tablet call is guarded, so a tablet restart
-- never force-stops this resource (FiveM does not restart dependents).
dependencies { 'ox_lib', 'lb-phone' }
