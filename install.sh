#!/bin/bash
# Default variables
function="install"
bool_data_dir="$HOME/.bool-data"
# Options
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
        case "$1" in
        -in|--install)
            function="install"
            shift
            ;;
        -un|--uninstall)
            function="uninstall"
            shift
            ;;
        *|--)
    break
	;;
	esac
done
install() {
#old ver
if [  -d $HOME/bool-network ]; then
  docker compose -f $HOME/bool-network/docker-compose.yml down -v
  sudo rm -rf $HOME/bool-network/
fi 
#docker install
cd
touch $HOME/.bash_profile
    if ! command -v docker &> /dev/null; then
		sudo apt update
		sudo apt upgrade -y
		sudo apt install curl apt-transport-https ca-certificates gnupg lsb-release -y
		. /etc/*-release
		wget -qO- "https://download.docker.com/linux/${DISTRIB_ID,,}/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt update
		sudo apt install docker-ce docker-ce-cli containerd.io -y
		docker_version=`apt-cache madison docker-ce | grep -oPm1 "(?<=docker-ce \| )([^_]+)(?= \| https)"`
		sudo apt install docker-ce="$docker_version" docker-ce-cli="$docker_version" containerd.io -y
	fi
	if ! command -v docker-compose &> /dev/null; then
		sudo apt update
		sudo apt upgrade -y
		sudo apt install wget jq -y
		local docker_compose_version=`wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name"`
		sudo wget -O /usr/bin/docker-compose "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`"
		sudo chmod +x /usr/bin/docker-compose
		. $HOME/.bash_profile
	fi
cd $HOME
#create dir and config
mkdir -p bool-testnode/node-data
chmod 777 $HOME/bool-testnode/node-data
# Create script 
tee $HOME/bool-testnode/docker-compose.yml > /dev/null <<EOF
version: "3"
services:
  bnk-node1:
    image: boolnetwork/bnk-node:pre-release
    restart: always
    environment:
      RUST_LOG: info
    volumes:
    - "./node-data:/data"
    command: |
      --validator
      --bootnodes /ip4/20.81.161.179/tcp/30333/ws/p2p/12D3KooWEA2uNEDyYq5Rzb1PW5TX7g6pF24s7r9c9ikQhAfUh9x1
      --enable-offchain-indexing true
      --rpc-methods Unsafe
      --unsafe-rpc-external
      --rpc-cors all
      --rpc-max-connections 100000
      --pool-limit 100000
      --pool-kbytes 2048000
      --tx-ban-seconds 600
      --blocks-pruning=archive
      --state-pruning=archive
      --ethapi=debug,trace,txpool
      --chain alpha_testnet
    ports:
      - 9944:9944
      - 30433:30333

EOF
sleep 2
#docker run
docker compose -f $HOME/bool-testnode/docker-compose.yml up -d
}
uninstall() {

docker compose -f $HOME/bool-testnode/docker-compose.yml down -v
sudo rm -rf $HOME/bool-testnode/
echo "Done"
cd
}
# Actions
sudo apt install wget -y &>/dev/null
cd
$function

