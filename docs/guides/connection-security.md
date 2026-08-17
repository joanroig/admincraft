# Connection security

The Admincraft WebSocket can execute commands and start, stop, or restart the server container. Its traffic must therefore be protected either by the network or by TLS.

## Choose the least-powerful access key

A current bridge can expose separate keys for different jobs. Put the chosen
key in the profile's **Bridge access key** field.

| Bridge variable | Logs and diagnostics | Minecraft commands | Container lifecycle |
| --- | --- | --- | --- |
| `READ_ONLY_SECRET_KEY` | Yes | No | No |
| `COMMAND_SECRET_KEY` | Yes | Yes | No |
| `ADMIN_SECRET_KEY` | Yes | Yes | Yes |
| `SECRET_KEY` | Yes | Yes | Yes; retained for compatibility |

Use different random values for enabled scopes. For a wall display or status
dashboard, use a read-only key. For daily server administration that must not
restart the host container, use a command key. Reserve the admin key for
trusted devices that need lifecycle controls.

The bridge advertises the capabilities granted to the connected key.
Admincraft then removes unavailable command suggestions and controls. Older
bridges that only define `SECRET_KEY` continue to work with full access.

## Which mode should I choose?

| Admincraft option | Address | Use it when | Certificate file |
| --- | --- | --- | --- |
| **Private network** | `ws://host:port` | Tailscale, a VPN, or a trusted LAN already encrypts and restricts the route | None |
| **Public certificate** | `wss://host:port` | The endpoint presents a certificate trusted by the operating system or browser | None |
| **Self-signed certificate** | `wss://host:port` | The endpoint uses a private certificate that you explicitly load into Admincraft | Required |

## Private network

Use this for Tailscale, another VPN, or a local network you control. Admincraft does not add TLS, so the connection preview shows `ws://`.

- Keep the WebSocket port closed to the public internet.
- Every Admincraft device must be able to reach the private address.
- An Admincraft page served over HTTPS cannot open `ws://` because browsers block mixed content.

[Configure Tailscale](../server/SERVER_SETUP.md#connect-admincraft-with-tailscale-recommended)

## Public certificate

Use this when the endpoint has a normal publicly trusted certificate, such as Tailscale Funnel, Let's Encrypt, or a TLS reverse proxy. The connection uses `wss://`, and there is no certificate file to manage in Admincraft.

[Configure Tailscale Funnel](../server/SERVER_SETUP.md#alternative-tailscale-funnel-no-app-on-the-client)

## Self-signed certificate

Use this when the WebSocket terminates TLS with a certificate that is not publicly trusted. Admincraft pins the certificate you load.

- Renewed certificates must be loaded again.
- The hostname or IP must match the certificate.
- This option is available in native apps, but not in the browser.

[Configure self-signed TLS](../server/SERVER_SETUP.md#alternative-public-access-with-self-signed-ssl)

!!! warning "Browser users"

    The hosted web app is served over HTTPS. Use **Public certificate** for the most reliable browser setup. Read [Using the web app](web-app.md) for the browser-specific constraints.
