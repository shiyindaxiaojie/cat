#!/usr/bin/env bash
set -eo pipefail

fail() {
    echo "ERROR: $*" >&2
    return 1 2>/dev/null || exit 1
}

append_java_opt() {
    if [[ -n "${JAVA_OPTS}" ]]; then
        JAVA_OPTS="${JAVA_OPTS} $1"
    else
        JAVA_OPTS="$1"
    fi
}

validate_size() {
    local name=$1
    local value=$2

    if [[ ! "${value}" =~ ^[0-9]+[kKmMgG]?$ ]]; then
        fail "${name} must be a JVM size such as 512m, 1g or 4096m; got '${value}'."
    fi
}

size_in_bytes() {
    local value=${1,,}
    local number=${value%[kmg]}
    local suffix=${value:${#number}}
    local multiplier=1

    case "${suffix}" in
        k) multiplier=1024 ;;
        m) multiplier=$((1024 * 1024)) ;;
        g) multiplier=$((1024 * 1024 * 1024)) ;;
    esac

    echo $((10#${number} * multiplier))
}

validate_positive_integer() {
    local name=$1
    local value=$2

    if [[ ! "${value}" =~ ^[1-9][0-9]*$ ]]; then
        fail "${name} must be a positive integer; got '${value}'."
    fi
}

JAVA_VERSION_TEXT=$(java -version 2>&1) || fail "Unable to execute java -version."
JAVA_VERSION_TOKEN=$(printf '%s\n' "${JAVA_VERSION_TEXT}" | sed -E -n 's/.* version "([0-9]+(\.[0-9]+)?).*$/\1/p' | head -n 1)

if [[ "${JAVA_VERSION_TOKEN}" == 1.* ]]; then
    JAVA_MAJOR_VERSION=${JAVA_VERSION_TOKEN#1.}
else
    JAVA_MAJOR_VERSION=${JAVA_VERSION_TOKEN%%.*}
fi

if [[ ! "${JAVA_MAJOR_VERSION}" =~ ^[0-9]+$ ]]; then
    fail "Unable to determine Java major version from: ${JAVA_VERSION_TEXT}"
fi

XMX=${XMX:-1g}
XMS=${XMS:-${XMX}}
XSS=${XSS:-256k}
METASPACE_SIZE=${METASPACE_SIZE:-128m}
MAX_METASPACE_SIZE=${MAX_METASPACE_SIZE:-256m}

validate_size XMS "${XMS}"
validate_size XMX "${XMX}"
validate_size XSS "${XSS}"
validate_size METASPACE_SIZE "${METASPACE_SIZE}"
validate_size MAX_METASPACE_SIZE "${MAX_METASPACE_SIZE}"

if [[ "$(size_in_bytes "${XMS}")" -ne "$(size_in_bytes "${XMX}")" ]]; then
    fail "XMS and XMX must be equal; got XMS='${XMS}' and XMX='${XMX}'."
fi

JAVA_OPTS="${JAVA_OPTS:-}"
append_java_opt "-server"
append_java_opt "-XX:+UnlockExperimentalVMOptions"
append_java_opt "-XX:+UnlockDiagnosticVMOptions"
append_java_opt "-XX:-DisplayVMOutput"
append_java_opt "-XX:-OmitStackTraceInFastThrow"
append_java_opt "-Xms${XMS}"
append_java_opt "-Xmx${XMX}"
append_java_opt "-Xss${XSS}"
append_java_opt "-XX:MetaspaceSize=${METASPACE_SIZE}"
append_java_opt "-XX:MaxMetaspaceSize=${MAX_METASPACE_SIZE}"

if [[ "${USE_ALWAYS_PRETOUCH:-N}" == "Y" ]]; then
    append_java_opt "-XX:+AlwaysPreTouch"
fi

if [[ "${PRINT_JVM_FLAGS:-N}" == "Y" ]]; then
    append_java_opt "-XX:+PrintFlagsFinal"
fi

case "${GC_MODE:-G1}" in
    G1)
        echo "GC mode is G1"
        append_java_opt "-XX:+UseG1GC"
        append_java_opt "-XX:MaxGCPauseMillis=${MAX_GC_PAUSE_MILLIS:-200}"
        append_java_opt "-XX:+ParallelRefProcEnabled"

        if [[ "${USE_STRING_DEDUPLICATION:-N}" == "Y" ]]; then
            append_java_opt "-XX:+UseStringDeduplication"
        fi

        [[ -n "${INITIATING_HEAP_OCCUPANCY_PERCENT:-}" ]] && append_java_opt "-XX:InitiatingHeapOccupancyPercent=${INITIATING_HEAP_OCCUPANCY_PERCENT}"
        [[ -n "${G1_RESERVE_PERCENT:-}" ]] && append_java_opt "-XX:G1ReservePercent=${G1_RESERVE_PERCENT}"
        [[ -n "${G1_HEAP_WASTE_PERCENT:-}" ]] && append_java_opt "-XX:G1HeapWastePercent=${G1_HEAP_WASTE_PERCENT}"
        [[ -n "${G1_NEW_SIZE_PERCENT:-}" ]] && append_java_opt "-XX:G1NewSizePercent=${G1_NEW_SIZE_PERCENT}"
        [[ -n "${G1_MAX_NEW_SIZE_PERCENT:-}" ]] && append_java_opt "-XX:G1MaxNewSizePercent=${G1_MAX_NEW_SIZE_PERCENT}"
        [[ -n "${G1_MIXED_GC_COUNT_TARGET:-}" ]] && append_java_opt "-XX:G1MixedGCCountTarget=${G1_MIXED_GC_COUNT_TARGET}"
        [[ -n "${G1_MIXED_GC_LIVE_THRESHOLD_PERCENT:-}" ]] && append_java_opt "-XX:G1MixedGCLiveThresholdPercent=${G1_MIXED_GC_LIVE_THRESHOLD_PERCENT}"
        ;;
    CMS)
        if [[ "${JAVA_MAJOR_VERSION}" -gt 8 ]]; then
            fail "CMS mode is only supported by this image when running Java 8."
        fi

        echo "GC mode is CMS"
        append_java_opt "-XX:+UseConcMarkSweepGC"
        append_java_opt "-Xmn${XMN:-512m}"
        append_java_opt "-XX:ParallelGCThreads=${PARALLEL_GC_THREADS:-2}"
        append_java_opt "-XX:ConcGCThreads=${CONC_GC_THREADS:-1}"
        append_java_opt "-XX:+UseCMSInitiatingOccupancyOnly"
        append_java_opt "-XX:CMSInitiatingOccupancyFraction=${CMS_INITIATING_HEAP_OCCUPANCY_PERCENT:-92}"
        append_java_opt "-XX:+CMSClassUnloadingEnabled"
        append_java_opt "-XX:+CMSScavengeBeforeRemark"
        append_java_opt "-XX:+ExplicitGCInvokesConcurrent"
        append_java_opt "-XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses"

        if [[ "${CMS_INCREMENTAL_MODE:-N}" == "Y" ]]; then
            append_java_opt "-XX:+CMSIncrementalMode"
            append_java_opt "-XX:CMSFullGCsBeforeCompaction=${CMS_FULL_GCS_BEFORE_COMPACTION:-5}"
        fi
        ;;
    ZGC|ShenandoahGC)
        fail "GC_MODE=${GC_MODE} is not supported by the Java 8 base image. Use G1 or CMS."
        ;;
    *)
        fail "Unsupported GC_MODE='${GC_MODE}'. Use G1 or CMS."
        ;;
