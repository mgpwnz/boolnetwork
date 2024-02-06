#!/bin/bash
# Default variables
function="install"
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
read -p "Node Name : " BOOLNAME
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
mkdir $HOME/bool-network/

# Create script 
tee $HOME/bool-network/docker-compose.yml > /dev/null <<EOF
version: "3.7"
name: bool

services:
  validator:
    image: boolnetwork/bnk-node:release
    restart: always
    command: |
      --validator
      --chain=tee
      --in-peers=1000
      --name=$BOOLNAME
    ports:
    - '30333:30333'
    volumes:
    - $HOME/.bool-data:/bool/.local/share/bnk-node
volumes:
  data:

EOF
sleep 2
#create data
mkdir $HOME/.bool-data
chown -R 1000:1000 $HOME/.bool-data
#docker run
docker compose up -f $HOME/bool-network/docker-compose.yml -d
}
uninstall() {

docker compose down -f $HOME/bool-network/docker-compose.yml -v
sudo rm -rf $HOME/bool-network/ 
echo "Done"
cd
}
# Actions
sudo apt install wget -y &>/dev/null
cd
$function

