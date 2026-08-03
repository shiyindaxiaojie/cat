#!/usr/bin/env bash
set -eo pipefail

# Only initialize CAT for the normal Tomcat command. This keeps diagnostic commands
# such as `docker run IMAGE bash` usable without requiring deployment variables.
if [[ "${1##*/}" == "catalina.sh" ]]; then
    # env.sh must be sourced so the generated JAVA_OPTS remains available to Tomcat.
    source "/data/appdatas/cat/env.sh"

    "/data/appdatas/cat/datasources.sh"
    "/data/appdatas/cat/client.sh"
fi

exec "$@"
