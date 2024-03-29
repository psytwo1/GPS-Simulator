#!/bin/bash

_usage() {
    echo "Usage: $(basename "$0") [OPTIONS] GPX_FILE" 1>&2
    echo "  -u | --udid UDID    Target specific device by its device UDID."
    echo "  -v | --verbose      View simulation verbose"
    echo "  --dry-run           Don't actually simulate location, just show they."
    echo "  -h | --help         Show this message and exit"
}

DRY_RUN="eval"
VERVOSE=false

ARGS=("$@")
LAST_ARG=""
if [ ${#ARGS} -gt 0 ]; then
    LAST_ARG="${ARGS[$((${#ARGS[@]} - 1))]}"
fi

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        _usage
        exit 0
        ;;
    --dry-run)
        DRY_RUN="echo"
        shift
        ;;
    -u | --udid)
        UDID=$2
        shift
        shift
        ;;
    -v | --verbose)
        VERVOSE=true
        shift
        ;;
    --)
        shift
        POSITIONAL_ARGS+=("$@")
        set --
        ;;
    -*)
        echo "[ERROR] Unknown option $1"
        exit 1
        ;;
    *)
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}" #// set $1, $2, ...
unset POSITIONAL_ARGS

if [[ "$1" != "$LAST_ARG" ]]; then
    _usage
    exit 1
fi

if [[ "$1" == "" ]]; then
    _usage
    exit 1
fi

DATE_CMD="date"
if ! $DATE_CMD -d "01/01/01" &>/dev/null; then
    DATE_CMD="gdate"
fi

GPX=$1

POINTS=$(xmlstarlet sel -N g="http://www.topografix.com/GPX/1/1" -t -v "count(/g:gpx/g:trk/g:trkseg/g:trkpt)" -n "$GPX")

for i in $(seq "$POINTS"); do
    LAT=$(xmlstarlet sel -N g="http://www.topografix.com/GPX/1/1" -t -v "/g:gpx/g:trk/g:trkseg/g:trkpt[${i}]/@lat" -n "$GPX")
    LON=$(xmlstarlet sel -N g="http://www.topografix.com/GPX/1/1" -t -v "/g:gpx/g:trk/g:trkseg/g:trkpt[${i}]/@lon" -n "$GPX")
    TIME=$(xmlstarlet sel -N g="http://www.topografix.com/GPX/1/1" -t -v "/g:gpx/g:trk/g:trkseg/g:trkpt[${i}]/g:time" -n "$GPX")

    CMD="$DRY_RUN idevicelocation"
    if [ "$UDID" != "" ]; then
        CMD="$CMD -u $UDID"
    fi
    CMD="$CMD $LAT $LON"
    if ! $CMD; then
        exit 1
    fi

    if [ $VERVOSE ]; then
        echo "Simulating GPS: $LAT, $LON"
    fi

    if [ "$i" -lt "$POINTS" ]; then
        TIME_NEXT=$(xmlstarlet sel -N g="http://www.topografix.com/GPX/1/1" -t -v "/g:gpx/g:trk/g:trkseg/g:trkpt[$((i + 1))]/g:time" -n "$GPX")
        WAIT="$(($($DATE_CMD -d "$TIME_NEXT" +%s) - $($DATE_CMD -d "$TIME" +%s)))"
        CMD="$DRY_RUN sleep $WAIT"
        if ! $CMD; then
            exit 1
        fi
    fi
done

CMD="$DRY_RUN idevicelocation -s"
if ! $CMD; then
    exit 1
fi
