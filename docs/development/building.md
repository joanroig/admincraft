# Build from source

## App prerequisites

- Flutter stable
- Platform tooling for the target you want to build
- Python 3 for the documentation site

Clone the repository and install Flutter dependencies:

```bash
git clone https://github.com/joanroig/admincraft.git
cd admincraft
flutter pub get
```

## Run Admincraft

```bash
flutter run
```

Choose Chrome for the web app, Windows for the desktop app, or a connected Android device.

## Build the app

=== "Web"

    ```bash
    flutter build web --release --wasm --base-href /admincraft/
    ```

=== "Windows"

    ```bash
    flutter build windows --release
    ```

=== "Android"

    ```bash
    flutter build apk --release
    ```

The `/admincraft/` base path matches GitHub Project Pages. Use `/` when deploying to the root of a custom domain.

## Android release signing

Released APKs must be signed with the same key every time. Android identifies an
app by its package name **and** its signature, so a build signed with a
different key cannot update an existing install: it fails with "package
conflicts with an existing package". The debug key is regenerated per machine,
which makes it unusable for releases.

Generate a keystore once and keep it safe. Losing it means no future build can
update an existing installation:

```bash
keytool -genkey -v -keystore admincraft-release.jks   -keyalg RSA -keysize 2048 -validity 10000 -alias admincraft
```

Then add four repository secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 admincraft-release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | the store password |
| `ANDROID_KEY_PASSWORD` | the key password |
| `ANDROID_KEY_ALIAS` | `admincraft` |

The release workflow writes `android/key.properties` from those and signs with
it. Without them the build still succeeds, but logs a warning and falls back to
the debug key, producing an APK that cannot update an existing install.

For local release builds, create `android/key.properties` yourself:

```properties
storeFile=/absolute/path/to/admincraft-release.jks
storePassword=...
keyAlias=admincraft
keyPassword=...
```

Both that file and `android/app/*.jks` are gitignored.

## Preview the documentation

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

Open `http://127.0.0.1:8000/` to view the local documentation. Changes under
`docs/` reload automatically. Production builds set `MKDOCS_SITE_URL` so links
use the GitHub Pages `/admincraft/docs/` path without imposing that path on the
local preview.

## Build the combined GitHub Pages site

```bash
flutter build web --release --wasm --base-href /admincraft/
python -m mkdocs build --strict --site-dir build/web/docs
```

The resulting `build/web` directory contains Admincraft at its root and the documentation under `docs/`. The Pages workflow performs these steps and deploys the directory as one artifact.
