# ![Admincraft logo](../logo/variants/obsidian_glow.png) Minecraft Bedrock Server on Oracle Cloud (Always Free)

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

- In `Networking > Virtual cloud networks > your network > Subnet Details`, select `Security List Details` and press `Add Ingress Rules`:

```
Minecraft main port
- Source CIDR: 0.0.0.0/0
- IP Protocol: UDP
- Destination Port Range: 19132
- Description: minecraft port
```

## Setup

- Use the SSH Keys to login via MobaXterm
- Open the needed ports:

```
iptables -I INPUT -p udp -m udp --dport 19132 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```

- Download the [docker-compose.yml](docker-compose.yml) file, edit the settings you like, and upload it to the home directory in the server. Alternatively, customize yours from scratch using [the original file](https://github.com/itzg/docker-minecraft-bedrock-server/blob/master/examples/docker-compose.yml).

## Common Commands

See all available commands [here](https://minecraftbedrock-archive.fandom.com/wiki/Commands/List_of_Commands).

### Run containers

`sudo docker compose up -d`

### Stop containers

`sudo docker compose stop`

### Restart containers

`sudo docker compose restart`

### Remove all containers (the world will NOT be lost)

`sudo docker compose rm -fsv`

### Remove all server data (the world will be lost!)

`sudo rm -rf data/`

### See logs interactively, or see X log lines

`sudo docker compose logs -f`

### See X log lines

`sudo docker compose logs --tail 2`

### Send minecraft commands from outside the container

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

## Automatic Upgrade and Backups

To update the server, simply restart the docker container:

`sudo docker compose restart`

The docker compose configuration already has the backups enabled, make sure to download the [config.yml](config.yml) file, edit it as you like (the world name should match the one you have introduced in [docker-compose.yml](docker-compose.yml)!), and finally upload it to a folder named `backup-config` in the home directory of the server.

## Credits and sources

- https://github.com/itzg/docker-minecraft-bedrock-server
- https://github.com/techtute/minecraft-bedrock-tools/blob/main/install-bedrock-server.sh
- https://github.com/Kaiede/Bedrockifier
