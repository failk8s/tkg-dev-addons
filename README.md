# TKG Developer Package
Installs all the developer tools on top of TKG using Carvel packages

## Build the packages
Follow these steps:
1. Create the package in [src/packages](src/packages). You should add a package-name/version and then the bundle in it
2. Update your [config.yaml](config.yaml) (although json file) with the new packages
3. Package up the bundle and push it to the registry `./update.sh update-all` or `./update.sh update -n <package-name> -v <package-version>`
4. Package up the package in the package repository `./update.sh package-manifests`

## Install on a cluster
TODO