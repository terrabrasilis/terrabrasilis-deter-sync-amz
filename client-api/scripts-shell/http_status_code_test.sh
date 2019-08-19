#!/bin/bash

usage() {
  cat <<EOL
USAGE: $(basename $0) [OPTIONS...] url

OPTIONS:
  -h, --help
  --status
  --debug
  --
EOL
    exit 1
}

assert_same() {
    if [ "$1" = "$2" ]; then
        return 0;
    fi

    return 1
}

fetch() {
    curl_out=`curl -s -w "%{http_code}" -o /dev/null $url $args`
    http_code=`echo "$curl_out" | cut -f1`

    return 0
}

main() {
    status=""
    debug=false
    args=""
    local argc=0
    local argv=()

    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                usage
                ;;
            --status)
                status=$2
                shift
                ;;
            --debug)
                debug=true
                ;;
            --)
                shift
                args=$*
                ;;
            *)
                argc=`expr $argc + 1`
                argv+=($1)
                ;;
        esac
  
        shift
    done

    if [ $argc -lt 1 ]; then
        echo "Too few arguments"
        exit 1
    fi

    url=${argv[0]}

    fetch

    if $debug; then
        echo "---> $url"
        echo "Expected: status = $status"
        echo "Actual: status = $http_code"
    fi

    assert_same $status $http_code && exit 0

    exit 1
}

main $*