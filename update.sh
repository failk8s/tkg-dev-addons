#!/usr/bin/env bash

# Redirect stdout and stderr to null --> &>/dev/null
# Redirect stdout or stderr to null --> 2>/dev/null


# For every package, we need to:
# Lock images
# Push bundle to repo

# We define 2 things:
# 1. Packages to create
# 2. tkg-dev-install experience

OVERRIDE_NAME=""
OVERRIDE_VERSION=""

_path=$(cat config.json | jq -r '.path')
_registry=$(cat config.json | jq -r '.registry')
_list_packages=$(cat config.json | jq -r '.packages[] | "\(.name)/\(.version)#\(.name)#\(.version)"')

function update_all {
    for package in $_list_packages
    do
        update_one $(echo $package | tr "#" " ")
    done
}


function update_one {
    local _package=$1
    local _name=$2
    local _version=$3
    if [ -d "$_path/$_package/bundle" ]; then
        echo "Updating package: $_package"
        pushd $_path/$_package/bundle &>/dev/null
        vendir sync
        kbld -f . --imgpkg-lock-output .imgpkg/images.yml
    echo "    imgpkg push --bundle $_registry/$_name-package:$_version --file ."
        popd &>/dev/null
    else
        echo "Directory ($_path/$_package/bundle) for package ($package) does not exist"
    fi
}


function update_repo {
    # TODO: Fix this and add config to json
    cd packages
    imgpkg push -i quay.io/failk8s/tkgdev-repo:latest -f packages
    cd -    
}

function parse_args {
  while [[ $# -gt 0 ]]
  do
    local key="$1"
    case $key in
      -n|--name)
        OVERRIDE_NAME="$2"
        shift # past argument
        shift # past value
        ;;
      -v|--version)
        OVERRIDE_VERSION="$2"
        shift # past argument
        shift # past value
        ;;
      *)
        echo "Wrong argument $key. Not supported"
        exit 1
        ;;
    esac
  done
}

if [[ $# -gt 0 ]]
then
  key="$1"
  case $key in
    update-all)
      shift # past argument
      update_all "$@"
      ;;
    update)
      shift # past argument
      parse_args $*
      update_one "$OVERRIDE_NAME/$OVERRIDE_VERSION" "$OVERRIDE_NAME" "$OVERRIDE_VERSION"
      ;;
    *)
      echo "You need to update-all or update -n PACKAGE_NAME -v PACKAGE_VERSION "
      ;;
  esac
else
  echo "You need to update-all or update -n PACKAGE_NAME -v PACKAGE_VERSION "
fi
