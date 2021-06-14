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
CONFIG_FILE=${CONFIG_FILE:-"config.yaml"}

_src_packages_path=$(cat $CONFIG_FILE | jq -r '.paths.sources.packages')
_src_repo_path=$(cat $CONFIG_FILE | jq -r '.paths.sources.repository')
_src_templates_path=$(cat $CONFIG_FILE | jq -r '.paths.sources.templates')
_target_packages_path=$(cat $CONFIG_FILE | jq -r '.paths.target.packages')
_target_repo_path=$(cat $CONFIG_FILE | jq -r '.paths.target.repository')
_target_k8s_path=$(cat $CONFIG_FILE | jq -r '.paths.target.k8s')
_registry=$(cat $CONFIG_FILE | jq -r '.registry')
_repo_name=$(cat $CONFIG_FILE | jq -r '.repository.name')
_repo_version=$(cat $CONFIG_FILE | jq -r '.repository.version')
_list_packages=$(cat $CONFIG_FILE | jq -r '.packages[] | .versions[] as $item | "\(.name)/\($item)#\(.name)#\($item)"')

TMPFILE=""
VALUEFILE=""
temp=$(basename $0)

function create_temp_valuesfile {
  TMPDIR=$(mktemp -d)
  TMPFILE="$TMPDIR"/values.yaml
  touch $TMPFILE
  echo "#@data/values" >> $TMPFILE
  echo "---" >>  $TMPFILE
  cat $CONFIG_FILE >> $TMPFILE
  echo $TMPFILE
}
function delete_temp_valuesfile {
  rm -rf $TMPDIR
}

function create_package_valuesfile {
  TMPDIR=$(mktemp -d)
  VALUEFILE="$TMPDIR"/data-value.yaml
  touch $VALUEFILE
  echo "#@data/values" >> $VALUEFILE
  echo "---" >>  $VALUEFILE
  echo "#@overlay/replace" >> $VALUEFILE
  echo "packages:" >>  $VALUEFILE
  echo "  - name: $1" >>  $VALUEFILE
  echo "    versions:" >>  $VALUEFILE
  echo "      - $2" >>  $VALUEFILE
  echo $VALUEFILE
}
function delete_package_valuesfile {
  rm -rf $TMPDIR
}

function update_all {
    for package in $_list_packages
    do
        update_one $(echo $package | tr "#" " ")
    done
}


function update_one {
    local _packageNV=$1
    local _name=$2
    local _version=$3
    if [ -d "$_src_packages_path/$_packageNV/bundle" ]; then
        echo "Updating package: $_packageNV"
        pushd $_src_packages_path/$_packageNV/bundle &>/dev/null
        # Only vendir if not vendir lock file
        if [ ! -e vendir.lock.yml ]; then
          vendir sync
        fi
        if [ ! -e .imgpkg/images.yml ]; then
          kbld -f . --imgpkg-lock-output .imgpkg/images.yml
        fi
        imgpkg push --bundle $_registry/$_name-package:$_version --file .
        popd &>/dev/null
    else
        echo "Directory ($_src_packages_path/$_packageNV/bundle) for package ($_packageNV) does not exist"
    fi
}


function package_all {
    for package in $_list_packages
    do
      echo "package_one $(echo $package | tr '#' ' ')"
        package_one $(echo $package | tr "#" " ")
    done
}

function package_one {
    local _packageNV=$1
    local _name=$2
    local _version=$3

    create_temp_valuesfile
    create_package_valuesfile $_name $_version
    # Create packages
    mkdir -p $_target_packages_path/packages/$_name
    ytt  -f $TMPFILE -f $VALUEFILE -f $_src_templates_path/package.yaml --output-files $_target_packages_path/packages/$_name --ignore-unknown-comments
    # Create package versions
    ytt  -f $TMPFILE -f $VALUEFILE -f $_src_templates_path/packageversion.yaml --output-files $_target_packages_path/packages/$_name --ignore-unknown-comments
    mv $_target_packages_path/packages/$_name/packageversion.yaml $_target_packages_path/packages/$_name/$_version.yaml
    # Lock images
    mkdir -p $_target_packages_path/.imgpkg
    kbld -f $_target_packages_path/packages --imgpkg-lock-output $_target_packages_path/.imgpkg/images.yml
    # Create repository
    imgpkg push -b $_registry/$_repo_name:$_repo_version --file $_target_packages_path
    mkdir -p $_target_k8s_path
    # kbld the repository 
    ytt -f $TMPFILE -f $_src_templates_path/repository.yaml --ignore-unknown-comments | kbld -f - > $_target_k8s_path/repository.yaml
    delete_temp_valuesfile
    delete_package_valuesfile
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
    package-all)
      shift # past argument
      package_all "$@"
      ;;
    package)
      shift # past argument
      parse_args $*
      package_one "$OVERRIDE_NAME/$OVERRIDE_VERSION" "$OVERRIDE_NAME" "$OVERRIDE_VERSION"
      ;;
    *)
      echo "You need to update-all or update -n PACKAGE_NAME -v PACKAGE_VERSION "
      ;;
  esac
else
  echo "You need to update-all or update -n PACKAGE_NAME -v PACKAGE_VERSION "
fi
