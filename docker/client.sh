#!/usr/bin/env bash
set -eo pipefail

echo "Initializing client.xml"

sed -i '/<server ip="[^"]*" port="2280" http-port="8080"\/>/d' /data/appdatas/cat/client.xml

determine_pod_ip() {
    local pod_ip
    if [[ -n "${POD_IP}" ]]; then
        echo "${POD_IP}"
    elif [[ -n "${HOST_IP}" ]]; then
        echo "${HOST_IP}"
    else
        pod_ip=$(hostname -i 2>/dev/null | awk '{print $1}')
        if [[ -z "${pod_ip}" ]]; then
            pod_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
        fi
        echo "${pod_ip}"
    fi
}

resolve_dns() {
    local domain=$1
    local ips=()

    if command -v getent &>/dev/null; then
        ips=($(getent ahosts "${domain}" | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}" | awk '{print $1}' | sort -u))
    elif command -v dig &>/dev/null; then
        ips=($(dig +short "${domain}" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | sort -u))
    elif command -v nslookup &>/dev/null; then
        ips=($(nslookup "${domain}" | awk '/Address:/ {if ($2 != "127.0.0.1") print $2}' | sort -u))
    else
        echo "WARNING: No DNS tools available, using domain directly: ${domain}"
        ips=("${domain}")
    fi

    if [[ ${#ips[@]} -eq 0 ]]; then
        ips=("${domain}")
    fi
    echo "${ips[@]}"
}

SERVER_URL=${SERVER_URL:-}
if [[ -z "${SERVER_URL}" ]]; then
    echo "SERVER_URL not specified, using Pod IP"
    POD_IP=$(determine_pod_ip)
    if [[ -z "${POD_IP}" ]]; then
        echo "ERROR: Unable to determine Pod IP. Please set SERVER_URL manually."
        exit 1
    fi
    SERVER_URL="${POD_IP}"
fi

declare -a FINAL_IPS
IFS=',' read -ra URL_ARRAY <<< "${SERVER_URL}"

for url in "${URL_ARRAY[@]}"; do
    url=$(echo "${url}" | xargs)
    [[ -z "${url}" ]] && continue

    if [[ "${url}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        FINAL_IPS+=("${url}")
        echo "Using static IP: ${url}"
    else
        echo "Resolving DNS: ${url}"
        resolved_ips=($(resolve_dns "${url}"))
        for ip in "${resolved_ips[@]}"; do
            if [[ "${ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                echo "Resolved IP: ${ip}"
                FINAL_IPS+=("${ip}")
            else
                echo "WARNING: Resolved non-IP value: ${ip}, using as-is"
                FINAL_IPS+=("${ip}")
            fi
        done
    fi
done

readarray -t UNIQUE_IPS < <(printf "%s\n" "${FINAL_IPS[@]}" | sort -u)

for ip in "${UNIQUE_IPS[@]}"; do
    sed -i "/<servers>/a <server ip=\"${ip}\" port=\"2280\" http-port=\"8080\"\/>" /data/appdatas/cat/client.xml
done

echo "client.xml initialization completed with IPs: ${UNIQUE_IPS[*]}"
