#!/bin/sh
#
# Server Switcher
# (c) 2023 Marc Anton Dahmen, MIT license
#

BASE=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
BREW=$(brew --prefix)
SYS_TMP=/tmp

if [ ! -f "$BASE/.env" ]
then
	echo ".env file is missing ..."
	exit
fi

source "$BASE/.env"

mkdir -p "$BASE/tmp"

addNginxLocations() {
	local file=$1
	local contents=$(cat "$BASE/tmp/$file")

	echo "Adding locations for all sites ..."

	local sites=$(\
		find $DOC_ROOT \
		-type f \
		-name index.php \
		-mindepth 2 \
		-maxdepth 8 \
		-exec dirname {} \; | \
		grep -v 'cache' | \
		grep -v 'vendor'\
	)

	local locations="\n"

	for site in $sites
	do
		path=${site#"$DOC_ROOT"}
		locations+="\t\tlocation $path { try_files \$uri \$uri/ $path/index.php\$is_args\$args; }\n"
	done

	printf "$contents" | sed "s|__NGINX_LOCATIONS__|$locations|g" > "$BASE/tmp/$file"
}

renderConfig() {
	local file=$1
	local contents=$(cat "$BASE/config/$file")

	printf "$contents" | \
		sed "s|__SERVER_NAME__|$SERVER_NAME|g" | \
		sed "s|__PORT__|$PORT|g" | \
		sed "s|__PHP_PORT__|$PHP_PORT|g" | \
		sed "s|__USER__|$USER|g" | \
		sed "s|__DOC_ROOT__|$DOC_ROOT|g" | \
		sed "s|__PROXY_PATH__|$PROXY_PATH|g" | \
		sed "s|__PROXY_PORT__|$PROXY_PORT|g" | \
		sed "s|__BREW__|$BREW|g" | \
		sed "s|__SYS_TMP__|$SYS_TMP|g" > \
		"$BASE/tmp/$file"
}

createOptions() {
	local options=''
	local phpVersions=$(brew list | grep -E "php(@|$)")

	for server in 'Apache' 'Nginx' 'Apache Proxy > Nginx' 'Nginx Proxy > Apache' 
	do
		for php in $phpVersions
		do
			local suffix=""
			if ! printf $php | grep -qs '@'; then local suffix=" (latest)"; fi 
			options+="$server with $(echo $php | awk '{print toupper($0)}')$suffix\n"
		done
	done

	options+='Stop All Servers'

	printf "$options"
}

stopAll() {
	echo "Stopping servers ..."
	apachectl -k stop >/dev/null
	ps -lef | grep nginx: | awk '{print $2}' | xargs kill -9 2>/dev/null
	brew services list | grep started | grep php | awk '{print $1}' | xargs brew services stop 
}

startApache() {
	renderConfig 'httpd.conf'
	echo 'Starting Apache ...'
	apachectl -k start -f "$BASE/tmp/httpd.conf" 
}

startApacheProxy() {
	renderConfig 'httpd-proxy.conf'
	echo 'Starting Apache Proxy ...'
	apachectl -k start -f "$BASE/tmp/httpd-proxy.conf"
	startNginx
}

startNginx() {
	renderConfig 'nginx.conf'
	addNginxLocations 'nginx.conf'
	echo "Starting Nginx ..."
	nginx -c "$BASE/tmp/nginx.conf"
}

startNginxProxy() {
	renderConfig 'nginx-proxy.conf'
	addNginxLocations 'nginx.conf'
	echo 'Starting Nginx Proxy ...'
	nginx -c "$BASE/tmp/nginx-proxy.conf"
	startApache
}

startPHP() {
	local version="$1"
	local conf="$BASE/tmp/server-switcher.conf"

	renderConfig 'php.conf'
	mv "$BASE/tmp/php.conf" "$conf" 
	find $BREW/etc/php/*/php-fpm.d -type d -maxdepth 0 -exec cp "$conf" {} \;
	brew services start "$version"
}

parseSelected() {
	stopAll
	
	if printf "$1" | grep -qs 'Stop'; then return; fi

	local php=$(echo "$1" | grep -E -i -o 'PHP(@\d\.\d)?' | awk '{print tolower($0)}')
	startPHP $php
	
	if printf "$1" | grep -qis 'nginx proxy'; then startNginxProxy; return; fi
	if printf "$1" | grep -qis 'apache proxy'; then startApacheProxy; return; fi
	
	if printf "$1" | grep -qis 'nginx'; then startNginx; return; fi
	if printf "$1" | grep -qis 'apache'; then startApache; return; fi
}

selected=$(printf "$(createOptions)" | fzf --layout=reverse --height=30%)

if [[ -z $selected ]]
then
	exit
fi

parseSelected "$selected"
