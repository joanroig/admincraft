# Troubleshooting

## Admincraft says connection details are missing

Check that **IP / Hostname** and **Secret Key** are filled in, then save the profile.

## The connection never reaches Connected

1. Confirm the server address and WebSocket port.
2. Confirm the `SECRET_KEY` exactly matches the WebSocket configuration.
3. Check that the WebSocket container is running:

    ```bash
    sudo docker compose ps
    sudo docker compose logs --tail 100 websocket
    ```

4. Test whether the device can reach the server network.
5. Recheck the selected [connection security mode](guides/connection-security.md).

## The web app refuses a Private network connection

An HTTPS page cannot connect to `ws://`. Use a `wss://` endpoint with **Public certificate**, or use a native Admincraft build with Tailscale or another private network.

## A self-signed certificate works natively but not in the browser

This is a browser limitation. The web app cannot pin the certificate. Use the Windows or Android app, trust the endpoint certificate at the operating-system/browser level and select **Public certificate**, or use a publicly trusted TLS endpoint.

## Certificate validation fails

- Confirm the certificate matches the exact IP address or hostname in the profile.
- Check whether the certificate expired.
- If it was renewed, load the new `.crt` file and save the profile.
- Confirm the server clock and client clock are correct.

## Import says the passphrase is wrong

AES-GCM cannot distinguish a wrong key from modified encrypted data. Retype the original passphrase. If it still fails, transfer the original export again rather than editing the JSON.

## Android refuses the update: "package conflicts with an existing package"

Android will not replace an app whose signing key has changed, and releases up
to and including v2.1.0 were signed with a throwaway debug key that the build
machine regenerated each time. Two of those builds are therefore signed by
different keys, and neither can update the other.

Releases after that use one stable key, so updates install normally. Moving off
an affected build takes one uninstall:

1. In Admincraft, open **Data & Sync** and export an encrypted backup, or copy
   the config. Uninstalling removes your saved servers along with the app.
2. Uninstall Admincraft.
3. Install the new APK.
4. Import the backup.

## Profiles disappeared from the browser

Browser profiles are stored as site data. Clearing that data removes them. Import your latest encrypted backup. Without an export, browser storage cannot be reconstructed by Admincraft.

## The web app appears stuck on an older version

Reload while online. If the old version remains, close other Admincraft tabs and clear the site's cached files in the browser settings. Export profiles before clearing all site data.

## Still stuck?

[Open a GitHub issue](https://github.com/joanroig/admincraft/issues/new/choose) with the Admincraft version, platform, connection security mode, and relevant WebSocket logs. Never include your `SECRET_KEY` or an unencrypted profile export.
