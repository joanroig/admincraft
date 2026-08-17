# Configure Google Drive OAuth for a custom build

This page is for Admincraft developers and self-hosters building the app. End
users should follow [Sync server profiles with Google Drive](../guides/google-drive-sync.md).

Admincraft requests only `https://www.googleapis.com/auth/drive.appdata`. The
scope reaches the app's hidden data folder and not a user's normal Drive files.

## Create the Google Cloud project

1. Create or select a project in the Google Cloud Console.
2. Open **APIs & Services → Library** and enable **Google Drive API**.
3. In **Google Auth Platform → Branding**, enter the app and support details.
4. Under **Audience**, choose **External** unless this is restricted to one
   Workspace organization.
5. Under **Data Access**, add only the `drive.appdata` scope above.

During development, add every account under **Test users**. To let other users
connect, open **Audience** and select **Publish app**. `drive.appdata` is a
non-sensitive scope, so it does not require sensitive-scope verification.

## Create OAuth clients

Create the clients in the same project as the enabled Drive API.

### Web

Create a **Web application** client and add every exact authorized JavaScript
origin used by a build, for example:

- `http://localhost:52656`
- `https://joanroig.github.io`

Origins do not contain a trailing path. No redirect URI is needed for the
Google Identity Services button. The ID becomes
`ADMINCRAFT_GOOGLE_WEB_CLIENT_ID`.

### Android

Create an **Android** client for package `com.joanroig.admincraft` and the SHA-1
of the certificate that signs the build. Debug and release keys need separate
clients when their fingerprints differ. Android also uses the web client ID as
its server client ID.

```powershell
cd android
./gradlew signingReport
```

For an existing APK, use Android SDK build-tools:

```powershell
apksigner verify --print-certs admincraft.apk
```

Changing the signing key changes the app identity Google sees. A missing match
usually appears as `[16] Account reauth failed`.

### Desktop

Create a **Desktop app** client. Admincraft uses Google's loopback browser flow.
The client ID and client secret become
`ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_ID` and
`ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_SECRET`.

## Build with credentials

```powershell
# Web
flutter run -d web-server --web-port 52656 `
  --dart-define=ADMINCRAFT_GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID

# Android
flutter build apk --release `
  --dart-define=ADMINCRAFT_GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID

# Windows
flutter build windows --release `
  --dart-define=ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_ID=YOUR_DESKTOP_CLIENT_ID `
  --dart-define=ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_SECRET=YOUR_DESKTOP_CLIENT_SECRET
```

For GitHub Actions, add all three names as repository **secrets**. Builds made
without the relevant values continue to run, but show **Setup required** in
Data & Sync.

Return to the [user sync guide](../guides/google-drive-sync.md) to test upload,
download, conflict handling, and passphrase recovery.
