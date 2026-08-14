# Set up a Java Edition server

Admincraft sends Java commands through RCON, but the RCON port stays inside the Docker network: the app connects to the Admincraft WebSocket bridge, so the same Android, Windows, and browser clients work for both editions.

If you already have a Java server, or would rather add nothing to it, Admincraft can also [talk to RCON directly](existing-server.md#connect-any-java-server-over-rcon), without this bridge. That trades away the live console and the restart button, and does not work in the browser. The [feature comparison](index.md#what-each-setup-gives-you) shows both.

## Start the containers

1. Download [`docker-compose-java.yml`](../server/docker-compose-java.yml).
2. Replace both `CHANGE_THIS_RCON_PASSWORD` values with the same strong password.
3. Replace `YOUR_SECRET_KEY_HERE` with a separate random secret, for example from `openssl rand -hex 32`.
4. Start the stack with `docker compose -f docker-compose-java.yml up -d`.

The example uses Paper. Set `TYPE` to another value supported by `itzg/minecraft-server` if you prefer Vanilla, Fabric, Forge, NeoForge, or another compatible Java server.

!!! danger "Do not publish RCON"

    Port `25575` is intentionally not listed under `ports`. RCON is not encrypted and should remain reachable only by the WebSocket bridge on the private Docker network.

## Add it to Admincraft

Create a server profile with:

- **Minecraft Edition:** Java Edition
- **IP / Hostname:** the host running Docker
- **Port:** `8080`
- **Secret Key:** the bridge `SECRET_KEY`, not the RCON password
- **Connection Security:** normally Private network when connecting over Tailscale, a VPN, or a trusted LAN

The Java profile enables Java-specific command completion and output parsing. Docker access gives the bridge live logs and restart controls; commands themselves travel from the bridge to the Minecraft server over the internal RCON connection.
