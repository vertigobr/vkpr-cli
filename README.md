# VKPR CLI tool

This repo holds the CLI to manage a VKPR cluster. This CLI is based on Ritchie formulas.

## Why Ritchie?

Using Ritchie we could create our own CLI following the pattern `vkpr + object + verb + name` and implement it with plain shell scripts.

![Rit banner](/docs/img/ritchie-banner.png)

For more information (if you are curious about it), please check the [Ritchie CLI documentation](https://docs.ritchiecli.io)

## Installing

The VKPR CLI tool will do its best to hide its internals (including Ritchie).

TODO: VKPR CLI install script. Currently we do it manually:

```sh
# Install the Rit
curl -fsSL https://commons-repo.ritchiecli.io/install.sh | bash
# Download VKPR Repo
rit add repo --provider="Github" --name="vkpr-cli" --repoUrl=<Github URL Project>
# Create alias
alias vkpr="rit vkpr"
```

## Tools

| Tools                    | Description |
| ------------------------ | ----------- |
| nginx-ingress-controller |             |
| Whoami                   |             |
| cert-manager             |             |
| external-dns             |             |
| loki                     |             |
| keycloak                 |             |

## Documentation

|     Objects + Verb     | Description                               |
| :--------------------: | ----------------------------------------- |
|         `init`         | Download dependencies                     |
|       `infra up`       | Install a local K8S cluster (Using K3D)   |
|      `infra down`      | Uninstall a local K8S cluster (Using K3D) |
|   `ingress install`    | Install the Ingress Controller            |
|    `ingress remove`    | Uninstall the Ingress Controller          |
|    `whoami install`    | Install the Whoami App                    |
|    `whoami remove`     | Uninstall the Whoami App                  |
| `cert-manager install` | Install the cert-manager App              |
| `cert-manager remove`  | Uninstall the cert-manager App            |
| `external-dns install` | Install the external-dns App              |
| `external-dns remove`  | Uninstall the external-dns App            |
|     `loki install`     | Install the loki App                      |
|     `loki remove`      | Uninstall the loki App                    |
|   `keycloak install`   | Install the keycloak App                  |
|   `keycloak remove`    | Uninstall the keycloak App                |

# global settings

vkpr global template
vkpr global set domain --name=vtgdev.net
