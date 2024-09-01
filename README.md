<p align="center">
  <a href="https://github.com/joanroig/admincraft">
    <picture>
      <img alt="Admincraft logo" src="docs/app_icon_design/Admincraft.png" width="140px">
    </picture>
  </a>
</p>

<h1 align="center">
  Admincraft
</h1>

<p align="center">
  Multiplatform Flutter app to control Dockerized Minecraft Bedrock servers via SSH.
</p>
<p align="center">
  <a href="https://github.com/joanroig/admincraft/blob/main/LICENSE.txt">
    <img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="Admincraft is released under the GPLv3 license." />
  </a>
  <a href="https://github.com/joanroig/admincraft/blob/develop/CONTRIBUTING.md">
    <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat" alt="PRs welcome!" />
  </a>
</p>

## What is Admincraft?

Admincraft is a multiplatform application designed to simplify the management of Minecraft Bedrock servers running in Docker containers. As RCON is not available on the Bedrock version, Admincraft connects to the server via SSH, allowing the execution of all Minecraft commands and performing essential server maintenance tasks such as restarting and updating.

### Current Project Status

- It is currently tailored to be used with Oracle Always Free, running a server created with [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server/tree/master).
- The development focus is on Android and Windows; other platforms may be unstable.

## Getting Started

You need a Minecraft Bedrock server to use Admincraft. Visit the [server setup guide](docs/server/SERVER_SETUP.md) to set up yours for free.

Once you have your server, download Admincraft for your platform from the [releases](https://github.com/joanroig/admincraft/releases) page, add your server in the app, and you're good to go!

## <span><img alt="Admincraft logo" src="docs/app_icon_design/Admincraft_16x16.png" width="16"></span> Development

- Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).
- Open the project in the IDE of your choice ([VSCode](https://code.visualstudio.com/) is recommended) and run the app by following [this guide](https://docs.flutter.dev/tools/vs-code).

### Build Android APK

Run:

`flutter build apk`

The APK will be available at [build/app/outputs/apk/release](build/app/outputs/apk/release)

## Feature Roadmap

You can view the planned, started, and completed features in [GitHub Projects](https://github.com/joanroig/admincraft/projects).

## Community & Contributions

The community and team are available in [GitHub Discussions](https://github.com/joanroig/admincraft/discussions), where you can ask for support, discuss the roadmap, and share ideas.

Our [Contribution Guide](https://github.com/joanroig/admincraft/blob/develop/CONTRIBUTING.md) describes how to contribute to the codebase and documentation.

## Related Projects

- [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server/tree/master) by [@itzg](https://github.com/itzg)
- [Bedrockifier](https://github.com/Kaiede/Bedrockifier) by [@Kaiede](https://github.com/Kaiede)
- [Monocraft Font](https://github.com/IdreesInc/Monocraft) by [@IdreesInc](https://github.com/IdreesInc)

## License

Licensed under the [GPLv3 License](https://github.com/joanroig/admincraft/blob/develop/LICENSE).
