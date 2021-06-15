# TKG Developer Package
Installs all the developer tools on top of TKG using Carvel packages

# Install latest kapp-controller

```
# If a TKG cluster (on the management cluster, pause kapp app autoupdate)
kubectl patch app/${GUEST_CLUSTER_NAME}-kapp-controller --patch '{"spec":{"paused":true}}' --type=merge

# On the workload cluster, delete old kapp-controller
kapp delete -a workload1-kapp-controller-ctrl -y

# On the workload cluster, update kapp-controller
kapp deploy -a kc -f https://raw.githubusercontent.com/vmware-tanzu/carvel-kapp-controller/develop/alpha-releases/0.20.0-rc.1.yml -y -n default
```

## Build the packages
Follow these steps:
1. Create the package in [src/packages](src/packages). You should add a package-name/version and then the bundle in it
2. Verify the overlays and tests
3. Update your [config.yaml](config.yaml) (although json file) with the new packages
4. Register the image in dev-platform [images.yml](src/packages/dev-platform/1.0.0/bundle/images.yml)
5. Add a PackageInstall and a Config descriptor to dev-platform [downstream](src/packages/dev-platform/1.0.0/bundle/downstream) directory. Verify the version of the package
6. Package up the bundle and push it to the registry `./update.sh update-all` or `./update.sh update -n <package-name> -v <package-version>`
7. Package up the package in the package repository `./update.sh package-manifests`

## Install on a cluster

To install the packagerepository on the cluster:
```
kubectl apply -f target/k8s/repository.yaml
```

Let's verify the Package we have:
```
kubectl get package
NAME                                        PACKAGE NAME                         VERSION   AGE
cert-manager.tkgdev.failk8s.com.1.1.0       cert-manager.tkgdev.failk8s.com      1.1.0     4m57s
cert-manager.tkgdev.failk8s.com.1.3.1       cert-manager.tkgdev.failk8s.com      1.3.1     4m57s
certs.tkgdev.failk8s.com.1.0.0              certs.tkgdev.failk8s.com             1.0.0     4m57s
contour.tkgdev.failk8s.com.1.10.0           contour.tkgdev.failk8s.com           1.10.0    4m57s
dev-platform.tkgdev.failk8s.com.1.0.0       dev-platform.tkgdev.failk8s.com      1.0.0     4m57s
dns.tkgdev.failk8s.com.1.0.0                dns.tkgdev.failk8s.com               1.0.0     4m56s
knative-serving.tkgdev.failk8s.com.0.21.0   knative-serving.tkgdev.failk8s.com   0.21.0    4m56s
registry.tkgdev.failk8s.com.1.0.0           registry.tkgdev.failk8s.com          1.0.0     4m56s
```

## Install the tkg-platform package
As the tkg-platform package is the only package we need to install, we need to:

### Create the dev-platform NS and RBAC

```
kubectl apply -f src/templates/dev-platform-ns-rbac.yaml
```

### Provide the configuration

Configure (or copy and modify) an override profile, and then create a secret from it:

```
kubectl create secret generic dev-platform-config -n dev-platform --from-file=values.yaml=./profiles/override-jomorales.yaml -o yaml --dry-run=client | kubectl apply -f -
```


### Install the package

Create an PackageInstall for `dev-platform` package with the new configuration:

```
cat <<EOF | kubectl apply -n dev-platform -f -
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageInstall
metadata:
  name: dev-platform
spec:
  serviceAccountName: dev-platform-sa
  packageRef:
    refName: dev-platform.tkgdev.failk8s.com
    versionSelection:
      constraints: "1.0.0"
      prereleases: {}
  values:
  - secretRef:
      name: dev-platform-config
EOF
```

If there's an issue, you can verify the problem with:
```
kubectl get packageinstall dev-platform -n dev-platform -o yaml
```


## Update a package

1. Update the version of the installed package in dv-platform package
