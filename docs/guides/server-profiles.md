# Server profiles

Each profile stores everything Admincraft needs to connect to one server:

- Alias
- IP address or hostname
- Port
- Bridge secret key, or the RCON password for a direct connection
- Connection type
- Pinned certificate, when applicable

## Add a server

1. Open the server selector in the app bar.
2. Choose **Add server**.
3. Complete the new profile in **Settings**.
4. Select **Save changes**.

## Switch servers

Open the server selector and choose a profile. Admincraft disconnects the
current connection, resets live world state, loads that profile's saved console
transcript, and connects using the selected profile.

## Edit or delete a profile

- Edit the selected profile in **Settings → Servers**, then select **Save changes**.
- Use **Danger zone → Delete server** in the configuration page to remove it.
- Admincraft always keeps at least one profile so the settings form has a selected server.

## Move profiles to another device

Use [Backup and transfer](backup-transfer.md) to move all saved profiles together. Theme, font, command history, and other device preferences are not part of the profile export.
