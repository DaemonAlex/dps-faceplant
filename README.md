# dps-faceplant

**Faceplant** is DelPerroSands' city app for help, reports and staff tools, on the
lb-phone and the lb-tablet. It is the in-city side of
[delperrosands.com](https://delperrosands.com): every ticket, reply, photo, duty
shift and ban is the same record on the phone and on the website.

This is a server and staff app. It is not the Faceplant social feed.

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
