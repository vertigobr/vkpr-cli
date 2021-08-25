# VKPR CLI

![License](https://camo.githubusercontent.com/e688d55dab653a01baa76e718f3aa473a08b1d57c9b4fcb7d553012a76d807c5/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6c6963656e73652d417061636865253230322e302d626c7565)

This repo holds the CLI to manage a VKPR cluster. This CLI is based on Ritchie formulas.
VKPR-CLI is Tool build with Shell that has the objetive to make it easier for the Develops to Build and Deploy it's scripts in yours cluster.

VKPR-CLI also helps the local development by using k3d to fully provision a Kubernetes cluster instance for testing purposes.

- [VKPR-CLI](#vkpr-cli-tool)
  - [Why Ritchie](##Why-Ritchie?)
  - [Minimum Required](##Minimum-required)
  - [Get VKPR](##Get-VKPR)
  - [Usage](##Usage)
    - [Initializate](###Init)
    - [Create a cluster](###Create-a-cluster)
    - [Running the scripts](###Running-the-scripts)
    - [Uninstalling the objects](###Uninstalling-the-objects)
  - [Tools](##Apps)
  - [Documentation](##Docs)
  - [License](##License)

## Why Ritchie?

Using Ritchie we could create our own CLI and implement it with plain shell scripts.

![Rit banner](/docs/img/ritchie-banner.png)

For more information (if you are curious about it), please check the [Ritchie CLI documentation](https://docs.ritchiecli.io)

## Minimum required

VKPR-CLI was made to run on Linux / MacOS. It's pre-requisites are:

- [Docker](https://docs.docker.com/get-docker/)
- [Git](https://git-scm.com/downloads)

## Get VKPR

The VKPR CLI tool will do its best to hide its internals (including Ritchie).

```sh
# Install the VKPR
curl -fsSL https://get.vkpr.net/ | bash
# Create alias
alias vkpr="rit vkpr"
```

## Usage

Try yourself to use VKPR following the next steps:

### Init

In order to start using VKPR, the first instruction you will have to use is the init:

```sh
vkpr init
```

It will download and install all required tools to your local environment:

- kubectl
- helm
- k3d
- arkade
- jq
- yq

### Create a cluster

After initializing all VKPR dependencies, you may be creating the Kubernetes Cluster in your environment for testing as a production environment.

To do that, you can run the command:

```sh
vkpr infra up
```

You can now test your scripts and create your own environments with VKPR commands.

### Running the scripts

After you have started VKPR and connected to an environment with the Kubernetes cluster, you may be running the scripts.
Scripts follow a standard order of `vkpr + object + verb`.

To start a simple web application, you can run the command:

```sh
vkpr whoami install
```

In certain commands, there is a quiz on how you want the application to go up. It can be configured, for example, access domains, HTTPS communication and others. After that, this command will create the objects needed to use whoami.

If you don't want to have to be configuring the application, you may be using the `--default` flag to follow the default values

### Uninstalling the objects

To be deleting all dependencies of the installed script, it is necessary to run the following command:

```sh
vkpr whoami remove
```

## Apps

| Tools                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| nginx-ingress-controller | Install ingress-nginx                                         |
| whoami                   | Install whoami                                                |
| cert-manager             | Install cert-manager to manage your certificates              |
| external-dns             | Install external-dns                                          |
| loki                     | Install Loki for monitoring and tracing                       |
| keycloak                 | Install Keycloak to manage the identity and access management |

## Docs

The Documentation can be viewed in the following [link](https://github.com/vertigobr/vkpr-cli).

## License

VKPR-CLI is licensed under the Apache License Version 2.0.
