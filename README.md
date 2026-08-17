<p align="center">
  <a href="https://github.com/joanroig/admincraft">
      <img alt="Admincraft logo" src="web/icons/Icon-192.png" width="140px">
  </a>
</p>

<h1 align="center">
  Admincraft
</h1>

<p align="center">
  Multiplatform app to control Minecraft Bedrock and Java servers, built with Flutter.
</p>

<p align="center">
  <a href="https://github.com/joanroig/admincraft-websocket"><img src="https://img.shields.io/badge/Admincraft_WebSocket-339933?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAVVJREFUOE99k71LA0EQxXcLLxrBvYghRBDRykKtrG2s/IutbKxTqYWVYqOIYBLBaM7i5Df4lsn6Mc3Nzs68ffNmLtb1sA3f1raf5sW4FLw/n7+FTmdVafZVLKa00R7unlhwdHNm36qqDESJR3un4eruIgNQrFiEAQGKSmuaxhLvH6/D68eLsSpjxoBgP21ZYl33Mw7MiGHT96fAGZa+nQUAXhmPHzJIqcXBznFmo1esBQ6ihz+bTUO3myyH13TnX84iAwCyRPIM9AotSiN8mYntGUwmz6HX2wxry+uWo/5VACtE1R0tZw1ASysDUxsTiNRHD6aF2BKVmAFo5lz4dgARAHeaFhNRzb8Aoq498cslQfMiecXxNUItjkTWFmq5DADaXhhGVAKoQCP/sQdeNIlF/144iraH+wv/RR6jlCcBu7w9NxYlAHealDGlBVHOG/KL81fOFz/OD4TZn3QMAAAAAElFTkSuQmCC" alt="Admincraft WebSocket badge"/></a>
  <a href="https://github.com/joanroig/Admincraft/blob/main/docs/server/SERVER_SETUP.md"><img src="https://img.shields.io/badge/Bedrock_Server-805539?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAz0lEQVR4AY2TsRWDMAxE5dHYggGyRGoWSJeGLi0LJFOkYoEM4rzze+d3NmceBZFBh3T6EfH8Lnlep8x4f98OZ0SXQwxNfn5bdveIr/1RnqsGxQI/uFJKzUUBXsC5z7NQ8NALaJ1x1KCM4ASwrEX6PN8LzuU6QMDZR/kKEcIzy8wr4ArR/XUjJhytcUCQrvMZ3OJAZ3WdHbzGgd5ccUBehB9K+ooDaAm0MtB9d1a1MHXc0MKAIh1BqbvnbFD3oN8F/eLUJaLuRKiAttSmK6jQ/2cNI7f0f4TVAAAAAElFTkSuQmCC" alt="Minecraft badge"/></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=fff&style=flat-square" alt="Flutter badge" /></a>
  <a href="https://github.com/joanroig/Admincraft/issues"><img src="https://img.shields.io/github/issues-raw/joanroig/admincraft.svg?maxAge=2592000&label=Open%20Issues&style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAMtJREFUOI1j1G5l+M+ABSiJ1GMTZmC++pqBgYGB4bb4NAYGBgYGJqyqSAAsMIbqyywUkzlfQxz2XZQRla8tysDAwMCg/bqOyi5gExNBccl3bTSboS6BhcEvqD7KXYBhIwPEJQw4woAB6lKYOOUugPndMDQSReL8tGUoNhtmRWGVp14sHFu9nIGBgYHhz823DAwMDAx2NTkoCg+1TEHh8woJUccFjGEtdSh5Ad2v6ADmd6rFAqNnUc5/BgaEnz6/e4dXA0zdr1dvqOMCAHUPQJl6c3AoAAAAAElFTkSuQmCC" alt="Open issues" /></a>
  <a href="https://github.com/joanroig/admincraft/blob/main/CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAAXNSR0IArs4c6QAAABVQTFRFAAAAMyURd0M1kF5DAZYRvYpy////M94BeAAAAAd0Uk5TAP///////6V/pvsAAAAzSURBVBiVY2BFAww0EmBEAtgF2NhYWECKWVjY2LAJMDODOMzMMBq7ABMTSICJCbcAXjMAV+YEKS5sU08AAAAASUVORK5CYII=" alt="PRs welcome!" /></a>  
  <a href="https://github.com/joanroig/admincraft/actions/workflows/build-and-release-app.yml"><img src="https://img.shields.io/github/actions/workflow/status/joanroig/admincraft/build-and-release-app.yml?style=flat-square&label=Build&logo=github" alt="Build"/></a>
  <a href="https://joanroig.github.io/admincraft/docs/"><img src="https://img.shields.io/badge/Documentation-805539?style=flat-square&logo=readthedocs&logoColor=white" alt="Documentation"/></a>
</p>

<p align="center">
  <img alt="Admincraft Mockup made with https://previewed.app/" src="mockup.png">
</p>

## ![Admincraft logo](docs/logo/variants/dirt.png) What is Admincraft?

Admincraft is a multiplatform app for managing Minecraft Bedrock and Java Edition servers. The [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket) bridge uses the Bedrock Docker console or Java RCON internally, while the app keeps the same secure WebSocket connection on every platform. It provides an intuitive GUI for issuing commands, performing server maintenance, and monitoring server logs.

