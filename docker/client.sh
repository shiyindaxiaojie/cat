#!/usr/bin/env bash
set -eo pipefail

CLIENT_XML="${CAT_CLIENT_XML:-/data/appdatas/cat/client.xml}"
CAT_TCP_PORT="${CAT_TCP_PORT:-2280}"
CAT_HTTP_PORT="${CAT_HTTP_PORT:-8080}"

echo "Initializing ${CLIENT_XML}"

for port_name in CAT_TCP_PORT CAT_HTTP_PORT; do
    port_value=${!port_name}
    if [[ ! "${port_value}" =~ ^[0-9]+$ ]] || ((port_value < 1 || port_value > 65535)); then
        echo "ERROR: ${port_name} must be between 1 and 65535; got '${port_value}'." >&2
        exit 1
    fi
done

if [[ ! -f "${CLIENT_XML}" ]]; then
    echo "ERROR: CAT client configuration is missing: ${CLIENT_XML}" >&2
    exit 1
fi

if [[ ! -w "${CLIENT_XML}" ]]; then
    echo "ERROR: CAT client configuration is not writable: ${CLIENT_XML}" >&2
    exit 1
fi

determine_pod_ip() {
    local pod_ip
    if [[ -n "${POD_IP:-}" ]]; then
        echo "${POD_IP}"
    else
        pod_ip=$(hostname -i 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $i !~ /^127\./) { print $i; exit } }')
        if [[ -z "${pod_ip}" ]] && command -v ifconfig &>/dev/null; then
            pod_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1 || true)
        fi
        echo "${pod_ip}"
    fi
}

is_ipv4() {
    local address=$1
    local octet
    local -a octets

    [[ "${address}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    IFS='.' read -ra octets <<< "${address}"
    for octet in "${octets[@]}"; do
        ((10#${octet} <= 255)) || return 1
    done
}

resolve_dns() {
    local domain=$1
    local ips=()

    if command -v getent &>/dev/null; then
        readarray -t ips < <(getent ahostsv4 "${domain}" 2>/dev/null | awk '$1 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ {print $1}' | sort -u || true)
    elif command -v dig &>/dev/null; then
        readarray -t ips < <(dig +short A "${domain}" 2>/dev/null | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | sort -u || true)
    elif command -v nslookup &>/dev/null; then
        readarray -t ips < <(nslookup "${domain}" 2>/dev/null | awk '/^Address: / && $2 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $2 !~ /^127\./ {print $2}' | sort -u || true)
    else
        echo "WARNING: No DNS tools available; keeping hostname in client.xml: ${domain}" >&2
    fi

    if [[ ${#ips[@]} -gt 0 ]]; then
        printf '%s\n' "${ips[@]}"
        return 0
    fi

    return 1
}

SERVER_URL="${SERVER_URL:-}"
if [[ -z "${SERVER_URL}" ]]; then
    POD_IP=$(determine_pod_ip)
    if [[ -z "${POD_IP}" ]]; then
        POD_IP="127.0.0.1"
    fi
    SERVER_URL="${POD_IP}"
    echo "SERVER_URL not specified; using local CAT endpoint: ${SERVER_URL}"
fi

declare -a FINAL_ENDPOINTS=()
IFS=',' read -ra URL_ARRAY <<< "${SERVER_URL}"

for url in "${URL_ARRAY[@]}"; do
    url="${url#"${url%%[![:space:]]*}"}"
    url="${url%"${url##*[![:space:]]}"}"
    [[ -z "${url}" ]] && continue

    if is_ipv4 "${url}"; then
        FINAL_ENDPOINTS+=("${url}")
        echo "Using static IP: ${url}"
    elif [[ "${url}" =~ ^([0-9]+\.){3}[0-9]+$ ]]; then
        echo "ERROR: Invalid IPv4 address in SERVER_URL: ${url}" >&2
        exit 1
    elif [[ "${url}" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
        if [[ "${RESOLVE_SERVER_URL:-N}" != "Y" ]]; then
            echo "Using DNS endpoint: ${url}"
            FINAL_ENDPOINTS+=("${url}")
            continue
        fi

        echo "Resolving DNS endpoint to a startup IP snapshot: ${url}"
        resolved_ips=()
        readarray -t resolved_ips < <(resolve_dns "${url}" || true)

        if [[ ${#resolved_ips[@]} -eq 0 ]]; then
            echo "WARNING: DNS endpoint is not currently resolvable; keeping hostname in client.xml: ${url}" >&2
            FINAL_ENDPOINTS+=("${url}")
            continue
        fi

        for ip in "${resolved_ips[@]}"; do
            echo "Resolved IP: ${ip}"
            FINAL_ENDPOINTS+=("${ip}")
        done
    else
        echo "ERROR: Invalid SERVER_URL endpoint: ${url}" >&2
        exit 1
    fi
done

if [[ ${#FINAL_ENDPOINTS[@]} -eq 0 ]]; then
    echo "ERROR: SERVER_URL did not contain any usable endpoints." >&2
    exit 1
fi

declare -A SEEN_ENDPOINTS=()
declare -a UNIQUE_ENDPOINTS=()
for endpoint in "${FINAL_ENDPOINTS[@]}"; do
    if [[ -z "${SEEN_ENDPOINTS[${endpoint}]:-}" ]]; then
        SEEN_ENDPOINTS["${endpoint}"]=1
        UNIQUE_ENDPOINTS+=("${endpoint}")
    fi
done

if ! grep -q '<servers>' "${CLIENT_XML}"; then
    echo "ERROR: Invalid CAT client configuration; <servers> element is missing: ${CLIENT_XML}" >&2
    exit 1
fi

ENDPOINT_LIST=$(IFS=,; echo "${UNIQUE_ENDPOINTS[*]}")
TEMP_CLIENT_XML=$(mktemp "${CLIENT_XML}.tmp.XXXXXX")
trap 'rm -f "${TEMP_CLIENT_XML}"' EXIT

awk -v endpoints="${ENDPOINT_LIST}" '
    /<server[[:space:]][^>]*\/>/ { next }
    /<servers>/ {
        print
        count = split(endpoints, values, ",")
        for (i = 1; i <= count; i++) {
            printf "        <server ip=\"%s\" port=\"%s\" http-port=\"%s\"/>\n", values[i], tcp_port, http_port
        }
        next
    }
    { print }
' tcp_port="${CAT_TCP_PORT}" http_port="${CAT_HTTP_PORT}" "${CLIENT_XML}" > "${TEMP_CLIENT_XML}"

chmod --reference="${CLIENT_XML}" "${TEMP_CLIENT_XML}"
mv "${TEMP_CLIENT_XML}" "${CLIENT_XML}"
trap - EXIT

echo "Initialize client.xml completed with endpoints: ${UNIQUE_ENDPOINTS[*]}"
