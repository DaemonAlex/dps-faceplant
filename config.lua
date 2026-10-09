Config = {}

-- The app on the lb-phone (registered from client/main.lua) and the lb-tablet
-- (listed in lb-tablet/config/config.lua Config.CustomApps).
Config.AppIdentifier = 'dps_faceplant'
Config.AppName = 'Faceplant'
Config.AppDescription = 'City help, reports and staff tools'
Config.AppDeveloper = 'DelPerroSands'

-- The website's API on our own network. Never the public address: the website
-- only accepts the game key from the game server's own address.
-- The key itself is NOT here: it is the server-only convar dps_faceplant_key,
-- set in faceplant-secret.cfg (exec'd from server.cfg, never committed).
Config.PortalUrl = 'http://10.10.10.30:3000/portal-api'
Config.WebsiteUrl = 'delperrosands.com'

-- How often the game asks the website for new bans (seconds). The website also
-- copies bans made with the in-game admin menu onto the player's record.
Config.SyncSeconds = 60

-- Join check: if the website does not answer in time, let the player in.
-- A website outage must never lock the city.
Config.JoinCheckTimeoutMs = 5000

-- Phone photos attached to one ticket or reply.
Config.MaxPhotos = 4
