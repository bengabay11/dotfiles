function install() {
	for DOTFILE in system/.{functions,aliases}; 
	do
		[ -f "$DOTFILE" ] && source "$DOTFILE" && echo "1"
	done
	cp ./git/.gitconfig ~/
	chmod 755 ./terminal/launch.sh && ./terminal/launch.sh
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
