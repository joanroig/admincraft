# Add Admincraft to a server you already run

Nothing here recreates your world or restarts Minecraft unnecessarily. Pick the section that matches what you have.

## You already run itzg containers

This is the arrangement Admincraft is built for, and it needs one extra container beside the one you have. Minecraft itself is untouched.

!!! tip "Skip the copying"
    [`docker-compose.admincraft.yml`](../server/docker-compose.admincraft.yml) is the
    service below, ready to layer on top of your own file so you never edit it:

    ```bash
    curl -fsSLO https://raw.githubusercontent.com/joanroig/admincraft/main/docs/server/docker-compose.admincraft.yml
    docker compose -f docker-compose.yml -f docker-compose.admincraft.yml up -d
    ```

    Set `SECRET_KEY` first, and for Java also `SERVER_TYPE: java` and the RCON values.

### Bedrock

The bridge reads the server console through the Docker socket, so it needs the container name and a secret of its own. Add this service to your existing `docker-compose.yml`:

```yaml
  websocket:
    container_name: websocket
    image: joanroig/admincraft-websocket:latest
    restart: always
    labels:
      com.centurylinklabs.watchtower.enable: "${ADMINCRAFT_AUTO_UPDATE:-true}"
    depends_on:
      minecraft:
        condition: service_healthy
    ports:
      # Keep this closed to the internet. See the security note below.
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      # Generate with: openssl rand -hex 32
      SECRET_KEY: YOUR_SECRET_KEY_HERE
      USE_SSL: "false"
      # Only needed if your Minecraft service is not called "minecraft".
      MC_NAME: minecraft

  admincraft-updater:
    container_name: admincraft-updater
    image: nickfedor/watchtower:1.16.1
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --label-enable --cleanup --interval 86400 websocket
    environment:
      WATCHTOWER_NO_STARTUP_MESSAGE: "true"
```

Then `docker compose up -d`. Only the new container starts; Minecraft keeps running.

Your Bedrock server also needs `ENABLE_SSH: true` so the bridge can reach its console. If it is missing, adding it does require recreating the Minecraft container, which restarts the world.

### Java

Java goes through RCON on the private Docker network, so the bridge needs the RCON details rather than the Docker socket:

```yaml
  websocket:
    container_name: websocket
    image: joanroig/admincraft-websocket:latest
    restart: always
    labels:
      com.centurylinklabs.watchtower.enable: "${ADMINCRAFT_AUTO_UPDATE:-true}"
    ports:
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      SECRET_KEY: YOUR_SECRET_KEY_HERE
      USE_SSL: "false"
      # Required: the bridge defaults to Bedrock and refuses a Java profile
      # with "profile is java, but this bridge is bedrock" without this.
      SERVER_TYPE: java
      MC_NAME: minecraft
      RCON_HOST: minecraft
      RCON_PORT: "25575"
      RCON_PASSWORD: YOUR_RCON_PASSWORD

  admincraft-updater:
    container_name: admincraft-updater
    image: nickfedor/watchtower:1.16.1
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --label-enable --cleanup --interval 86400 websocket
    environment:
      WATCHTOWER_NO_STARTUP_MESSAGE: "true"
```

Your Minecraft service needs RCON enabled (`ENABLE_RCON: "true"` and a matching `RCON_PASSWORD`) and should expose `25575` to the Docker network with `expose:`, never publish it with `ports:`.

### Bridge updates

The supplied Compose setup checks once a day for a newer Admincraft bridge,
recreates only the `websocket` container, and removes its superseded image. It
never updates Minecraft or any unrelated service. Existing app connections may
briefly reconnect while the bridge is replaced.

Automatic bridge updates are on by default. To opt out, create a `.env` file
beside the Compose file before starting the stack:

```dotenv
ADMINCRAFT_AUTO_UPDATE=false
```

You can still update manually at any time with:

```bash
docker compose pull websocket
docker compose up -d --force-recreate websocket
```

### Then secure the hop and connect

Port `8080` gives full command execution, so do not leave it open to the internet. The simplest arrangement is [Tailscale](../server/SERVER_SETUP.md#connect-admincraft-with-tailscale-recommended): join the server to your tailnet, keep `8080` closed in the firewall, and use **Private network** in Admincraft.

Then [install Admincraft](install.md) and [add the profile](first-server.md), using the server's private address, port `8080`, and the `SECRET_KEY` you just generated.

## Connect any Java server over RCON

If your Java server is not containerised, or you would rather add nothing to it, Admincraft can speak RCON directly. No bridge, no Docker, no companion container.

Enable it in `server.properties` and restart the server:

```properties
enable-rcon=true
rcon.port=25575
rcon.password=a-long-random-password
```

In Admincraft, choose **Java Edition** and the **Direct RCON, no bridge** connection type, then give the server's address, port `25575`, and that password.

!!! danger "RCON must never face the internet"
    RCON has no encryption. The password and every command travel in clear text, and anyone who can reach the port can try passwords freely. Put it behind Tailscale, a VPN or a LAN, and keep the port closed publicly.

What you give up compared with the bridge:

- **No live console.** RCON answers commands and pushes nothing, so the terminal shows replies only. Player joins and leaves never appear, and the player list is refreshed rather than watched.
- **No restart button.** Restarting is a container operation, and direct RCON does not go through Docker.
- **Not available in the browser.** A web page cannot open a raw socket. Use the Windows, macOS, Linux or Android build.

The [feature comparison](index.md#what-each-setup-gives-you) sets the two side by side.

## Neither of these fits

If you have no server yet, start from scratch with the [Bedrock server on Oracle's free tier](../server/SERVER_SETUP.md) or the [Java setup](java-server.md). Both end with a working server and Admincraft connected to it.
