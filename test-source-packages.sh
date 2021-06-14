#!/bin/bash

[ "$1" == "" ] && echo "You need to provide a module name to test (e.g: certs/1.0.0 or cert-manager/1.3.1)" && exit 1

MODULE="src/packages/$1/bundle/config"

[ ! -d "$MODULE" ] && echo "There's no module with that name" && exit 1

if [ ! -z $2 ]; then
    ([ "$2" != "minikube" ] && [ "$2" != "tmc" ]) && echo "Flavour needs to be tmc or minikube" && exit 1
    ytt -f tests/override.test-$2.yaml -f $MODULE --ignore-unknown-comments
    echo ""
    echo "Tested $2 config"
    echo ""
else
    ytt -f tests/override.test-tmc.yaml -f $MODULE --ignore-unknown-comments
    echo ""
    echo "Tested tmc config"
    echo ""
    read  -n 1 -p "Press a key to continue with minikube"
    ytt -f tests/override.test-minikube.yaml -f $MODULE --ignore-unknown-comments
    echo ""
    echo "Tested minikube config"
    echo ""
fi