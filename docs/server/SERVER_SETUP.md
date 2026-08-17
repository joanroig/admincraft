# ![Admincraft logo](../logo/variants/enderman.png) Minecraft Bedrock Server on Oracle Cloud (Always Free)

This guide provides instructions for setting up a Minecraft Bedrock server on [Oracle Cloud's Always Free tier](https://www.oracle.com/cloud/free/). It covers everything from creating a virtual machine (VM) on Oracle Cloud Infrastructure to configuring the server with Docker and managing the server using common commands. After finishing this guide, you'll be able to control your server with Admincraft!

## Setup a VM on Oracle Cloud

- Create a new instance with those settings:

```
Placement
- Availability domain: AD-1

Image and shape
- Image: Canonical Ubuntu 22.04
- Image build: 2024.06.26-0 (or any newer one)
- Shape: VM.Standard.A1.Flex
- OCPU count: 2
- Network bandwidth (Gbps): 2
- Memory (GB): 16

This uses the current Always Free maximum shown for an Ampere instance: 2
OCPUs and 16 GB of memory. Confirm that the Oracle console still marks the
shape as Always Free before creating it, because service limits and available
capacity can vary by account and region.

Primary VNIC information
- Virtual cloud network -> Choose one or create for later editing
- Subnet -> Choose one or create for later editing

Add SSH keys
Generate a key pair for me -> Download and store safely!

Boot volume
- Use in-transit encryption
```

- Once created, take a note of the server IP, you will need it to connect to your server.

- In `Networking > Virtual cloud networks > your network > Subnet Details`, select `Security List Details` and press `Add Ingress Rules`:

### Minecraft port

```
- Source CIDR: 0.0.0.0/0
- IP Protocol: UDP
- Destination Port Range: 19132
- Description: Minecraft port
```

### Admincraft WebSocket port

> **_NOTE:_** Only needed if you follow the [self-signed SSL alternative](#alternative-public-access-with-self-signed-ssl). The recommended Tailscale setup reaches the WebSocket over a private network, so this port stays closed to the internet.

```
- Source CIDR: 0.0.0.0/0
- IP Protocol: TCP
- Destination Port Range: 8080
- Description: Admincraft WebSocket port
```

## Setup the Minecraft server

1. Login via [MobaXterm](https://mobaxterm.mobatek.net/download.html) or the tool of your choice by using the IP, SSH Keys and username (ubuntu if you choose an Ubuntu image).
2. Once connected, execute those commands to open the Minecraft port:

```
sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 19132 -j ACCEPT
sudo netfilter-persistent save
```

> **_NOTE:_** Only add the WebSocket port if you follow the [self-signed SSL alternative](#alternative-public-access-with-self-signed-ssl):
> `sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8080 -j ACCEPT`

3. Edit the [docker-compose.yml](docker-compose.yml) file:

   - Change the `services.websocket.environment.SECRET_KEY` variable for a strong full-access key you will use to control the server with Admincraft. Generate one with `openssl rand -hex 32` and keep it out of any public repository: anyone holding it can run commands and manage the container. Current bridges can instead use `ADMIN_SECRET_KEY`, `COMMAND_SECRET_KEY`, and `READ_ONLY_SECRET_KEY` to issue least-privilege keys; see [Connection security](../guides/connection-security.md#choose-the-least-powerful-access-key).
   - Change any other variables you like in `services.minecraft`, like the `LEVEL_NAME` or `LEVEL_SEED`, you can see a full list [here](https://github.com/itzg/docker-minecraft-bedrock-server?tab=readme-ov-file#server-properties).

4. Make sure to edit the [backups-config/config.yml](backups-config/config.yml) file, the `worlds` setting should match the one you have introduced in the setting `LEVEL_NAME` in the [docker-compose.yml](docker-compose.yml). You can also change the backups frequency as you like.

5. Upload the [docker-compose.yml](docker-compose.yml) file, the [`backups-config`](https://github.com/joanroig/admincraft/tree/main/docs/server/backups-config) folder and the [update-server.sh](update-server.sh) script to the home folder of your server.
6. Run `sudo docker compose up -d` to start your server for the first time.
7. You should now be able to connect to your server with Minecraft. To connect with Admincraft, continue with the next chapter.

> **_NOTE:_** If you enabled the setting `ALLOW_LIST = true` in the [docker-compose.yml](docker-compose.yml), you will need to whitelist the users you want to be able to connect with the command `whitelist add username`.

## Choosing how to connect

The WebSocket gives full control of your server, so the connection always has to be encrypted by something: either the network it travels over, or TLS. Pick the option that fits you and follow its chapter below.

| Option | App on the client | Certificate to copy | Reachable from the internet |
| --- | --- | --- | --- |
| [Tailscale](#connect-admincraft-with-tailscale-recommended) (recommended) | Tailscale | no | no |
| [Tailscale Funnel](#alternative-tailscale-funnel-no-app-on-the-client) | none | no | yes |
| [Self-signed SSL](#alternative-public-access-with-self-signed-ssl) | none | yes, and again on every renewal | yes |

Each one maps to a **Connection type** in Admincraft: `Private network`, `Public address, trusted certificate` and `Public address, self-signed certificate`. Java servers can also skip the bridge entirely with `Direct RCON, no bridge`.

> **_NOTE:_** Running Admincraft in a browser narrows the choice. Self-signed certificates cannot be loaded at all, and if the app itself is served over HTTPS the browser blocks the unencrypted `Private network` option as mixed content. Tailscale Funnel is the option that always works in a browser.

## Connect Admincraft with Tailscale (recommended)

The WebSocket gives full control of your server, so it should never be exposed to the internet without protection. [Tailscale](https://tailscale.com) puts your phone and your server on a private encrypted network, so the WebSocket port stays invisible to everyone else. It is free for personal use, needs no certificates and nothing ever expires.

1. Install Tailscale on the server:

```
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

The command prints a login link. Open it and sign in.

> **_NOTE:_** Sign up with a personal account (Google, GitHub, Microsoft). Custom email domains are treated as business use and do not get the free Personal plan.

2. Note the server's Tailscale address:

```
tailscale ip -4
```

3. Install the Tailscale app on your phone or PC and sign in with the same account.

4. Open Admincraft and connect:

   - **IP / Hostname:** the Tailscale address from step 2 (for example `100.101.102.103`)
   - **Port:** `8080`
   - **Secret key:** the `SECRET_KEY` from your [docker-compose.yml](docker-compose.yml)
   - **Connection security:** `Private network`

Admincraft should connect automatically and display the server logs. If there is any issue you will be prompted with an error pop-up.

Traffic is encrypted by Tailscale itself, so no certificate is needed. Keep port `8080` closed in your cloud firewall: only your own devices can reach it.

> **_NOTE:_** Tailscale must be connected on the device running Admincraft. To let someone else administer the server, invite them to your Tailscale network instead of sharing the secret key.

## Alternative: Tailscale Funnel (no app on the client)

Use this if you do not want to install Tailscale on every device running Admincraft. Only the server runs Tailscale; Funnel publishes the WebSocket on a public hostname with a certificate that renews itself, so there is still nothing to copy into the app.

Follow step 1 of the Tailscale setup above to install Tailscale on the server, then:

1. Funnel terminates TLS for you, so the WebSocket should speak plain HTTP and listen only on the server itself. In the [docker-compose.yml](docker-compose.yml), set `USE_SSL: "false"` and bind the port to loopback:

```yaml
    ports:
      - 127.0.0.1:8080:8080
```

Apply it with `sudo docker compose up -d`. Binding to `127.0.0.1` is what keeps the socket private: Funnel reaches it from the server itself, nothing else can, and the cloud firewall becomes a second layer instead of the only one.

2. Publish it:

```
sudo tailscale funnel --bg 8080
sudo tailscale funnel status
```

> **_NOTE:_** The first run blocks and prints `Funnel is not enabled on your tailnet` with a link. Open the link to enable Funnel, then run the command again. It does not continue on its own.

`status` reports your public hostname, in the form `machine-name.tailnet-name.ts.net`. Tailscale requests and renews the certificate automatically; the public side always uses port `443`.

3. Connect Admincraft with:

- **IP / Hostname:** the `ts.net` hostname reported by `tailscale funnel status`
- **Port:** `443`
- **Secret key:** the `SECRET_KEY` from your [docker-compose.yml](docker-compose.yml)
- **Connection security:** `Public certificate`

> **_NOTE:_** With the port bound to `127.0.0.1`, the private Tailscale option above stops working, because devices on your tailnet can no longer reach it either. To use both, add a second mapping for the server's Tailscale address, for example `- 100.101.102.103:8080:8080`.

> **_WARNING:_** Funnel makes the WebSocket reachable from the whole internet, so the `SECRET_KEY` becomes the only thing protecting your server. Use a long random value and never commit it anywhere public. The private Tailscale setup above is safer.

## Alternative: public access with self-signed SSL

Use this if you cannot install Tailscale on the device running Admincraft, or you need the WebSocket reachable from anywhere. It exposes port `8080` to the internet, so SSL is mandatory and the certificate has to be copied into Admincraft by hand.

Open port `8080` first (see [Setup a VM on Oracle Cloud](#setup-a-vm-on-oracle-cloud) and step 2 of the server setup), then:

1. Edit the [certs/makecerts.sh](certs/makecerts.sh) by changing the variable `COMMON_NAME=YOUR_IP_HERE` for your server IP.
2. Upload the [`certs`](https://github.com/joanroig/admincraft/tree/main/docs/server/certs) folder to the home folder of your server.
3. Make the script executable, format it for Linux, and run it to generate the certificates:

```
cd certs
chmod +x makecerts.sh
sed -i 's/\r$//' makecerts.sh
./makecerts.sh
```

4. In the [docker-compose.yml](docker-compose.yml) file, set `services.websocket.environment.USE_SSL` to `"true"` and uncomment the `./certs` volume mount.

5. The `server.crt` certificate can be downloaded directly from the server to avoid Man-in-the-Middle attacks. If using a safe network, it can download it from [https://IP:8080/getcert](https://IP:8080/getcert) ignoring the security warnings.

6. Open Admincraft and connect:

   - **IP / Hostname:** your server IP
   - **Port:** `8080`
   - **Secret key:** the `SECRET_KEY` from your [docker-compose.yml](docker-compose.yml)
   - **Connection security:** `Self-signed certificate`, then load `server.crt`

> **_WARNING:_** Do not expose port `8080` with `Private network` selected. That mode sends your secret key and every command in clear text, and is only safe inside Tailscale, a VPN or a LAN.

> **_NOTE:_** `makecerts.sh` issues certificates valid for one year. Once it expires Admincraft will refuse to connect, and you have to run the script again and reload `server.crt`. The Tailscale options avoid this entirely.

## Keeping the Server Updated

There are **two** separate things that need updating, and confusing them will leave your server stranded on an old version:

| What | How it updates |
| --- | --- |
| **Bedrock server binary** | Re-checked against Mojang's API on every container start, so a restart is enough. |
| **Admincraft bridge image** | The supplied Compose file checks daily and replaces only the bridge by default. |
| **Minecraft and backup images** | Update when you explicitly run `docker compose pull`, or through the optional nightly job below. |

Restarting Minecraft alone handles the first but does not pull any image. That
matters because the version lookup lives inside the Minecraft image: when
Mojang changed their download page, older images failed with `Unable to find an
element with attribute matcher data-platform=serverBedrockLinux` and silently
kept running the last version they had. Newer images query a JSON API instead.

### Automatic bridge update (on by default)

The `admincraft-updater` service checks every 24 hours and recreates only the
`websocket` container when `joanroig/admincraft-websocket:latest` changes. Its
label filter and explicit container name prevent it from updating Minecraft,
backups, databases, or unrelated containers. Superseded bridge images are
removed automatically.

Check it with:

```bash
sudo docker logs admincraft-updater
```

To opt out, create a `.env` file beside `docker-compose.yml`, then recreate the
updater and bridge:

```dotenv
ADMINCRAFT_AUTO_UPDATE=false
```

```bash
sudo docker compose up -d --force-recreate websocket admincraft-updater
```

### Manual update

```
sudo docker compose pull
sudo docker compose up -d
```

If the pull fails with `unauthorized: your account must log in with a Personal Access Token (PAT)`, a stale Docker Hub credential is stored for `root`. Clear it and retry:

```
sudo docker logout
```

### Automatic nightly update

[update-server.sh](update-server.sh) warns any online players, pulls new images, recreates the stack, prunes old images, and then **verifies that a fresh backup actually landed** before reporting success. Upload it to your home folder and install it:

```
chmod +x ~/update-server.sh
sudo chown root:root ~/update-server.sh
sudo crontab -e
```

Add this line to run it every night at 04:00:

```
0 4 * * * /home/ubuntu/update-server.sh >> /var/log/minecraft-update.log 2>&1
```

> **_NOTE:_** Cron follows the host's system clock. Check yours with `timedatectl` before assuming a time zone.

Review runs with `sudo tail -n 40 /var/log/minecraft-update.log`.

Because `VERSION` defaults to `LATEST`, this means Mojang decides when your world converts to a new format, and **Bedrock world upgrades are one-way**. The nightly backup taken immediately after each update is your safety net. If you would rather approve each version bump yourself, pin `VERSION: 1.26.43.1` (or whichever build you want) in the [docker-compose.yml](docker-compose.yml) — you will still receive image fixes automatically without surprise world conversions.

## Backups

Backups are handled by the `backup` container and configured in [backups-config/config.yml](backups-config/config.yml). With `runInitialBackup: true`, a snapshot is taken on every service start in addition to the regular interval, so each nightly update leaves a restore point behind.

Check that backups are working:

```
sudo ls -lht ~/backups
sudo docker exec backup /opt/bedrock/bedrockifier healthcheck
```

Force one immediately:

```
sudo docker exec backup /opt/bedrock/bedrockifier trigger-backup
```

> **_NOTE:_** The container's healthcheck only covers its HTTP endpoint, so it can report `healthy` while no backups are being written. Trust the timestamps in `~/backups` over the container status.

## Common Server Commands

See all available commands [here](https://minecraftbedrock-archive.fandom.com/wiki/Commands/List_of_Commands).

### Run containers in the background (detached mode)

`sudo docker compose up -d`

### Run containers in the foreground (for debugging)

`sudo docker compose up`

### Stop containers

`sudo docker compose stop`

### Restart containers

`sudo docker compose restart`

### Remove all containers (the world will not be lost)

`sudo docker compose rm -fsv`

### Remove all containers and volumes (the world will not be lost)

`sudo docker rm -vf $(sudo docker ps -aq)`

### Remove all images (the world will not be lost)

`sudo docker rmi -f $(sudo docker images -aq)`

### Remove all server data (the world WILL BE LOST!)

`sudo rm -rf minecraft/`

### See logs interactively

`sudo docker compose logs -f`

### See X log lines

`sudo docker compose logs --tail 2`

### See logs interactively for a specific container

```
sudo docker compose logs admincraft -f
sudo docker compose logs websocket -f
```

### Send minecraft commands from outside the container (this is exactly how Admincraft controls the server)

```
sudo docker exec minecraft send-command <commandname>

sudo docker exec minecraft send-command whitelist add moaibeats
sudo docker exec minecraft send-command give moaibeats coal 20
sudo docker exec minecraft send-command time set 2000
```

### Go into the container's command line (do not exit with CTRL-C! Use CTRL-P CTRL-Q)

`sudo docker attach minecraft`

#### Some examples

```
whitelist add moaibeats
give moaibeats coal 20
```

### Go into the container's shell

`sudo docker exec -ti minecraft /bin/bash`

## Architecture

The system consists of three main containers running in a Docker environment:

1. **Minecraft Bedrock Server** (`minecraft`):

   - Exposes the Minecraft server to the internet through port `19132/udp`.
   - Accepts incoming connections from Minecraft clients.
   - SSH access is enabled for the backup process, and the Minecraft server data is stored in a mounted volume.
   - Server configuration is set in the `docker-compose.yml` file, allowing for customization of settings such as world seed, level name, and gameplay modes.

2. **Admincraft WebSocket Server** (`websocket`):

   - Listens on port `8080`, allowing control of the Minecraft server using Admincraft. In the recommended setup this port is reached over Tailscale and stays closed to the internet; the self-signed SSL alternative exposes it publicly instead.
   - The WebSocket server authenticates incoming connections using JWT (JSON Web Tokens), with the `SECRET_KEY` stored in environment variables.
   - Once authenticated, users can issue Minecraft server commands, which are executed in real time within the Minecraft container.
   - Additionally, certain Docker-level commands (like restarting the server) can be executed through the WebSocket interface, but these are restricted to predefined key commands for security reasons.

3. **Backup Server** (`backup`):
   - Connects to the Minecraft server every few hours via SSH to back up world data.
   - The backup server uses a mounted volume to store backup files in a dedicated folder, ensuring Minecraft server data can be restored if needed.
   - Backup configurations, including the backup schedule and the target Minecraft server, are stored in the `backups-config/config.yml` file.

## Credits and sources

- https://github.com/itzg/docker-minecraft-bedrock-server
- https://github.com/Kaiede/Bedrockifier
- https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/apache-on-ubuntu/01oci-ubuntu-apache-summary.htm