[Open Admincraft Web](https://joanroig.github.io/admincraft/) · [Read the documentation](https://joanroig.github.io/admincraft/docs/)

### Current project status

- Bedrock is optimized for [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server/tree/master); Java is optimized for [docker-minecraft-server](https://github.com/itzg/docker-minecraft-server).
- Releases are available for Android, Windows, macOS, and Linux. The hosted web
  app runs from the same Flutter codebase with browser-specific networking and
  certificate restrictions.
- Runs in the browser too (`flutter run -d chrome`), with two limitations the browser imposes: self-signed certificates cannot be loaded, because the browser validates TLS itself and exposes no way to add a trust anchor, and a page served over HTTPS cannot open an unencrypted `ws://` connection, so the `Private network` option only works when the app itself is served over `http://` (such as a local build).

## ![Admincraft logo](docs/logo/variants/pig.png) Getting Started

You need a Minecraft server and [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket). Visit the [documentation](https://joanroig.github.io/admincraft/docs/) for installation, connection, backup, and troubleshooting guides. Use the [Bedrock setup guide](docs/server/SERVER_SETUP.md) or the [Java setup guide](docs/getting-started/java-server.md).

Once you have your server ready, [download Admincraft for your platform](https://github.com/joanroig/admincraft/releases), add your server in the app, and you're good to go!

In the app settings, pick the **Connection Security** option matching your setup: `Private network` for Tailscale, a VPN or a LAN, `Public certificate` for a server with a publicly trusted certificate, and `Self-signed certificate` to load your own. The [server setup guide](docs/server/SERVER_SETUP.md#choosing-how-to-connect) walks through each one.

**Settings → Data & Sync** can copy/paste or export/import all saved server
profiles. Transfers include server secret keys, so Admincraft always encrypts
them with a passphrase you choose.

## ![Admincraft logo](docs/logo/variants/obsidian.png) Development

This section is for contributors and custom-build maintainers. App users should
start with the [user documentation](https://joanroig.github.io/admincraft/docs/getting-started/install/);
server operators should use the [server setup guides](https://joanroig.github.io/admincraft/docs/getting-started/).

- Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).
- Open the project in the IDE of your choice ([VSCode](https://code.visualstudio.com/) is recommended) and run the app by following [this guide](https://docs.flutter.dev/tools/vs-code#running-and-debugging).

### Build Android APK

- Run `flutter build apk`.
- The APK will be available at [build/app/outputs/apk/release](build/app/outputs/apk/release).

### Build Windows Executable

- Run `flutter build windows`.
- The .exe file with the required files will be available at [build/windows/x64/runner/Release](build/windows/x64/runner/Release).

### Build Web and Documentation

- Install the documentation dependencies with `python -m pip install -r requirements-docs.txt`.
- Run `flutter build web --release --wasm --base-href /admincraft/`.
- Run `python -m mkdocs build --strict --site-dir build/web/docs`.
- The combined GitHub Pages site will be available under `build/web`, with documentation in `build/web/docs`.

Pushes to `main` automatically test, build, and deploy both through the **Deploy web app and docs** workflow. In the repository's Pages settings, the source must be set to **GitHub Actions**.

### Automatic Builds

Admincraft uses GitHub Actions to automate building and releasing the app. New releases are triggered by running the "Bump Version & Release" workflow from the GitHub Actions tab. This will automatically start the build and release process. The process consists of two workflows:

- **Bump Version & Release** ([.github/workflows/bump-version-and-release.yml](.github/workflows/bump-version-and-release.yml)): This workflow bumps the version in `pubspec.yaml`, commits the change, and creates a new tag. It can be triggered manually and supports major, minor, or patch version increments.
- **Build and Release** ([.github/workflows/build-and-release-app.yml](.github/workflows/build-and-release-app.yml)): This workflow builds the release artifacts, names them with the version, and uploads them to the [GitHub Releases page](https://github.com/joanroig/admincraft/releases).

## ![Admincraft logo](docs/logo/variants/grass.png) Feature Roadmap

You can view the planned, started, and completed features in [GitHub Projects](https://github.com/users/joanroig/projects/2/views/2).

## ![Admincraft logo](docs/logo/variants/villager.png) Community & Contributions

The community and team are available in [GitHub Discussions](https://github.com/joanroig/admincraft/discussions), where you can ask for support, discuss the roadmap, and share ideas.

Our [Contribution Guide](https://github.com/joanroig/admincraft/blob/main/CONTRIBUTING.md) describes how to contribute to the codebase and documentation.

## ![Admincraft logo](docs/logo/variants/enderman.png) Credits

- Item icons from [mcicons](https://github.com/themuhamed/mcicons) by @themuhamed, used under the MIT License.

Docker tools

- [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server)
- [Bedrockifier](https://github.com/Kaiede/Bedrockifier)
- [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket)

Fonts

- [Miracode](https://github.com/IdreesInc/Miracode)
- [Scientifica](https://github.com/oppiliappan/scientifica)
- [Monocraft](https://github.com/IdreesInc/Monocraft)

## ![Admincraft logo](docs/logo/variants/cow.png) License

Admincraft version 2.0.0 and later is source-available under the
[PolyForm Shield License 1.0.0](https://github.com/joanroig/admincraft/blob/main/LICENSE).
See [LICENSING.md](https://github.com/joanroig/admincraft/blob/main/LICENSING.md)
for the version boundary and third-party components.

## ![Admincraft logo](docs/logo/variants/zombie.png) Disclaimer

**NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

Minecraft is a trademark of Mojang Synergies AB. Admincraft is an independent
project with no affiliation to Mojang, Microsoft, or the maintainers of any
server image it works with.
