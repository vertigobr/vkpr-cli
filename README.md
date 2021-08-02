# VKPR CLI tool

This repo holds the CLI to manage a VKPR cluster. This CLI is based on Ritchie formulas.

## Why Ritchie?

Using Ritchie we could create our own CLI following the pattern `vkpr + object + verb + name` and implement it with plain shell scripts.

![Rit banner](/docs/img/ritchie-banner.png)

For more information (if you are curious about it), please check the [Ritchie CLI documentation](https://docs.ritchiecli.io)

## Installing

The VKPR CLI tool will do its best to hide its internals (including Ritchie).

TODO: VKPR CLI install script. Currently wo do it manually:

```sh
# todo
# download rit
# rit add repo --provider="Github" --name="vkprxxx" --repoUrl="xx" # (url do vkpr-cli no github)
# create alias vkpr=rit vkpr
```

## Documentation

# download dependencies (tools/other CLIs)
vkpr init
# runs a local k8s cluster (using k3d)
vkpr infra up
# global settings
vkpr global set domain --name=vtgdev.net
# install ingress controller (using helm chart)
vkpr ingress install

# instala keycloak (via helm chart)
vkpr keycloak install
# instala cert-manager (via helm chart)
vkpr cert-manager install







