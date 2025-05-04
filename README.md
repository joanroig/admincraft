<p align="center">
  <a href="https://github.com/joanroig/admincraft">
      <img alt="Admincraft logo" src="web/icons/Icon-192.png" width="140px">
  </a>
</p>

<h1 align="center">
  Admincraft
</h1>

<p align="center">
  Multiplatform app to control Minecraft Bedrock Dockerized servers, built with Flutter.
</p>

<p align="center">
  <a href="https://github.com/joanroig/admincraft-websocket">
      <img src="https://img.shields.io/badge/Admincraft_WebSocket-339933?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAVVJREFUOE99k71LA0EQxXcLLxrBvYghRBDRykKtrG2s/IutbKxTqYWVYqOIYBLBaM7i5Df4lsn6Mc3Nzs68ffNmLtb1sA3f1raf5sW4FLw/n7+FTmdVafZVLKa00R7unlhwdHNm36qqDESJR3un4eruIgNQrFiEAQGKSmuaxhLvH6/D68eLsSpjxoBgP21ZYl33Mw7MiGHT96fAGZa+nQUAXhmPHzJIqcXBznFmo1esBQ6ihz+bTUO3myyH13TnX84iAwCyRPIM9AotSiN8mYntGUwmz6HX2wxry+uWo/5VACtE1R0tZw1ASysDUxsTiNRHD6aF2BKVmAFo5lz4dgARAHeaFhNRzb8Aoq498cslQfMiecXxNUItjkTWFmq5DADaXhhGVAKoQCP/sQdeNIlF/144iraH+wv/RR6jlCcBu7w9NxYlAHealDGlBVHOG/KL81fOFz/OD4TZn3QMAAAAAElFTkSuQmCC" alt="Admincraft WebSocket badge"/>
  </a>
  <a href="https://github.com/joanroig/Admincraft/blob/main/docs/server/SERVER_SETUP.md">
    <img src="https://img.shields.io/badge/Bedrock_Server-805539?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAz0lEQVR4AY2TsRWDMAxE5dHYggGyRGoWSJeGLi0LJFOkYoEM4rzze+d3NmceBZFBh3T6EfH8Lnlep8x4f98OZ0SXQwxNfn5bdveIr/1RnqsGxQI/uFJKzUUBXsC5z7NQ8NALaJ1x1KCM4ASwrEX6PN8LzuU6QMDZR/kKEcIzy8wr4ArR/XUjJhytcUCQrvMZ3OJAZ3WdHbzGgd5ccUBehB9K+ooDaAm0MtB9d1a1MHXc0MKAIh1BqbvnbFD3oN8F/eLUJaLuRKiAttSmK6jQ/2cNI7f0f4TVAAAAAElFTkSuQmCC" alt="Minecraft badge"/>
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=fff&style=flat-square" alt="Flutter badge" />
  </a>
  <a href="https://github.com/joanroig/Admincraft/issues">
    <img src="https://img.shields.io/github/issues-raw/joanroig/admincraft.svg?maxAge=2592000&label=Open%20Issues&style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAMtJREFUOI1j1G5l+M+ABSiJ1GMTZmC++pqBgYGB4bb4NAYGBgYGJqyqSAAsMIbqyywUkzlfQxz2XZQRla8tysDAwMCg/bqOyi5gExNBccl3bTSboS6BhcEvqD7KXYBhIwPEJQw4woAB6lKYOOUugPndMDQSReL8tGUoNhtmRWGVp14sHFu9nIGBgYHhz823DAwMDAx2NTkoCg+1TEHh8woJUccFjGEtdSh5Ad2v6ADmd6rFAqNnUc5/BgaEnz6/e4dXA0zdr1dvqOMCAHUPQJl6c3AoAAAAAElFTkSuQmCC" alt="Open issues" />
  </a>
  <a href="https://github.com/joanroig/admincraft/blob/main/CONTRIBUTING.md">
    <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAAXNSR0IArs4c6QAAABVQTFRFAAAAMyURd0M1kF5DAZYRvYpy////M94BeAAAAAd0Uk5TAP///////6V/pvsAAAAzSURBVBiVY2BFAww0EmBEAtgF2NhYWECKWVjY2LAJMDODOMzMMBq7ABMTSICJCbcAXjMAV+YEKS5sU08AAAAASUVORK5CYII=" alt="PRs welcome!" />
  </a>  
  <a href="https://github.com/joanroig/admincraft/actions/workflows/build-and-release-app.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/joanroig/admincraft/build-and-release-app.yml?style=flat-square&label=Build&logo=github" alt="Build"/>
  </a>
