# Install Admincraft

Choose the version that matches how you want to use Admincraft.

## Web app

[Open Admincraft in your browser](https://joanroig.github.io/admincraft/){ .md-button .md-button--primary }

The web app installs nothing and receives updates automatically. Profiles are stored in that browser's site data, so create an [encrypted backup](../guides/backup-transfer.md) before clearing browser storage or moving devices.

Review the [web app limitations](../guides/web-app.md) before choosing a connection security mode.

## Installed apps

Download the latest build from [GitHub Releases](https://github.com/joanroig/admincraft/releases/latest).

=== "Windows"

    - Use the installer for the normal setup experience.
    - Or download the portable ZIP, extract the whole archive, and run
      `admincraft.exe`. The executable needs the files beside it.

=== "Android"

    1. Download the APK.
    2. Allow installation from your browser or file manager if Android asks.
    3. Open the APK and install Admincraft.

=== "macOS"

    - Open the DMG and copy Admincraft to Applications, or use the portable
      ZIP.
    - Current builds are not notarized. On first launch, macOS may require
      **Control-click → Open** and confirmation in **Privacy & Security**.

=== "Linux"

    - Install the `.deb` package on Debian or Ubuntu.
    - Or download the AppImage, run `chmod +x` on it, and launch it directly.

!!! tip

    Installed apps can use self-signed certificates. Browsers cannot load a
    certificate directly, so web users normally use a public certificate or a
    compatible private-network setup.

## Next step

[Connect your first server](first-server.md){ .md-button .md-button--primary }
