#! /bin/sh

URL="https://portal.ix42.org/api/v4/router/gen-config"
URL_DONE="https://portal.ix42.org/api/v4/router/updated"
ETCPATH="/etc/bird"
RUNPATH="/var/run"
LOGPATH="/var/log/bird"
BIN="/usr/sbin/bird"

handle=$IXHANDLE

# Parse arguments
export DEBUG=0

function show_help {
    echo "$0 [-d] -h <handle> [-?]"
}


while getopts "?qdh:" opt; do
    case "$opt" in
        \?)
            show_help
            exit 0
            ;;
        d)  export DEBUG=1
            ;;
        h)  handle=$OPTARG
            ;;
    esac
done

if [[ -z "$handle" ]]; then
    echo ERROR: handle is required
    exit 1
fi

mkdir -p $ETCPATH
mkdir -p $LOGPATH
mkdir -p $RUNPATH

cfile="${ETCPATH}/bird.conf"
dest="${cfile}.$$"
socket="${RUNPATH}/bird.ctl"

cmd="curl --fail -s -H \"X-IXP-Manager-API-Key: ${IXKEY}\" ${URL}/${handle} >${dest}"

if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
eval $cmd

# We want to be safe here so check the generated file to see whether it
# looks valid

if [[ $? -ne 0 ]]; then
    echo "ERROR: non-zero return from curl when generating $dest"
    exit 2
fi

if [[ ! -e $dest || ! -s $dest ]]; then
    echo "ERROR: $dest does not exist or is zero size"
    exit 3
fi

if [[ $( cat $dest | grep "protocol bgp pb_" | wc -l ) -lt 2 ]]; then
    echo "ERROR: fewer than 2 BGP protocol definitions in config file $dest - something has gone wrong..."
    exit 4
fi

# parse and check the config
cmd="${BIN} -p -c $dest"
if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
eval $cmd &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "ERROR: non-zero return from ${BIN} when parsing $dest"
    exit 7
fi

# config file should be okay; back up the current one
if [[ -e ${cfile} ]]; then
    cp "${cfile}" "${cfile}.old"
fi
mv $dest $cfile

# are we running or do we need to be started?
cmd="${BIN}c -s $socket show memory"
if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
eval $cmd &>/dev/null

if [[ $? -ne 0 ]]; then
    cmd="${BIN} -c ${cfile} -s $socket"

    if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
    eval $cmd &>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "ERROR: ${BIN} was not running for $dest and could not be started"
        exit 5
    fi
else
    cmd="${BIN}c -s $socket configure"
    if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
    eval $cmd &>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Reconfigure failed for $dest"

        if [[ -e ${cfile}.old ]]; then
            echo "Trying to revert to previous"
            mv ${cfile}.conf $dest
            mv ${cfile}.old ${cfile}
            cmd="${BIN}c -s $socket configure"
            if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
            eval $cmd &>/dev/null
            if [[ $? -eq 0 ]]; then
                echo Successfully reverted
            else
                echo Reversion failed
                exit 6
            fi
        fi
    fi

fi

# tell IXP Manager the router has been updated:
cmd="curl -s -X POST -H \"X-IXP-Manager-API-Key: ${IXKEY}\" ${URL_DONE}/${handle} >/dev/null"
if [[ $DEBUG -eq 1 ]]; then echo $cmd; fi
eval $cmd

if [[ $? -ne 0 ]]; then
    echo "Warning - could not inform IXP Manager via updated API"
fi

exit 0
