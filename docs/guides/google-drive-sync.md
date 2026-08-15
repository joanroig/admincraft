# Google Drive sync

Admincraft stores one encrypted `admincraft.json` file in Google Drive's hidden
[application-data folder](https://developers.google.com/workspace/drive/api/guides/appdata).
The file is not visible in My Drive and only the same Google Cloud application
can access it. Server addresses, certificates, and secret keys are encrypted
before upload with the passphrase you choose.

The passphrase and desktop refresh token are kept in the operating system's
secure storage. Google never receives the plain server configuration.

## Google Cloud setup

### 1. Create the project and enable Drive

1. Create or select a project in the
   [Google Cloud Console](https://console.cloud.google.com/).
2. Open **APIs & Services → Library**.
3. Find **Google Drive API** and select **Enable**.

### 2. Configure Google Auth Platform

1. Open **Google Auth Platform → Branding** and enter the Admincraft app and
   support details.
2. Under **Audience**, choose **External** unless the app is restricted to one
   Google Workspace organization.
3. Under **Data Access**, add only:

       https://www.googleapis.com/auth/drive.appdata

   This scope is [classified as non-sensitive](https://developers.google.com/workspace/drive/api/guides/api-specific-auth)
   and gives Admincraft access only to its hidden configuration folder—not to
   the user's other Drive files.
4. During development, keep the app in **Testing** and add each Google account
   under **Test users**. Testing grants expire after seven days. Publish the app
   when it is ready for general use.

### 3. Create OAuth clients

Create all clients in the same Cloud project.

#### Web client

Create a **Web application** OAuth client. Add these **Authorized JavaScript
origins** as needed (origins do not include a trailing path):

- `http://localhost`
- `http://localhost:52656`
- `https://joanroig.github.io`

No redirect URI is needed for the Flutter web sign-in button. Copy the client
ID; it becomes `ADMINCRAFT_GOOGLE_WEB_CLIENT_ID`.

#### Android client

Create an **Android** OAuth client with:

- Package name: `com.joanroig.admincraft`
- SHA-1: the fingerprint of the key used to sign that build

Add separate Android clients for debug and release signing keys when their
fingerprints differ. The Android client ID is selected by Google from the
package/signature pair and is not passed through `--dart-define`. Android also
uses the Web client ID created above as its server client ID.

For the debug fingerprint, run `./gradlew signingReport` from `android/` (or
`gradlew.bat signingReport` on Windows). Configure a real release signing key
before publishing; the current project release build still uses the debug key.

#### Windows client

Create a **Desktop app** OAuth client. Copy its client ID and client secret.
The desktop flow uses Google's supported
[loopback browser flow](https://developers.google.com/identity/protocols/oauth2/native-app#redirect-uri_loopback),
receives the result on a random localhost port, and validates state and PKCE;
no redirect URI needs to be entered manually.

Desktop applications are public OAuth clients, so an embedded client secret
cannot be treated as confidential. Keep it out of the repository anyway and
inject it while building.

## Build with the client IDs

Web development:

```powershell
flutter run -d web-server --web-port 52656 `
  --dart-define=ADMINCRAFT_GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

GitHub Pages:

```powershell
flutter build web --release --wasm --base-href /admincraft/ `
  --dart-define=ADMINCRAFT_GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

Android:

```powershell
flutter build apk --release `
  --dart-define=ADMINCRAFT_GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

Windows:

```powershell
flutter build windows --release `
  --dart-define=ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_ID=YOUR_DESKTOP_CLIENT_ID `
  --dart-define=ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_SECRET=YOUR_DESKTOP_CLIENT_SECRET
```

For this repository's GitHub Actions, add three **repository secrets**:

- `ADMINCRAFT_GOOGLE_WEB_CLIENT_ID`
- `ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_ID`
- `ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_SECRET`

Secrets, not variables. The two client IDs are not confidential and either
store would work, but the workflows read all three from `secrets`, and a name
stored in the other place resolves to an empty string with no warning.

The workflows inject them into the relevant builds. Builds without these
values still work, but Data & Sync shows **Setup required** and disables Google
sign-in.

## First sync on a device

1. Open **Data & Sync → Google Drive sync** and sign in.
2. Choose **Upload this device** if its profiles should become the Drive copy,
   or **Use Drive copy** on a new device.
3. Enter the same encryption passphrase on every device.

After setup, Admincraft syncs at startup and after server changes. If both the
local and Drive copies changed since the previous sync, the more recently
modified copy wins. **Upload**, **Download**, and **Sync now** remain available
for explicit recovery.

!!! warning
    Google cannot recover the encryption passphrase. Keep a manual exported
    backup somewhere safe before relying on sync alone.
