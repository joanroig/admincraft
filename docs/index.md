---
hide:
  - navigation
  - toc
---

<div class="admincraft-hero" markdown>

![Admincraft dirt-block logo](logo/variants/dirt.png){ .admincraft-hero__logo }

# Your Minecraft server, under control

Admincraft is a multiplatform control panel for Minecraft Bedrock and Java Edition servers. Run commands, manage the world, and carry your saved servers between devices.

Built for [itzg's Minecraft containers](https://github.com/itzg/docker-minecraft-bedrock-server), where it gives a live console, world controls and a restart button. It also speaks plain RCON, so an existing Java server can be managed without changing how it runs.

<div class="admincraft-hero__actions">
  <a class="md-button md-button--primary" href="https://joanroig.github.io/admincraft/">Open Admincraft</a>
  <a class="md-button" href="getting-started/install/">Get started</a>
</div>

</div>

<div class="grid cards admincraft-cards" markdown>

-   :material-rocket-launch:{ .lg .middle } **Get connected**

    ---

    Install Admincraft or open it in a browser, then connect your first Minecraft server.

    [:octicons-arrow-right-24: Start here](getting-started/install.md)

-   :material-shield-lock:{ .lg .middle } **Choose safe transport**

    ---

    Understand private networks, public certificates, and self-signed certificates before exposing server control.

    [:octicons-arrow-right-24: Connection security](guides/connection-security.md)

-   :material-server-network:{ .lg .middle } **Manage several servers**

    ---

    Keep independent addresses, credentials, and certificates, and switch between them from the app bar.

    [:octicons-arrow-right-24: Server profiles](guides/server-profiles.md)

-   :material-backup-restore:{ .lg .middle } **Move devices safely**

    ---

    Copy or export an encrypted backup, then import it on another computer, phone, or browser.

    [:octicons-arrow-right-24: Backup and transfer](guides/backup-transfer.md)

</div>

!!! warning "Admincraft controls the server"

    A saved secret key can execute server commands. Treat exported profiles and server credentials like passwords, even though Admincraft encrypts its transfer files.

!!! info "Not an official Minecraft product"

    **NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

    Minecraft is a trademark of Mojang Synergies AB. Admincraft is an independent project, unaffiliated with Mojang, Microsoft, or the maintainers of any server image it works with.
