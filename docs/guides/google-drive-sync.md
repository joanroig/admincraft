# Sync server profiles with Google Drive

This page is for people using Admincraft. If you are building Admincraft or
configuring its Google Cloud project, use the
[developer OAuth setup](../development/google-drive-oauth.md) instead.

Admincraft stores one encrypted `admincraft.json` file in Google Drive's hidden
application-data folder. It cannot see the rest of your Drive. Server
addresses, certificates, secret keys, and custom server logos are encrypted
before upload with the passphrase you choose.

## Start syncing

1. Open **Settings → Data & Sync**.
2. Under **Google Drive sync**, select **Sign in with Google**. On the web,
   select the Google-branded sign-in button.
3. Choose **Upload this device** if the profiles on this device should become
   the Drive copy. Choose **Use Drive copy** on a new or replacement device.
4. Enter an encryption passphrase and keep it somewhere safe.

Use the same passphrase on every device. Google cannot recover it, and
Admincraft never uploads it.

After setup, Admincraft syncs at startup and after server changes. If local and
Drive copies both changed, the more recently modified copy wins. **Upload**,
**Download**, and **Sync now** remain available for recovery.

!!! warning
    Keep an exported backup file somewhere safe. A Drive copy cannot be
    decrypted without its passphrase.

## Web app notes

Drive sync works in the web app, but sign-in is tied to the exact site origin.
If a sign-in button does not appear, reload the page once and make sure pop-ups
and third-party sign-in are allowed for the Admincraft site.

Profiles in the browser still depend on site storage. Drive sync or an
encrypted backup protects them if browser data is cleared.

## Troubleshooting

| What Admincraft shows | What to do |
| --- | --- |
| **Setup required** | This build was made without Google client IDs. Use Backup file, or ask whoever built it to configure Drive. |
| **This build is not registered** | The Android build's package/signing key is not registered by its publisher. Use an official matching build or contact the publisher. |
| **The project is still in testing** | The publisher must add your account as a tester or publish the Google project. |
| **No Admincraft configuration exists** | Choose **Upload this device** on the device that has the profiles first. |
| **Sign-in was cancelled** | Try again and finish the Google account prompt. |
| **Could not decrypt** | Check that the passphrase exactly matches the one used for the Drive copy. |

If you maintain the build, the
[developer OAuth setup](../development/google-drive-oauth.md) explains origins,
Android signing fingerprints, client IDs, publishing, and CI secrets.
