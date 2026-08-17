# Choose your server setup

This section is for the person running the Minecraft server or its Admincraft
bridge. If that infrastructure already exists and you only need to use the
app, start with [Install Admincraft](install.md) instead.

Admincraft is built around [itzg's Minecraft containers](https://github.com/itzg/docker-minecraft-bedrock-server), which is where it does the most: a live console, world controls and a restart button, on Bedrock and Java alike. It also speaks plain RCON, so an existing Java server can be managed without changing anything about how it runs.

Two arrangements are therefore possible, and the difference matters enough to choose deliberately.

**Through the bridge.** A small companion container, [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket), runs beside Minecraft. It reads the container console and talks to Java RCON on the private Docker network. This is the full experience and the only one that works in a browser.

**Direct RCON.** Admincraft connects straight to a Java server's RCON port. Nothing extra to install, and it works with any Java server, containerised or not. In exchange there is no live console and no restart, and RCON has no encryption at all.

## What each setup gives you

| | itzg Bedrock + bridge | itzg Java + bridge | Any Java, direct RCON |
| --- | --- | --- | --- |
| Send commands | ✅ | ✅ | ✅ |
| Live server console | ✅ | ✅ | ❌ RCON cannot stream it |
| Time, weather, game rules | ✅ | ✅ | ✅ on refresh |
| Player list | ✅ live | ✅ live | ✅ on refresh |
| Restart the server | ✅ | ✅ | ❌ no container control |
| Works in the browser | ✅ | ✅ | ❌ no raw sockets |
| Can be encrypted without a VPN | ✅ TLS | ✅ TLS | ❌ never |
| Extra container needed | yes | yes | no |
| Docker needed | yes | yes | no |

The two "on refresh" cells are the practical difference: through the bridge the app watches the log and notices things happening, while over RCON it only knows what it last asked.

## Fastest way in

If you have a machine with Docker and want a server running now, one script does
the whole thing: it writes a compose file, generates the secrets, starts
Minecraft and the bridge, and prints what to type into Admincraft.

```bash
curl -fsSLO https://raw.githubusercontent.com/joanroig/admincraft/main/docs/server/quickstart.sh
bash quickstart.sh
```

Downloaded first rather than piped straight into a shell, so you can read what
it does before it runs. Pass `--edition java` to skip the prompt. It refuses to
touch an existing `docker-compose.yml`.

Already running a Minecraft container? Add the bridge without editing anything
you have, by layering one file on top:

```bash
curl -fsSLO https://raw.githubusercontent.com/joanroig/admincraft/main/docs/server/docker-compose.admincraft.yml
# set SECRET_KEY, and SERVER_TYPE plus the RCON values for Java
docker compose -f docker-compose.yml -f docker-compose.admincraft.yml up -d
```

Only the new container starts; Minecraft keeps running. The
[existing server guide](existing-server.md) explains the fields.

## Pick your route

| Where you are | Start here |
| --- | --- |
| **A machine with Docker** | The [quick start script](#fastest-way-in) above |
| **No server and no machine** | [Bedrock server on Oracle's free tier](../server/SERVER_SETUP.md) — a whole server, from an empty cloud account to a working world, at no cost |
| **No server yet, and you want Java** | [Set up a Java Edition server](java-server.md) |
| **Already running itzg containers** | [Add Admincraft to an existing server](existing-server.md) — no need to recreate anything |
| **A Java server that is not containerised** | [Connect over direct RCON](existing-server.md#connect-any-java-server-over-rcon) |
| **A bridge already configured** | [Install Admincraft](install.md), then [add the profile](first-server.md) |
| **A profile exported elsewhere** | [Import it](../guides/backup-transfer.md#import-on-another-device) |

## What we recommend

For a personal server: Minecraft and the bridge in Docker together, [Tailscale](https://tailscale.com) joining the server to your devices, **Private network** selected in Admincraft, and the bridge port closed to the internet. Nothing is exposed publicly and there are no certificates to manage.

If you would rather not install Tailscale on every device, [Tailscale Funnel](../server/SERVER_SETUP.md#alternative-tailscale-funnel-no-app-on-the-client) publishes the bridge on a hostname with a certificate that renews itself, which is also the only arrangement the browser build can use over the internet.
