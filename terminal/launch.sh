#!/bin/bash

sudo apt-get install -y figlet
sudo apt-get install -y lolcat
mv -f ~/print_ascii_art.sh ~/
cat banner.sh >> ~/.bashrc
