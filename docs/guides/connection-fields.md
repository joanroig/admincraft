# What each connection field means

One idea makes the rest of this page obvious:

!!! tip "Every field describes the bridge, not the Minecraft server"
    Admincraft never talks to Minecraft directly. It talks to the **Admincraft WebSocket bridge**, and the bridge talks to Minecraft. So **Host**, **Port** and **Secret key** always describe the bridge container, on both editions.

This is the part that catches people out. A Java server has an RCON port and an RCON password, and neither of them goes in Admincraft.

## The fields

| Field | What it is | Where the value comes from |
| --- | --- | --- |
| **Alias** | A label for your own benefit. Shown in the server picker. | Anything you like. |
| **Minecraft edition** | Which kind of server the bridge should drive. Bedrock uses the container console; Java uses RCON. | Match your server. |
| **Address** | The machine running the `websocket` container. The label changes with the connection type, and names the Minecraft server instead for direct RCON. | Tailscale address, `ts.net` hostname, or public IP. |
| **Bridge port** | The port the bridge listens on. | `8080` normally, `443` behind Tailscale Funnel. |
| **Bridge secret key** | The bridge's own key, used to sign the token Admincraft sends. | `SECRET_KEY` in the bridge's `docker-compose.yml`. |
| **Connection type** | Which setup you have. The address and port fields relabel themselves to match. | See [connection security](connection-security.md), or [direct RCON](#direct-rcon-with-no-bridge). |

## Why Java does not ask for RCON details

Choosing **Java Edition** changes which backend the *bridge* uses, not where Admincraft connects. The RCON host, port and password are configured on the bridge:

```yaml
  websocket:
    environment:
      SECRET_KEY: YOUR_SECRET_KEY_HERE   # ← this is the "Bridge secret key"
      RCON_HOST: minecraft
      RCON_PORT: "25575"
      RCON_PASSWORD: CHANGE_THIS_RCON_PASSWORD
```

RCON stays on the internal Docker network and is never published to a host port. That is deliberate: RCON has no encryption, so exposing it would hand out server control in plain text.

So the edition selector is a statement about your server, and the RCON password never leaves the machine it runs on.

## Direct RCON, with no bridge

A Java server can be reached without the bridge at all: Admincraft opens an RCON
connection straight to it. Choose **Direct RCON, no bridge** as the connection
type, and the fields then describe the Minecraft server rather than a bridge.

| Field | Value |
| --- | --- |
| Minecraft edition | `Java Edition` |
| Address of the Minecraft server | the server, over Tailscale, a VPN or a LAN |
| Bridge port | `25575`, or whatever `rcon.port` in `server.properties` says |
| Bridge secret key | the `rcon.password` from `server.properties` |
| Connection type | `Direct RCON, no bridge (Java only)` |

Enable it on the server first:

```properties
enable-rcon=true
rcon.port=25575
rcon.password=a-long-random-password
```

!!! danger "Never expose the RCON port to the internet"
    RCON has no encryption whatsoever. The password and every command you send
    cross the network in clear text, and anyone who can reach the port can try
    passwords at will. Put it on Tailscale, a VPN or a LAN and leave it closed
    to the public internet. If the server is remote, this mode removes the
    bridge but **not** the need for a private network.

Two further limits:

- **Not available in the browser.** RCON is a raw TCP protocol and a web page
  cannot open one. The option is hidden in the web app; use the Windows, macOS,
  Linux or Android build, or the bridge.
- **No live console.** RCON answers commands and pushes nothing, so the terminal
  shows command replies only. Player joins and leaves never appear, and the
  player list has to be refreshed with `list` rather than watching for events.
  The bridge streams the real server log, so choose it if you want to watch the
  console.

## Worked example: Bedrock over Tailscale Funnel

The setup from the [Bedrock guide](../server/SERVER_SETUP.md#alternative-tailscale-funnel-no-app-on-the-client):

| Field | Value |
| --- | --- |
| Minecraft edition | `Bedrock Edition` |
| Address | `my-server.tailnet-name.ts.net` |
| Bridge port | `443` |
| Bridge secret key | the `SECRET_KEY` from your compose file |
| Connection type | `Public address, trusted certificate` |

The address preview under the dropdown should read `wss://my-server.tailnet-name.ts.net:443`.

## Worked example: Java on a private Tailscale network

| Field | Value |
| --- | --- |
| Minecraft edition | `Java Edition` |
| Address | `100.101.102.103` |
| Bridge port | `8080` |
| Bridge secret key | the `SECRET_KEY` from your compose file |
| Connection type | `Private network (Tailscale, VPN or LAN)` |

The preview reads `ws://100.101.102.103:8080`. That is unencrypted by design, and safe only because Tailscale already encrypts the route. It will not work from the hosted web app: see [using the web app](web-app.md#tailscale-in-the-web-app).

## If it will not connect

Work down the chain, since each step rules out everything before it:

1. **Is the preview the address you expect?** It is shown live under the security dropdown.
2. **Is the port the bridge's port?** Not `19132` (Bedrock game), not `25575` (Java RCON).
3. **Is the key the bridge's `SECRET_KEY`?** Not the RCON password, not the Minecraft allowlist.
4. **Does the connection type match the address?** `Private network` gives `ws://` and only works over a private route. A trusted certificate needs a **hostname**: a bare IP can never validate, because certificates are issued to names.
5. **Can the device reach the host at all?** With Tailscale, both ends must be on the tailnet and connected.
