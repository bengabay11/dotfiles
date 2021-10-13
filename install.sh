function install() {
	system/install.sh
	git/install.sh
	terminal/install.sh
	python/install.sh
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	install;
else
	echo "This may overwrite existing files in your home directory."
        read -p "Do you want to continue? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		install;
	fi;
fi;
unset install;
