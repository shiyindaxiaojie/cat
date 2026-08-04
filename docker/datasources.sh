#!/usr/bin/env bash
set -eo pipefail

TARGET_XML="${CAT_DATASOURCES_XML:-/data/appdatas/cat/datasources.xml}"

echo "Initializing ${TARGET_XML}"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

xml_escape() {
    local value=$1
    local result=""
    local char
    local index

    for ((index = 0; index < ${#value}; index++)); do
        char=${value:index:1}
        case "${char}" in
            '&') result+='&amp;' ;;
            '<') result+='&lt;' ;;
            '>') result+='&gt;' ;;
            '"') result+='&quot;' ;;
            "'") result+='&apos;' ;;
            *) result+="${char}" ;;
        esac
    done

    printf '%s' "${result}"
}

render_line() {
    local text=$1
    local result=""

    # Scan only the original XML text. Values are appended directly and are
    # never scanned again, so a password such as "MYSQL_PASSWORD&/" stays intact.
    while [[ -n "${text}" ]]; do
        case "${text}" in
            MYSQL_URL*)
                result+="${MYSQL_URL}"
                text=${text#MYSQL_URL}
                ;;
            MYSQL_PORT*)
                result+="${MYSQL_PORT}"
                text=${text#MYSQL_PORT}
                ;;
            MYSQL_USERNAME*)
                result+="${ESCAPED_USERNAME}"
                text=${text#MYSQL_USERNAME}
                ;;
            MYSQL_PASSWORD*)
                result+="${ESCAPED_PASSWORD}"
                text=${text#MYSQL_PASSWORD}
                ;;
            MYSQL_SCHEMA*)
                result+="${MYSQL_SCHEMA}"
                text=${text#MYSQL_SCHEMA}
                ;;
            *)
                result+="${text:0:1}"
                text=${text:1}
                ;;
        esac
    done

    printf '%s' "${result}"
}

MYSQL_URL=${MYSQL_URL:-}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USERNAME=${MYSQL_USERNAME:-}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-}
MYSQL_SCHEMA=${MYSQL_SCHEMA:-cat}

[[ -f "${TARGET_XML}" ]] || fail "CAT datasource configuration not found: ${TARGET_XML}"
[[ -n "${MYSQL_URL}" ]] || fail "MYSQL_URL is required."
[[ -n "${MYSQL_USERNAME}" ]] || fail "MYSQL_USERNAME is required."
if [[ ! "${MYSQL_URL}" =~ ^[A-Za-z0-9_]([A-Za-z0-9._-]*[A-Za-z0-9_])?$ ]] \
    && [[ ! "${MYSQL_URL}" =~ ^\[[0-9A-Fa-f:]+\]$ ]]; then
    fail "MYSQL_URL must be a hostname, IPv4 address or bracketed IPv6 address."
fi
[[ "${MYSQL_PORT}" =~ ^[0-9]+$ ]] || fail "MYSQL_PORT must be numeric."
((MYSQL_PORT >= 1 && MYSQL_PORT <= 65535)) || fail "MYSQL_PORT must be between 1 and 65535."
[[ "${MYSQL_SCHEMA}" =~ ^[A-Za-z0-9_$-]+$ ]] || fail "MYSQL_SCHEMA contains unsupported characters."

for value in "${MYSQL_USERNAME}" "${MYSQL_PASSWORD}"; do
    [[ "${value}" != *$'\n'* && "${value}" != *$'\r'* ]] || fail "MySQL credentials must not contain line breaks."
done

ESCAPED_USERNAME=$(xml_escape "${MYSQL_USERNAME}")
ESCAPED_PASSWORD=$(xml_escape "${MYSQL_PASSWORD}")

mkdir -p -- "$(dirname "${TARGET_XML}")"
TEMP_XML=$(mktemp "${TARGET_XML}.tmp.XXXXXX")
trap 'rm -f "${TEMP_XML}"' EXIT

while IFS= read -r line || [[ -n "${line}" ]]; do
    render_line "${line}"
    printf '\n'
done < "${TARGET_XML}" > "${TEMP_XML}"

if [[ -f "${TARGET_XML}" ]]; then
    chmod --reference="${TARGET_XML}" "${TEMP_XML}"
else
    chmod 0640 "${TEMP_XML}"
fi

mv "${TEMP_XML}" "${TARGET_XML}"
trap - EXIT

echo "Initialize datasources.xml completed: ${TARGET_XML}"