esac

mkdir -p -- "${HOME}/applogs"

if [[ "${USE_GC_LOG:-Y}" == "Y" ]]; then
    validate_positive_integer GC_LOG_FILE_COUNT "${GC_LOG_FILE_COUNT:-5}"
    validate_size GC_LOG_FILE_SIZE "${GC_LOG_FILE_SIZE:-50M}"

    if [[ "${JAVA_MAJOR_VERSION}" -gt 8 ]]; then
        echo "GC logs will be written to '${HOME}/applogs/jvm_gc-%p-%t.log'."
        append_java_opt "-Xlog:gc:file=${HOME}/applogs/jvm_gc-%p-%t.log:time,uptime,level,tags:filecount=${GC_LOG_FILE_COUNT:-5},filesize=${GC_LOG_FILE_SIZE:-50M}"
    else
        echo "GC logs will be written to '${HOME}/applogs/jvm_gc.log'."
        append_java_opt "-Xloggc:${HOME}/applogs/jvm_gc.log"
        append_java_opt "-XX:+PrintGCDetails"
        append_java_opt "-XX:+PrintGCDateStamps"
        append_java_opt "-XX:+UseGCLogFileRotation"
        append_java_opt "-XX:NumberOfGCLogFiles=${GC_LOG_FILE_COUNT:-5}"
        append_java_opt "-XX:GCLogFileSize=${GC_LOG_FILE_SIZE:-50M}"
    fi
fi

if [[ "${USE_HEAP_DUMP:-Y}" == "Y" ]]; then
    echo "Heap dumps will be written to '${HOME}/applogs/jvm_heap_dump.hprof'."
    append_java_opt "-XX:HeapDumpPath=${HOME}/applogs/jvm_heap_dump.hprof"
    append_java_opt "-XX:+HeapDumpOnOutOfMemoryError"
fi

if [[ "${USE_LARGE_PAGES:-N}" == "Y" ]]; then
    echo "Large pages are enabled."
    append_java_opt "-XX:+UseLargePages"
fi

if [[ "${JDWP_DEBUG:-N}" == "Y" ]]; then
    validate_positive_integer JDWP_PORT "${JDWP_PORT:-5005}"
    ((JDWP_PORT >= 1 && JDWP_PORT <= 65535)) || fail "JDWP_PORT must be between 1 and 65535."
    echo "Remote JVM debugging is enabled on port ${JDWP_PORT:-5005}."
    append_java_opt "-Xdebug"
    append_java_opt "-Xrunjdwp:transport=dt_socket,address=${JDWP_PORT:-5005},server=y,suspend=n"
fi

export JAVA_OPTS
