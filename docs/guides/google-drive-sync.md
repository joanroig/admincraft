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

After setup, Admincraft checks Drive at startup and syncs whenever a server
profile is added, edited, deleted, or imported. On Android, the startup check
uses Credential Manager; Android may briefly show its system sign-in progress
surface, which the app cannot suppress. It is only requested when automatic
sync is enabled. If local and Drive copies both changed, the more recently
modified copy wins. **Upload**, **Download**, and **Sync now** remain available
for recovery.

!!! warning
    Keep an exported backup file somewhere safe. A Drive copy cannot be
    decrypted without its passphrase.

## If you forget the passphrase

There is no recovery key or encryption backdoor. If the Drive file is your
only remaining copy, it cannot be decrypted without the old passphrase.

If Admincraft still has the server profiles on this device, open
**Settings → Data & Sync → Forgot passphrase?** and choose **Replace Drive
copy**. Confirm a new passphrase and Admincraft will encrypt the local profiles
again, overwrite the inaccessible Drive file, and resume sync. This does not
recover anything that existed only in the old Drive file.

Choose **Disconnect Drive** instead if you want to stop sync without replacing
the remote file. The profiles on this device are kept.

## Web app notes

Drive sync works in the web app, but sign-in is tied to the exact site origin.
If a sign-in button does not appear, reload the page once and make sure pop-ups
and third-party sign-in are allowed for the Admincraft site.

Profiles in the browser still depend on site storage. Drive sync or an
encrypted backup protects them if browser data is cleared.

### Profiles created with a self-signed certificate

Drive preserves a certificate configured on Android or desktop, but a browser
cannot use that certificate for pinning. When such a profile is downloaded,
Admincraft keeps it unchanged for native devices, stops the browser from
attempting an incompatible connection, and explains the required change.

Use **Public address, trusted certificate** with a hostname and certificate the
browser already trusts. If the browser reaches the same Minecraft server
through a different address, keep the self-signed profile for native apps and
add a second browser-compatible server profile. Admincraft will sync both.

## Troubleshooting

| What Admincraft shows | What to do |
| --- | --- |
| **Setup required** | This build was made without Google client IDs. Use Backup file, or ask whoever built it to configure Drive. |
| **This build is not registered** | The Android build's package/signing key is not registered by its publisher. Use an official matching build or contact the publisher. |
| **The project is still in testing** | The publisher must add your account as a tester or publish the Google project. |
| **No Admincraft configuration exists** | Choose **Upload this device** on the device that has the profiles first. |
| **Sign-in was cancelled** | Try again and finish the Google account prompt. |
| **Could not decrypt** | Check that the passphrase exactly matches the one used for the Drive copy. |
| **Passphrase forgotten** | Use **Forgot passphrase?** to replace Drive from a device that still has the profiles, or disconnect while keeping its local profiles. A Drive-only copy cannot be recovered. |

If you maintain the build, the
[developer OAuth setup](../development/google-drive-oauth.md) explains origins,
Android signing fingerprints, client IDs, publishing, and CI secrets.
