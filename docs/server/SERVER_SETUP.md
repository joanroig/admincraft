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
- Memory (GB): 12

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

```
- Source CIDR: 0.0.0.0/0
- IP Protocol: TCP
- Destination Port Range: 8080
- Description: Admincraft WebSocket port
```

## Setup the Minecraft server

1. Login via [MobaXterm](https://mobaxterm.mobatek.net/download.html) or the tool of your choice by using the IP, SSH Keys and username (ubuntu if you choose an Ubuntu image).
2. Once connected, execute those commands to open the needed ports for Minecraft and Admincraft WebSocket:

```
sudo iptables -I INPUT 6 -m state --state NEW -p udp --dport 19132 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8080 -j ACCEPT
sudo netfilter-persistent save
```

3. Edit the [docker-compose.yml](docker-compose.yml) file:

   - Change the `services.websocket.environment.SECRET_KEY` variable for a strong password you will use to control the server with Admincraft.
   - Change any other variables you like in `services.minecraft`, like the `LEVEL_NAME` or `LEVEL_SEED`, you can see a full list [here](https://github.com/itzg/docker-minecraft-bedrock-server?tab=readme-ov-file#server-properties).

4. Make sure to edit the [backups-config/config.yml](backups-config/config.yml) file, the `worlds` setting should match the one you have introduced in the setting `LEVEL_NAME` in the [docker-compose.yml](docker-compose.yml). You can also change the backups frequency as you like.

> **_NOTE:_** If you want to enable SSL, follow the next chapter before continuing (recommended)!

5. Upload the [docker-compose.yml](docker-compose.yml) file and the [backups-config](backups-config) folder to the home folder of your server.
6. Run `sudo docker compose up -d` to start your server for the first time.
7. You should now be able to connect to your server with Minecraft and with Admincraft!

> **_NOTE:_** If you enabled the setting `ALLOW_LIST = true` in the [docker-compose.yml](docker-compose.yml), you will need to whitelist the users you want to be able to connect with the command `whitelist add username`.

## Optional: Configure SSL

1. Edit the [certs/makecerts.sh](certs/makecerts.sh) by changing the variable `COMMON_NAME=YOUR_IP_HERE` for your server IP.
2. Upload the [certs](certs) folder to the home folder of your server.
3. Make the script executable, format it for Linux, and run it to generate the certificates:

```
cd certs
chmod +x makecerts.sh
sed -i 's/\r$//' makecerts.sh
./makecerts.sh
```

4. Ensure that the `services.websocket.environment.USE_SSL` variable in the [docker-compose.yml](docker-compose.yml) file is set to true.

5. The `server.crt` certificate can be downloaded directly from the server to avoid Man-in-the-Middle attacks. If using a safe network, it can download it from [https://IP:8080/getcert](https://IP:8080/getcert) ignoring the security warnings.

## Login to Admincraft

- Open Admincraft and use the server IP and the SECRET_KEY you set in the previous steps. If you enabled SSL, also provide the `server.crt`.
- Admincraft should connect automatically and display the server logs. If there is any issue you will be prompted with an error pop-up.

## Automatic Upgrade and Backups

To update the Minecraft server to the latest version, simply restart it from the Admincraft Control Panel, or execute this command in the server:

`sudo docker compose restart`

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

   - Accessible via port `8080`, allowing secure control of the Minecraft server using Admincraft.
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
