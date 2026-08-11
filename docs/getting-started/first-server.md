# Connect your first server

Before starting, have these values ready:

- The server IP address or hostname.
- The Admincraft WebSocket port, normally `8080`.
- The `SECRET_KEY` configured for the WebSocket.
- The correct [connection security mode](../guides/connection-security.md).
- For **Self-signed certificate**, the server's `.crt` file.

## Add the profile

1. Open **Settings** in Admincraft.
2. Give the server a recognizable **Alias**.
3. Enter its **IP / Hostname**, **Port**, and **Secret Key**.
4. Choose **Connection Security**.
5. If you selected **Self-signed certificate**, load the certificate file.
6. Select **Save Settings**.

Admincraft reconnects using the saved values. The status in the app bar changes to **Connected** when the WebSocket accepts the connection.

## Example configurations

| Setup | Host | Port | Connection Security |
| --- | --- | ---: | --- |
| Tailscale | `100.x.y.z` | `8080` | Private network |
| Tailscale Funnel | `server.tailnet.ts.net` | `443` | Public certificate |
| Public self-signed endpoint | Public IP or DNS name | `8080` | Self-signed certificate |

!!! danger

    Never select **Private network** for a WebSocket port exposed directly to the internet. That mode uses `ws://`; it relies on Tailscale, a VPN, or a trusted LAN to encrypt the traffic.

If the connection fails, see [Troubleshooting](../troubleshooting.md).
