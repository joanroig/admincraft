# Using the web app

The web version runs the same Admincraft interface without an installation, but the browser controls networking, certificates, and local storage.

## Profiles live in browser storage

Saved profiles remain on the current browser and site. They can disappear if you clear site data, use a temporary/private session, or switch browser profiles.

Create an [encrypted export](backup-transfer.md) after adding or changing important server profiles.

## HTTPS and WebSockets

The hosted Admincraft page uses HTTPS. Browsers block an HTTPS page from connecting to an unencrypted `ws://` endpoint as mixed content.

For the hosted web app, a **trusted certificate** type (`wss://`) is the most reliable choice. A private-network connection can work from an Admincraft build served over HTTP, but should never be exposed to the public internet.

### Tailscale in the web app

A Tailscale address such as `100.x.y.z` cannot be used from the hosted page. **Private network** connects over `ws://`, which the browser blocks, and `wss://` is impossible for a tailnet address because no certificate authority will issue a certificate for it.

Use **[Tailscale Funnel](../server/SERVER_SETUP.md#alternative-tailscale-funnel-no-app-on-the-client)** instead. Funnel publishes the WebSocket on a `ts.net` hostname with a certificate that renews itself, which is exactly what the browser requires:

- **IP / Hostname:** the `ts.net` hostname from `tailscale funnel status`
- **Port:** `443`
- **Connection type:** `Public address, trusted certificate`

The private tailnet address still works in the Windows and Android builds, which are not subject to mixed-content rules. So the rule of thumb is Funnel for the browser, tailnet address for the installed app.

## Self-signed certificates

Web pages cannot install or pin a certificate for a WebSocket connection. The **Self-signed certificate** option is therefore hidden in the web app.

If the browser or operating system already trusts the endpoint certificate, use **Public certificate**. Otherwise use the Windows or Android build, or place the WebSocket behind a publicly trusted TLS endpoint.

## Clipboard and downloads

Copy/paste and file import/export are supported. Your browser may ask for clipboard or download permission. If clipboard access is denied, use the encrypted file instead.

## Offline behavior

After the first successful visit, Admincraft caches its application files for faster repeat loads. A network connection is still required to reach the server, and opening the app online periodically ensures the latest version is cached.
