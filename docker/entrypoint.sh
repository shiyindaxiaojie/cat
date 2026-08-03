#!/usr/bin/env bash
set -eo pipefail

# Only initialize CAT for the normal Tomcat command. This keeps diagnostic commands
# such as `docker run IMAGE bash` usable without requiring deployment variables.
if [[ "${1##*/}" == "catalina.sh" ]]; then
    # env.sh must be sourced so the generated JAVA_OPTS remains available to Tomcat.
    source "${CATALINA_HOME}/env.sh"

    "${CATALINA_HOME}/datasources.sh"
    "${CATALINA_HOME}/client.sh"
fi

exec "$@"
