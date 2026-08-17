# Interface tour

This page is for using Admincraft after at least one server profile has been
saved. On a phone, the main areas appear in the bottom navigation bar. On a
wide window, the same destinations move to the side rail.

## Overview

**Overview** shows the selected server's connection state, players, world time,
difficulty, and recent activity. Live values are collected from server output
or quiet status requests and can take a moment to appear after connecting.

Use the server picker in the title bar to change servers. Each profile keeps
its own console transcript and connection settings.

## Console

**Console** shows server output and accepts commands. Useful controls include:

- Search within the visible transcript.
- Pause or resume automatic scrolling.
- Jump to the latest output when you have scrolled away from it.
- Recall command history and use command completion.
- Insert common numeric amounts such as 1, 5, 10, 20, 64, or 128.

Commands you send and recent output are stored per server on this device. Open
**Settings → Preferences → Console behavior** to choose the terminal font and
size, timestamps, output limit, automatic scrolling, text filtering, and the
default filter for common server noise.

With a current Admincraft bridge, reconnecting also replays a bounded recent
tail from the Minecraft container. Timestamped event IDs prevent the overlap
from appearing twice. Connection handshakes and automatic status queries do
not appear as ordinary console lines.

Current bridge connections also complete these diagnostic commands:

- `admincraft help` lists commands available to the current access key.
- `admincraft status`, `admincraft health`, and `admincraft uptime` inspect the
  Minecraft container.
- `admincraft info` summarizes the bridge, protocol, permission, server, and
  capabilities.
- `admincraft version` reports the installed bridge version.
- `admincraft logs [count]` replays up to 1,000 recent lines on demand.
- `admincraft start-server`, `stop-server`, and `restart-server` manage the
  container when the profile uses an admin key.

The completion strip and controls follow the capabilities advertised by the
bridge. A read-only key therefore offers diagnostics and logs without exposing
Minecraft commands; a command key omits lifecycle actions.

## Controls

**Controls** turns common commands into buttons for time, weather, difficulty,
players, game rules, and server start, stop, and restart. **Live commands** contains favorite
commands saved from the console. The server-response panel at the bottom can be
collapsed when you need more room.

Some values can be observed from server output; others are refreshed with quiet
commands or show the last value set from Admincraft. Direct RCON has fewer live
events because it cannot stream the server log.

Current bridges publish structured container state, world time, and player
counts. Admincraft uses these for the overview and diagnostics without adding
`time`, `list`, or connection messages to the visible server transcript.

The Minecraft `stop` command shuts down the game process. The controls under
**Server** instead ask the bridge to start, stop, or restart the Docker
container, so it can be started again without shell access.

## Settings

**Settings** is divided by purpose:

| Page | What belongs there |
| --- | --- |
| **Servers** | Add, select, edit, or delete connection profiles |
| **Data & Sync** | Encrypted transfer files and Google Drive profile sync |
| **Preferences** | Appearance, console behavior, and notification popups |
| **Docs** | Open this documentation site |

Device preferences are intentionally not synchronized with server profiles.
This lets each phone, browser, or desktop keep suitable fonts, layout, and
console behavior.

## Diagnostics and command audit

Open **Overview → Diagnostics** to inspect the connection state, bridge and
protocol versions, access-key permission, server state, last heartbeat, last
log and state event, advertised capabilities, and the most recent connection
error. **Copy** produces a secret-free summary suitable for an issue report.

The same panel keeps a per-server audit of user-issued commands, their source,
and whether they were sent or rejected. This is intentionally separate from
the Minecraft console transcript: background status observations are not audit
entries, and clearing console output does not turn normal server logs into
user actions.

## Notifications

Short notifications appear near the top without blocking controls underneath.
Use the bell icon to open notification history, review longer connection
errors, dismiss individual entries, or clear the list.
