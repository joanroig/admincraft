<p align="center">
  <a href="https://github.com/joanroig/admincraft">
      <img alt="Admincraft logo" src="docs/logo/variants/dirt.png" width="140px" style="image-rendering: pixelated;">
  </a>
</p>

<h1 align="center">
  Admincraft
</h1>

<p align="center">
  Multiplatform app for controlling Dockerized Minecraft Bedrock servers via SSH, built with Flutter.
</p>
<p align="center">
  <a href="https://github.com/joanroig/admincraft/blob/main/LICENSE.txt">
    <img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="Admincraft is released under the GPLv3 license." />
  </a>
  <a href="https://github.com/joanroig/admincraft/blob/develop/CONTRIBUTE.md">
    <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat" alt="PRs welcome!" />
  </a>
</p>

## ![Admincraft logo](docs/logo/variants/dirt.png) What is Admincraft?

Admincraft is a multiplatform app for managing Minecraft Bedrock servers in Docker containers. Since RCON isn't available for Bedrock, Admincraft uses SSH to execute Minecraft commands and handle server maintenance tasks like restarts and updates, all through an intuitive GUI.

### Current project status

- Currently optimized for use with Oracle Always Free, using a server created with [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server/tree/master).
- Development is focused on Android and Windows; other platforms may be unstable.

## ![Admincraft logo](docs/logo/variants/grass.png) Getting Started

You need a Minecraft Bedrock server to use Admincraft. Visit the [server setup guide](docs/server/SERVER_SETUP.md) to set up yours for free.

Once you have your server, download Admincraft for your platform from the [releases](https://github.com/joanroig/admincraft/releases) page, add your server in the app, and you're good to go!

## ![Admincraft logo](docs/logo/variants/obsidian_glow.png) Development

- Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).
- Open the project in the IDE of your choice ([VSCode](https://code.visualstudio.com/) is recommended) and run the app by following [this guide](https://docs.flutter.dev/tools/vs-code).

### Build Android APK

- Run `flutter build apk`.
- The APK will be available at [build/app/outputs/apk/release](build/app/outputs/apk/release).

### Build Windows Executable

- Run `flutter build windows`.
- The .exe file with the required files will be available at [build/windows/x64/runner/Release].(build/windows/x64/runner/Release)

## ![Admincraft logo](docs/logo/variants/diamond.png) Feature Roadmap

You can view the planned, started, and completed features in [GitHub Projects](https://github.com/joanroig/admincraft/projects).

## ![Admincraft logo](docs/logo/variants/creeper.png) Community & Contributions

The community and team are available in [GitHub Discussions](https://github.com/joanroig/admincraft/discussions), where you can ask for support, discuss the roadmap, and share ideas.

Our [Contribution Guide](https://github.com/joanroig/admincraft/blob/develop/CONTRIBUTE.md) describes how to contribute to the codebase and documentation.

## ![Admincraft logo](docs/logo/variants/obsidian.png) Related Projects

- [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server/tree/master) by [@itzg](https://github.com/itzg)
- [Bedrockifier](https://github.com/Kaiede/Bedrockifier) by [@Kaiede](https://github.com/Kaiede)
- [Monocraft Font](https://github.com/IdreesInc/Monocraft) by [@IdreesInc](https://github.com/IdreesInc)

## ![Admincraft logo](docs/logo/variants/cow.png) License

Licensed under the [GPLv3 License](https://github.com/joanroig/admincraft/blob/develop/LICENSE).