</p>

<p align="center">
  <img alt="Admincraft Mockup made with https://previewed.app/" src="mockup.png">
</p>

## ![Admincraft logo](docs/logo/variants/dirt.png) What is Admincraft?

Admincraft is a multiplatform app for managing Minecraft Bedrock servers in Docker containers. Given that RCON isn't available for Bedrock, Admincraft uses the [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket) project to interact with the Minecraft server. This approach allows for secure and real-time command execution and server management through a WebSocket connection, providing an intuitive GUI for tasks such as issuing commands, performing server maintenance, and monitoring server logs.

### Current project status

- Currently optimized for use with Oracle Always Free, using a server created with [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server/tree/master).
- Development is focused on Android and Windows; other platforms may be unstable.

## ![Admincraft logo](docs/logo/variants/pig.png) Getting Started

You need a Minecraft Bedrock server and [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket) running in Docker to use Admincraft. Visit the [server setup guide](docs/server/SERVER_SETUP.md) to set up yours for free!

Once you have your server ready, [download Admincraft for your platform](https://github.com/joanroig/admincraft/releases), add your server in the app, and you're good to go!

## ![Admincraft logo](docs/logo/variants/obsidian.png) Development

- Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).
- Open the project in the IDE of your choice ([VSCode](https://code.visualstudio.com/) is recommended) and run the app by following [this guide](https://docs.flutter.dev/tools/vs-code#running-and-debugging).

### Build Android APK

- Run `flutter build apk`.
- The APK will be available at [build/app/outputs/apk/release](build/app/outputs/apk/release).

### Build Windows Executable

- Run `flutter build windows`.
- The .exe file with the required files will be available at [build/windows/x64/runner/Release](build/windows/x64/runner/Release).

### Automatic Builds

Admincraft uses GitHub Actions to automate building and releasing the app. New releases are triggered by running the "Bump Version & Release" workflow from the GitHub Actions tab. This will automatically start the build and release process. The process consists of two workflows:

- **Bump Version & Release** ([.github/workflows/bump-version-and-release.yml](.github/workflows/bump-version-and-release.yml)): This workflow bumps the version in `pubspec.yaml`, commits the change, and creates a new tag. It can be triggered manually and supports major, minor, or patch version increments.
- **Build and Release** ([.github/workflows/build-and-release.yml](.github/workflows/build-and-release.yml)): This workflow is triggered manually or automatically after the completion of the "Bump Version & Release" workflow. It builds the app for Android and Windows, names the artifacts with the version, and uploads them to the [GitHub Releases page](https://github.com/joanroig/admincraft/releases) as downloadable files.

## ![Admincraft logo](docs/logo/variants/grass.png) Feature Roadmap

You can view the planned, started, and completed features in [GitHub Projects](https://github.com/users/joanroig/projects/2/views/2).

## ![Admincraft logo](docs/logo/variants/villager.png) Community & Contributions

The community and team are available in [GitHub Discussions](https://github.com/joanroig/admincraft/discussions), where you can ask for support, discuss the roadmap, and share ideas.

Our [Contribution Guide](https://github.com/joanroig/admincraft/blob/main/CONTRIBUTING.md) describes how to contribute to the codebase and documentation.

## ![Admincraft logo](docs/logo/variants/enderman.png) Credits

Docker tools

- [docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server)
- [Bedrockifier](https://github.com/Kaiede/Bedrockifier)
- [Admincraft WebSocket](https://github.com/joanroig/admincraft-websocket)

Fonts

- [Miracode](https://github.com/IdreesInc/Miracode)
- [Scientifica](https://github.com/oppiliappan/scientifica)
- [Monocraft](https://github.com/IdreesInc/Monocraft)

## ![Admincraft logo](docs/logo/variants/cow.png) License

Licensed under the [GPLv3 License](https://github.com/joanroig/admincraft/blob/main/LICENSE.txt).
