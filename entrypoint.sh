#!/bin/sh

cd /app

if [ $# -gt 0 ]; then
    exec gosu $WWWUSER "$@"
else
  echo "🎬 entrypoint.sh: [$(whoami)] [FRANKENPHP $(frankenphp -v)]"
  echo "🎬 Detecting enviroment: ${APP_ENV}"

  DIR=/docker-entrypoint.d
  if [ -d "$DIR" ]; then
    echo "🎬 executing pre-scripts under $DIR"
    /bin/run-parts --verbose "$DIR"
    echo "✅ finished executing pre-scripts under $DIR"
  fi

  echo "🎬 start supervisord"

  supervisord -c /etc/supervisor/supervisord.conf
fi