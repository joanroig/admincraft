# Connect your first server

Have these ready before you start:

- Whether the server runs **Bedrock or Java**.
- The address Admincraft should reach, and the port.
- The bridge's `SECRET_KEY`, or the `rcon.password` if you are connecting straight to a Java server.
- For a self-signed endpoint, the server's `.crt` file.

If any of that is unfamiliar, [what each connection field means](../guides/connection-fields.md) explains where the values come from.

## Add the profile

On a fresh install Admincraft opens on a welcome screen: choose **Add your first server**. If you already have one, open **Settings → Servers → Add server**, or use the picker in the title bar.

1. Give the server a recognisable **Alias**.
2. Choose the **Minecraft edition**. It must match the bridge's `SERVER_TYPE`.
3. Choose the **Connection type**. Do this before the fields below, because the address and port labels change to match it.
4. Fill in the address and port. What they refer to depends on the connection type: the bridge for every type except direct RCON, where it is the Minecraft server itself.
5. Enter the **Bridge secret key**, or the RCON password for a direct connection.
6. For a self-signed endpoint, load the certificate.
7. Select **Save changes**.

The preview under the connection type shows the address that will be used, so you can check it before saving. Admincraft connects on save, and the status in the title bar becomes **Connected**.

## Example configurations

| Setup | Address | Port | Connection type |
| --- | --- | ---: | --- |
| Tailscale | `100.x.y.z` | `8080` | Private network |
| Tailscale Funnel | `server.tailnet.ts.net` | `443` | Public address, trusted certificate |
| Public self-signed endpoint | Public IP or hostname | `8080` | Public address, self-signed certificate |
| Java without a bridge | The Minecraft server | `25575` | Direct RCON, no bridge |

!!! danger "Do not use a private-network type on a public port"
    **Private network** and **Direct RCON** both send traffic unencrypted. They
    rely on Tailscale, a VPN or a trusted LAN to protect the route, and must
    never point at something reachable from the internet.

Two things the app will not let you do, so you are not left guessing:

- **A profile missing an address or key cannot connect.** The connect button stays disabled and says so, rather than failing at the transport.
- **A trusted certificate must cover the address you enter.** Use the exact
  hostname or IP address listed in the certificate. A hostname is the usual
  and most portable choice.

If the connection fails, see [Troubleshooting](../troubleshooting.md).
