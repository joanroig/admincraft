# Server profiles

Each profile stores everything Admincraft needs to connect to one server:

- Alias
- IP address or hostname
- Port
- Secret key
- Connection security mode
- Pinned certificate, when applicable

## Add a server

1. Open the server selector in the app bar.
2. Choose **Add server**.
3. Complete the new profile in **Settings**.
4. Select **Save Settings**.

## Switch servers

Open the server selector and choose a profile. Admincraft disconnects the current WebSocket, clears session-specific output and world state, and connects using the selected profile.

## Edit or delete a profile

- Edit the selected profile in **Settings**, then select **Save Settings**.
- Use the delete icon beside **Server Settings** to remove it.
- Admincraft always keeps at least one profile so the settings form has a selected server.

## Move profiles to another device

Use [Backup and transfer](backup-transfer.md) to move all saved profiles together. Theme, font, command history, and other device preferences are not part of the profile export.
