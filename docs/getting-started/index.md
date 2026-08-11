# Getting started

Admincraft needs two pieces:

1. The **Admincraft app** on Windows, Android, or the web.
2. A Minecraft Bedrock server running the companion **Admincraft WebSocket** service.

The WebSocket bridges Admincraft to the Bedrock Docker console. Because that bridge can execute commands, the connection must be protected by a private encrypted network or TLS.

## Pick your route

| I already have… | Next step |
| --- | --- |
| A configured Admincraft WebSocket | [Install or open Admincraft](install.md), then [connect the server](first-server.md) |
| A Bedrock Docker server, but no WebSocket | Follow the [full server setup](../server/SERVER_SETUP.md) |
| Nothing yet | Start with the [full server setup](../server/SERVER_SETUP.md) |
| A profile exported from another device | Go directly to [Backup and transfer](../guides/backup-transfer.md#import-on-another-device) |

## Recommended setup

For a personal server, the simplest secure arrangement is:

- Minecraft and Admincraft WebSocket running together in Docker.
- Tailscale connecting the server and the device running Admincraft.
- **Private network** selected in Admincraft.
- Port `8080` kept closed to the public internet.

The [server setup guide](../server/SERVER_SETUP.md#connect-admincraft-with-tailscale-recommended) walks through that configuration.
