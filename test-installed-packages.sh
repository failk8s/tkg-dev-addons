#!/bin/bash

MODULE="src/packages/dev-platform/1.0.0/bundle/config"

[ ! -d "$MODULE" ] && echo "There's no module with that name" && exit 1

ytt -f $MODULE --ignore-unknown-comments