# VKPR CLI

![License](https://camo.githubusercontent.com/e688d55dab653a01baa76e718f3aa473a08b1d57c9b4fcb7d553012a76d807c5/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6c6963656e73652d417061636865253230322e302d626c7565)

This repo holds the CLI to manage a VKPR cluster. This CLI is based on Ritchie formulas.
VKPR-CLI is Tool build with Shell that has the objetive to make it easier for the Develops to Build and Deploy it's scripts in yours cluster.

VKPR-CLI also helps the local development by using k3d to fully provision a Kubernetes cluster instance for testing purposes.

- [VKPR-CLI](#vkpr-cli)
  - [Why Ritchie](#why-ritchie)
  - [Minimum Required](#minimum-required)
  - [Setup VKPR](#setup-vkpr)
  - [Usage](#usage)
    - [Initializate](#init)
    - [Create a cluster](#create-a-cluster)
    - [Deploy a sample app](deploy-a-sample-app)
    - [Uninstalling the objects](#uninstalling-the-objects)
  - [Tools](#apps)
  - [Documentation](#docs)
  - [License](#license)

## Why Ritchie?

Using Ritchie we could create our own CLI and implement it with plain shell scripts.

![Rit banner](/docs/img/ritchie-banner.png)

For more information (if you are curious about it), please check the [Ritchie CLI documentation](https://docs.ritchiecli.io)

## Minimum required

VKPR-CLI was made to run on Linux / MacOS. It's pre-requisites are:

- [Docker](https://docs.docker.com/get-docker/)
- [Git](https://git-scm.com/downloads)

## Setup VKPR

VKPR was built on top of Ritchie, but he abstracts most of his interaction with him. To install it, you must run the following command.

### Installing VKPR CLI
```sh
curl -fsSL https://get.vkpr.net/ | bash
echo 'alias vkpr="rit vkpr"' >> ~/.bashrc # If you use another Unix Shell, specify your specific source
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
You can peek into it using ```k9s```:

```
~/.vkpr/bin/k9s
```

You can now test your scripts and create your own environments with VKPR commands.

### Deploy a sample app

To test some application using VKPR, we will use whoami as an example.

For this, we will implement an ingress controller and the whoami itself:

```
vkpr ingress install
vkpr whoami install --default
```
Now you can test this sample application with a simple curl command:

```
curl whoami.localhost:8000
# OR 
curl -H "Host: whoami.localhost" localhost:8000
```

> WARNING: Use the second form if ```whoami.localhost``` does not resolve to ```127.0.0.1```

### Discard cluster

After all tests, if you want to destroy the created cluster, you may discard his with a single command:

```sh
vkpr infra down
```

### Uninstalling the objects

To be deleting all dependencies of the installed script, it is necessary to run the following command:

```sh
vkpr whoami remove
```

## Apps

| Tools                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| ingress                  | Install nginx-ingress-controller                              |
| whoami                   | Install whoami                                                |
| cert-manager             | Install cert-manager to manage your certificates              |
| external-dns             | Install external-dns                                          |
| loki                     | Install Loki for monitoring and tracing                       |
| keycloak                 | Install Keycloak to manage the identity and access management |
| consul                   | Install consul to service identities and traditional networking practices to securely connect applications|
| kong                     | Install kong to manage, configure, and route requests to your APIs.|
| postgres                 | Install postgres to manage the Database                       |
| prometheus-stack         | Installs the kube-prometheus stack, a collection of Kubernetes manifests |
| vault                    | Install vault to manage secrets & protect sensitive data      |
| argocd                   | Install argocd to automated the application deployment and lifecycle management|
| aws eks                  | Install aws to fork and setup the GitOps Repo in your Gitlab  |

## Docs

The Documentation can be viewed in the following [link](https://docs.vkpr.net/).

## License

VKPR-CLI is licensed under the Apache License Version 2.0.
