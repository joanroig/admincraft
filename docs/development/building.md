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
    flutter build web --release --base-href /admincraft/
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
flutter build web --release --base-href /admincraft/
python -m mkdocs build --strict --site-dir build/web/docs
```

The resulting `build/web` directory contains Admincraft at its root and the documentation under `docs/`. The Pages workflow performs these steps and deploys the directory as one artifact.
