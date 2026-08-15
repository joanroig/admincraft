# Google Drive sync

Admincraft stores one encrypted `admincraft.json` file in Google Drive's hidden
[application-data folder](https://developers.google.com/workspace/drive/api/guides/appdata).
The file is not visible in My Drive and only the same Google Cloud application
can access it. Server addresses, certificates, and secret keys are encrypted
before upload with the passphrase you choose.

The passphrase and desktop refresh token are kept in the operating system's
secure storage. Google never receives the plain server configuration.

!!! warning "A project in testing only admits its own testers"

    A Google Cloud project starts in **testing**, which admits only the accounts
    its owner listed as testers. Everyone else is refused with
    `Error 403: access_denied`, however correctly the rest is set up. Publishing
    the project lifts that, and for this scope it needs no review: see
    [publish the project](#4-publish-the-project).

    Note what the refusal applies to. Signing in still succeeds, because
    identifying you and granting access to Drive are separate steps and only the
    second is gated.

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
   under **Test users**. Testing grants expire after seven days, so a tester is
   asked to authorise again every week.

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
`gradlew.bat signingReport` on Windows).

For the release fingerprint, read it from the keystore itself:

```powershell
keytool -list -v -keystore admincraft-release.jks -alias admincraft
```

!!! warning "Changing the signing key breaks Drive sign-in"

    Google identifies an Android app by package name **and** signing
    certificate. A build signed with a different key than the registered
    Android client matches nothing, and sign-in fails with
    `[16] Account reauth failed` even though the client IDs are correct.
    Registering a release key after shipping debug-signed builds, as this
    project did in v2.2.0, is exactly that situation: the release fingerprint
    needs its own Android client.

    The fingerprint of an already published build can be read from the APK
    itself, which is worth doing to confirm what actually shipped:

    ```powershell
    apksigner verify --print-certs admincraft-v2.2.0-android.apk
    ```

    `apksigner` comes with the Android SDK build-tools. `keytool -printcert
    -jarfile` will not do here: it reads only v1 JAR signatures, and these
    APKs are signed with the v2/v3 schemes alone.

#### Windows client

Create a **Desktop app** OAuth client. Copy its client ID and client secret.
The desktop flow uses Google's supported
[loopback browser flow](https://developers.google.com/identity/protocols/oauth2/native-app#redirect-uri_loopback),
receives the result on a random localhost port, and validates state and PKCE;
no redirect URI needs to be entered manually.

Desktop applications are public OAuth clients, so an embedded client secret
cannot be treated as confidential. Keep it out of the repository anyway and
inject it while building.

### 4. Publish the project

Open **Google Auth Platform → Audience** and select **Publish app**. Any Google
account can then sign in, the test-user list stops mattering, and grants no
longer expire every seven days.

There is no review to wait for and nothing to pay. Google only requires its
verification process for [sensitive and restricted scopes](https://developers.google.com/workspace/drive/api/guides/api-specific-auth),
and `drive.appdata` is neither: it is classified as non-sensitive, because it
reaches only the app's own hidden folder and never the user's files. An app
requesting nothing beyond that publishes immediately, without the unverified-app
warning or the hundred-user cap those scopes carry.

Two things would change that, and both are choices rather than accidents:
adding a wider Drive scope later moves the project into the sensitive tier and
its review, and showing a name and logo on the consent screen instead of the
project's own details needs the lighter brand verification.

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

## When sign-in fails

| What the app says | What it usually means |
| --- | --- |
| This build is not registered in its Google Cloud project | No Android OAuth client matches this package name and signing certificate. Register the fingerprint of the build you are running, as above. |
| Setup required | The build carries no client IDs. They are compiled in, so a build made without them cannot sign in at all; check the repository secrets and rebuild. |
| The project is still in testing | Publish it, or add the account under **Test users**. |
| Sign-in was cancelled | The account chooser was dismissed. |

Two things that look like app faults and are not:

- Signing in and reaching Drive are separate steps. Admincraft asks who you are
  when it starts, which any account may answer, and asks for the Drive scope
  only when you sign in from **Data & Sync**. A testing project refuses the
  second while allowing the first, which looks like an account that signs in
  and then cannot sync.
- The Drive API must be enabled in the same project the OAuth clients belong
  to. Sign-in can succeed while every sync then fails.
