#!/usr/bin/env bash

cd /app

if [ "$WWWUSER" != "root" ] && [ "$WWWUSER" != "sail" ]; then
    echo "You should set SUPERVISOR_PHP_USER to either 'sail' or 'root'."
    exit 1
fi

if [ "$WWWUSER" != "root" ]; then
    if [ ! -z "$WWWUSER_ID" ]; then
        usermod -u $WWWUSER_ID $WWWUSER
    fi
fi

if [ ! -d /.composer ]; then
    mkdir /.composer
fi

chmod -R ugo+rw /.composer

if [ $# -gt 0 ]; then
     if [ "$WWWUSER" = "root" ]; then
        exec "$@"
    else
        exec gosu $WWWUSER "$@"
    fi
else
  echo "🎬 entrypoint.sh: [$(whoami) ($(id -u))] [FRANKENPHP $(frankenphp -v)]"
  echo "🎬 Detecting enviroment: ${APP_ENV}"
  echo "🎬 Detecting sail User: $WWWUSER ($WWWUSER_ID)"
  echo "🎬 Detecting PHP version: $(php -v | head -n 1)"

  DIR=/docker-entrypoint.d
  if [ -d "$DIR" ]; then
    echo "🎬 executing pre-scripts under $DIR"
    /bin/run-parts --verbose "$DIR"
    echo "✅ finished executing pre-scripts under $DIR"
  fi

  echo "🎬 start supervisord"

  exec supervisord -c /etc/supervisor/supervisord.conf
fi