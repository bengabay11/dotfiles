#!/bin/bash

update_bashrc() {
	echo "clear" >> ~/.bashrc
	echo "~/print_ascii_art.sh" >> ~/.bashrc
	command='figlet -f slant "BoonGooboon" | lolcat'
	echo $command >> ~/.bashrc
}

sudo apt-get install -y figlet
sudo apt-get install -y lolcat
mv -f ~/print_ascii_art.sh ~/
update_bashrc
