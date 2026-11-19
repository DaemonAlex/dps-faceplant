<p align="center"><img src=".github/dps-logo.svg" alt="DelPerroSands" width="360"></p>

# dps-faceplant

**Faceplant** is DelPerroSands' city app for help, reports and staff tools, on the
lb-phone and the lb-tablet. It is the in-city side of
[delperrosands.com](https://delperrosands.com): every ticket, reply, photo, duty
shift and ban is the same record on the phone and on the website.

This is a server and staff app. It is not the Faceplant social feed.

## What it is for

A player who needs staff used to leave the city, open Discord or the website, and write it all
out again. Staff had to switch windows to see it. Faceplant puts the ticket in the player's hand
while they are still standing where it happened, with the place, the time and photos attached.
Staff answer from the same phone, and the website keeps the one record.

## What players get

| Tab | What it does |
| --- | --- |
| **Help** | Open a ticket: Get help, Report a player, Harassment, Bug report, Refund request, Staff complaint. Add up to 4 photos from the phone gallery. The location and time are added for staff. |
| **My tickets** | Their tickets, their status, and staff replies. They can reply and add more photos. Videos are added on the website, on the same ticket. |
| **News** | City news from staff, and where to read the rules. |

A player with an active ban sees how to appeal on the website instead of the form.

## What staff get (Staff tab, staff only)

- Clock in and out. The shift shows on the website's staff board and ends by itself when they leave the city.
- The queue of open tickets they are allowed to handle (the website decides this by rank).
- Claim, reply (or write a staff-only note), close with an outcome, and **Set GPS** to where the ticket was sent from.
- Refunds and appeals are decided on the website.

## Bans

- **Join check:** a player banned on the website is refused at connect, with the reason and the appeal link. If the website does not answer in 5 seconds the player is let in: a website outage never locks the city.
- **Sync, every 60 seconds:** players already in the city who are banned on the website are removed.
- **In-game admin menu bans** (wasabi_adminmenu) are copied onto the player's website record by the website itself.

## How it links (and why it is safe)

```
phone page ─► client/main.lua ─► server/main.lua ─► website API on our own network
                                  (server-only key)    10.10.10.30:3000/portal-api
```

- The page never talks to the website. The server does, with the key in the
  server-only convar `dps_faceplant_key`.
- The website accepts the key **only** from the game server's own address. It
  answers "not found" to everyone else, including the internet.
- For each player the website hands the server a short session (12 hours),
  found or made by the player's Discord ID. The server then uses the website's
  normal doors, so ranks, limits and the audit log are exactly the website's.
- Phone photos (Fivemanage links) are downloaded by the website, checked for
  their real type, and kept privately with the ticket. Only the phone's photo
  host is accepted.

## On its own, and with other scripts

**On its own.** The app needs `lb-phone` to show, and the DelPerroSands website to hold the
tickets. There is no version with free scripts only. If the website does not answer, the app
says it is offline and players can still join the city.

**With a paid phone and tablet (lb-phone, lb-tablet).** Faceplant is an app on the home screen of
both. Photos come from the phone's own gallery: take one with the Camera app, then add it to the
ticket. The script uses the public custom app exports and the gallery picker only, so a phone or
tablet update does not break it. It adds the app again when `lb-phone` restarts. The tablet is
optional. Every tablet call is guarded.

**With the website (delperrosands.com).** Every ticket, reply, photo, duty shift and ban is the
same record in both places. The website decides ranks, limits and who can handle which ticket.
The game server only passes things along with a key that players never see.

**With a paid admin menu (wasabi_adminmenu).** A ban made in the admin menu is copied onto the
player's website record by the website. This script does not call the admin menu, so an admin
menu update does not break it. Bans made on the website are enforced here at connect and every
60 seconds.

**With Discord.** A player is matched to their website account by their Discord ID. Players need
Discord open when they start FiveM.

## Requirements

- `ox_lib`
- `lb-phone` (paid)
- `lb-tablet` (paid, optional)
- The DelPerroSands website portal API, reachable from the game server

## Install

1. Put this folder in `resources/[dps]/dps-faceplant`.
2. Create `server-data/faceplant-secret.cfg` (owner-only, never committed):
   ```
   set dps_faceplant_key "<the GAME_KEY from /opt/dps-portal/game.env>"
   ```
   and add `exec faceplant-secret.cfg` to `server.cfg` **before** the resources start.
3. Add the tablet entry to `lb-tablet/config/config.lua` → `Config.CustomApps`:
   ```lua
   {
       identifier = 'dps_faceplant',
       name = 'Faceplant',
       description = 'City help, reports and staff tools',
       developer = 'DelPerroSands',
       size = 120,
       defaultApp = true,
       ui = 'https://cfx-nui-dps-faceplant/ui/index.html',
   },
   ```
4. `[dps]` starts after `[rp]`, so ox_lib and lb-phone are already up.
5. Full restart (`fx restart`).

Players need Discord open when they start FiveM; that is how the city knows who they are.

## Tests

```
lua5.4 tests/run.lua
```

## Not in this version

- A phone notification when staff reply (the page refreshes every 30 seconds while open).
- Viewing photos inside the app (staff view them on the website).
- Blocking players who are not city members (whitelist) is a separate decision.

## Configuration

`config.lua`:

| Setting | Meaning |
|---|---|
| `Config.AppIdentifier`, `AppName`, `AppDescription`, `AppDeveloper` | How the app shows on the phone and tablet. |
| `Config.PortalUrl` | The website's API on the private network. Never the public address. |
| `Config.WebsiteUrl` | The address shown to players for appeals and rules. |
| `Config.SyncSeconds` | How often the game asks the website for new bans. Default 60. |
| `Config.JoinCheckTimeoutMs` | How long the join check waits for the website before it lets the player in. Default 5000. |
| `Config.MaxPhotos` | Photos on one ticket or reply. Default 4. |

The key is not in `config.lua`. It is the server-only convar `dps_faceplant_key`.

## Recent changes

- **12 November 2026.** README: what it is for, how it works alone and with paid scripts, other
  DPS scripts.
- **25 October 2026.** Synced with the live server.
- **8 October 2026.** First version: help, reports, harassment, bugs and staff tools on the phone
  and tablet.
- **6 October 2026.** The location line and buttons use plain text. Emoji showed as boxes.

## Author

Made by [DaemonAlex](https://github.com/DaemonAlex) for DelPerroSands.

## Other DPS scripts

All of these are made for DelPerroSands and run together on one Qbox server. Each one works on
its own. The ones marked "pairs with" do more when both are running.

| Script | What it does |
|---|---|
| [dps-inventory](https://github.com/DaemonAlex/dps-inventory) | The inventory: ox_inventory with equipment slots, backpacks, armour plates and a self status panel, in the DelPerroSands colours. |
| [dps-medical](https://github.com/DaemonAlex/dps-medical) | Patient records, illness and diagnostic tests. A companion to wasabi_ambulance. Pairs with dps-inventory: symptoms and diagnoses show on the status panel. |
| [dps-insurance](https://github.com/DaemonAlex/dps-insurance) | Ties m-Insurance into the MDT, impound, hospital and medical chart, and raises premiums for incidents other scripts report. Pairs with dps-medical and dps-fuel. |
| [dps-studio](https://github.com/DaemonAlex/dps-studio) | Build rooms, doors and portals in game from one panel (`/studio`), with owners and managers so staff do not have to support them. |
| [dps-shops](https://github.com/DaemonAlex/dps-shops) | Shop clerks who greet, react to robberies, talk back through dps-ainpcs and remember trouble, plus player-owned stores with delivery runs. Pairs with dps-ainpcs. |
| [dps-fleet](https://github.com/DaemonAlex/dps-fleet) | Vehicle browser and workshop on one panel: extras, liveries and mods for emergency vehicles. |
| [dps-parking](https://github.com/DaemonAlex/dps-parking) | Parking with valet, impound, violations and reserved spots. |
| [dps-vehiclepersistence](https://github.com/DaemonAlex/dps-vehiclepersistence) | Vehicles stay where they were parked. Pairs with dps-parking. |
| [dps-towjob](https://github.com/DaemonAlex/dps-towjob) | Queue-based tow job with jg-mechanic integration. |
| [dps-services](https://github.com/DaemonAlex/dps-services) | Request a tow and follow it live on the lb-phone and lb-tablet. Pairs with dps-towjob. |
| [dps-autoshops](https://github.com/DaemonAlex/dps-autoshops) | Self-service repair shops when no mechanic is on duty. |
| [dps-cityworker](https://github.com/DaemonAlex/dps-cityworker) | City infrastructure job and career. |
| [dps-ainpcs](https://github.com/DaemonAlex/dps-ainpcs) | NPCs you can talk to, with trust, quests and intel. Other scripts can make their own NPCs talk (dps-shops clerks). |
| [dps-badpeds](https://github.com/DaemonAlex/dps-badpeds) | Police interaction with NPCs: stops, arrests, intel and jail records. |
| [dps-gangwars](https://github.com/DaemonAlex/dps-gangwars) | Ambient gang NPCs, territory population and war reinforcements. |
| [dps-rotations](https://github.com/DaemonAlex/dps-rotations) | Moves dealers, harvests and other spots on a fixed schedule. |
| [dps-trains](https://github.com/DaemonAlex/dps-trains) | The train system. Pairs with dps-trains-stock, dps-traintools and dps-transitapp. |
| [dps-transitapp](https://github.com/DaemonAlex/dps-transitapp) | Live train arrival boards on the lb-phone. |
| [dps-chat](https://github.com/DaemonAlex/dps-chat) | A command box for voice-only servers. No chat feed. |
| [dps-filmmode](https://github.com/DaemonAlex/dps-filmmode) | One key hides every HUD layer and gives a smooth free camera for recording. |
| [dps-fuel](https://github.com/DaemonAlex/dps-fuel) | Gas station drive-offs for the ox_fuel nozzle: ripped hose, pump fire, station camera and a police call, by odds. Pairs with dps-insurance. |
| [dps-voice](https://github.com/DaemonAlex/dps-voice) | Spoken lines for NPCs, station announcements, dispatch and shops, from local voice models first. Pairs with dps-ainpcs. |
| [dps-bags](https://github.com/DaemonAlex/dps-bags) | Real bags for ox_inventory: the bag you carry shows on your character. |
| [dps-items](https://github.com/DaemonAlex/dps-items) | Item rules for ox_inventory: locked items, glovebox seats and an exploit watch. |
| [dps-furniture](https://github.com/DaemonAlex/dps-furniture) | Puts streamed furniture packs into the qs-housing furniture shop. |
| [dps-shellbrowser](https://github.com/DaemonAlex/dps-shellbrowser) | Staff tool to look at every qs-housing shell and set its door. |
| [dps-signs](https://github.com/DaemonAlex/dps-signs) | Rotates city messages across the SmartSigns road boards. |
| [dps-stationclear](https://github.com/DaemonAlex/dps-stationclear) | Hides map props that are in the way and keeps stray game peds off chosen spots. |
| [dps-citymap](https://github.com/DaemonAlex/dps-citymap) | A ready-made map of the whole city, cut into tiles for in-game screens. |
| [dps-cayo](https://github.com/DaemonAlex/dps-cayo) | Switches on the game's own Cayo Perico island, and nothing else. |
| [dps-aviation](https://github.com/DaemonAlex/dps-aviation) | Flight behaviour: aircraft idle instead of cutting out, sane taxi speed, a real start sequence. |
| [dps-airlines](https://github.com/DaemonAlex/dps-airlines) | Airlines job: passenger flights, cargo, charters, flight school and maintenance. |
| [dps-traintools](https://github.com/DaemonAlex/dps-traintools) | Rider tools for trains: board, sit, get off at a stop, ambient passengers. Pairs with dps-trains. |
| [dps-trains-stock](https://github.com/DaemonAlex/dps-trains-stock) | Train models and carriage sets for the train system. No scripts. Pairs with dps-trains. |
| [dps-traintracks](https://github.com/DaemonAlex/dps-traintracks) | Extra train track data. No scripts. Pairs with dps-trains. |
| [dps-crossings](https://github.com/DaemonAlex/dps-crossings) | Level crossings that close when a train comes. Pairs with dps-trains. |
| [dps-transit](https://github.com/DaemonAlex/dps-transit) | Passenger rail planning and scheduling (older system; dps-trains runs today). |
| [dps-maritime](https://github.com/DaemonAlex/dps-maritime) | Dock work and boat deliveries with progression. |
| [dps-maritime-maps](https://github.com/DaemonAlex/dps-maritime-maps) | Map files for the Jetsam docks, the map half of dps-maritime. |
| [dps-proracing](https://github.com/DaemonAlex/dps-proracing) | Circuit racing with lobbies, an AI practice grid and lap times. |
| [dps-carmenu](https://github.com/DaemonAlex/dps-carmenu) | Staff vehicle browser and spawner over the live Qbox vehicle list. |
| [dps-clothingbrowser](https://github.com/DaemonAlex/dps-clothingbrowser) | Staff tool to browse, identify and export clothing and uniforms. |
| [dps-lootpeds](https://github.com/DaemonAlex/dps-lootpeds) | Loot dead NPCs, with loot tables per model. |
| [dps-hookers](https://github.com/DaemonAlex/dps-hookers) | Adults-only RP (18+), adapted from MH Hookers by MaDHouSe. |
| [dps-weatherbridge](https://github.com/DaemonAlex/dps-weatherbridge) | Lets qb-weathersync and Renewed-Weathersync scripts work with night_natural_disasters. |
| [dps-fixes](https://github.com/DaemonAlex/dps-fixes) | Small server fixes kept in one resource. |
| [dps-bucketfix](https://github.com/DaemonAlex/dps-bucketfix) | Puts players back in the main world after spawning. |
| [dps-unfocus](https://github.com/DaemonAlex/dps-unfocus) | One key that frees a player stuck in a menu. |
| [dps-welcomecam](https://github.com/DaemonAlex/dps-welcomecam) | Aims the first camera a new player sees. |
| [dps-handlingdump](https://github.com/DaemonAlex/dps-handlingdump) | Developer tool: saves the stock handling of every vanilla vehicle. |
| [dps-weaponsounds](https://github.com/DaemonAlex/dps-weaponsounds) | Custom weapon sounds (planning; no code yet). |
| [dps-events](https://github.com/DaemonAlex/dps-events) | Playtime reward events (planning; no code yet). |
