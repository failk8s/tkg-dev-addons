#!/usr/local/bin/bash
#
# Note: This script requires bash 4+
#

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -uo pipefail



function scaffold {
    local arg="${1:-}"
    if [[ "x${arg}" != "x" ]]; then
        # Check if it exists
        if [[ ! -d addons/${arg} ]]; then
            mkdir -p addons/${arg}/bundle
            touch addons/${arg}/bundle/addon.yml
            mkdir -p addons/${arg}/bundle/.imgpkg
            touch addons/${arg}/bundle/.imgpkg/images.yml
            touch addons/${arg}/bundle/.imgpkg/bundle.yml
            mkdir -p addons/${arg}/bundle/config
            mkdir -p addons/${arg}/bundle/config/upstream
            touch addons/${arg}/bundle/config/upstream/.gitkeep
            mkdir -p addons/${arg}/bundle/config/downstream
            touch addons/${arg}/bundle/config/downstream/.gitkeep
            mkdir -p addons/${arg}/bundle/config/overlays
            touch addons/${arg}/bundle/config/overlays/.gitkeep
        else
            echo "Addon is already scaffolded"
        fi
    else
        echo "You should specify which package to scaffold"
    fi
}

function vendir {
    local arg="${1:-}"
    if [[ "x${arg}" == "x" ]]; then
        vendir sync
    else
        vendir sync -d addons/${arg}/bundle/config
    fi
}

function kbld {
    local arg="${1:-}"
    if [[ "x${arg}" != "x" ]]; then
        echo "kbld --file addons/${arg}/bundle/config --imgpkg-lock-output addons/${arg}/bundle/.imgpkg/images.yml"
    else
        echo "You should specify which package to kbld"
    fi
}

if [[ $# -gt 0 ]]
then
    key="$1"
    case $key in
        scaffold)
            shift # past argument
            scaffold "$@"
        ;;
        kbld)
            shift # past argument
            kbld "$@"
        ;;
        vendir)
            shift # past argument
            vendir "$@"
        ;;
    esac
else
    echo "Error in options"
fi