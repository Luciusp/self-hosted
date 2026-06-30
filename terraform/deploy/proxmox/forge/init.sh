mkdir -p /home/docker-lxc/servers
wget -P /home/docker-lxc/servers/komodo https://raw.githubusercontent.com/moghtech/komodo/main/compose/mongo.compose.yaml && \
wget -P /home/docker-lxc/servers/komodo https://raw.githubusercontent.com/moghtech/komodo/main/compose/compose.env

chown -R docker-lxc:docker-lxc /home/docker-lxc/servers
