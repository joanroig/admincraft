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
| **Host or IP of the bridge** | The machine running the `websocket` container. | Tailscale address, `ts.net` hostname, or public IP. |
| **Bridge port** | The port the bridge listens on. | `8080` normally, `443` behind Tailscale Funnel. |
| **Bridge secret key** | The bridge's own key, used to sign the token Admincraft sends. | `SECRET_KEY` in the bridge's `docker-compose.yml`. |
| **Connection security** | How the app-to-bridge hop is protected. | See [connection security](connection-security.md). |

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

## Worked example: Bedrock over Tailscale Funnel

The setup from the [Bedrock guide](../server/SERVER_SETUP.md#alternative-tailscale-funnel-no-app-on-the-client):

| Field | Value |
| --- | --- |
| Minecraft edition | `Bedrock Edition` |
| Host or IP of the bridge | `my-server.tailnet-name.ts.net` |
| Bridge port | `443` |
| Bridge secret key | the `SECRET_KEY` from your compose file |
| Connection security | `Public certificate` |

The address preview under the dropdown should read `wss://my-server.tailnet-name.ts.net:443`.

## Worked example: Java on a private Tailscale network

| Field | Value |
| --- | --- |
| Minecraft edition | `Java Edition` |
| Host or IP of the bridge | `100.101.102.103` |
| Bridge port | `8080` |
| Bridge secret key | the `SECRET_KEY` from your compose file |
| Connection security | `Private network` |

The preview reads `ws://100.101.102.103:8080`. That is unencrypted by design, and safe only because Tailscale already encrypts the route. It will not work from the hosted web app: see [using the web app](web-app.md#tailscale-in-the-web-app).

## If it will not connect

Work down the chain, since each step rules out everything before it:

1. **Is the preview the address you expect?** It is shown live under the security dropdown.
2. **Is the port the bridge's port?** Not `19132` (Bedrock game), not `25575` (Java RCON).
3. **Is the key the bridge's `SECRET_KEY`?** Not the RCON password, not the Minecraft allowlist.
4. **Does the security mode match the address?** `Private network` gives `ws://` and only works over a private route. `Public certificate` needs a certificate the device already trusts.
5. **Can the device reach the host at all?** With Tailscale, both ends must be on the tailnet and connected.
