#!/usr/bin/env bash

git pull origin master;

function install() {
	apply_system_configurtion
	cp ./git/.gitconfig ~/
	chmod 755 ./terminal/banner.sh && ./terminal/banner.sh
}

function apply_system_configurtion() {
	for DOTFILE in ./system/.{function,aliases}; do
		echo "$DOTFILE"
  		[ -f "$DOTFILE" ] && echo "1"
done

}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	install;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		install;
	fi;
fi;
unset install;
