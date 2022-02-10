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
    - [Provisioning](#provisioning)
    - [Uninstalling the objects](#uninstalling-the-objects)
  - [Deploying a web service](#deploying-a-web-service)
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

### info!

Optionally you can use VKPR internal tools by changing PATH:


```
export PATH=$PATH:~/.vkpr/bin
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

### WARN!

Use the second form if ```whoami.localhost``` does not resolve to ```127.0.0.1```

### Discard cluster

After all tests, if you want to destroy the created cluster, you may discard his with a single command:

```
vkpr infra down
```

## Provisioning

## Deploying a web service

Let's assume that we already have a working Kubernetes cluster in AWS and we need to be uploading such applications:
* nginx-ingress: A LoadBalancer to expose the application outside the cluster.
* whoami: A simple web server.
* external-DNS: Will be responsible for replicating the address in the internet used by the application.
* cert-manager: You will be responsible for generating the certificates used to use the application in HTTPS.

With Kubeconfig already associated with your context, you will run the following command:

## Installing nginx-ingress
```
➜ vkpr ingress install
Formula was successfully built!

? Which type of LoadBalancer do you prefer ?  [Use arrows to move, type to filter, ? for more help]
> Classic
  NLB

==============================
VKPR Ingress Install Routine
==============================
....
```

## Installing whoami

```
➜ vkpr whoami install
Formula was successfully built!

? Type the Whoami domain: [? for help] (localhost) test.vkpr.net

? Secure ?  [Use arrows to move, type to filter, ? for more help]
> true
  false

==============================
VKPR Whoami Install Routine
Whoami Domain: whoami.test.vkpr.net
Ingress Controller: nginx
==============================
....
```

## Installing external-dns

```
➜ vkpr external-dns install
Formula was successfully built!

? Type your provider:  [Use arrows to move, type to filter, ? for more help]
> aws
  digitalocean
  powerDNS

? Provider key not found, please provide a value for aws accesskeyid:
? Provider key not found, please provide a value for aws secretaccesskey:
? Provider key not found, please provide a value for aws region:

==============================
VKPR External-DNS Install Routine
Provider: aws
==============================
....
```

## Installing cert-manager

```
➜ vkpr cert-manager install
Formula was successfully built!

? Type your email to use to generate certificates:  [Use arrows to move, type to filter, ? for more help]
> default@vkpr.com
  Type other email

? What is the default cluster issuer ?  [Use arrows to move, type to filter, ? for more help]
  staging
> production
  custom-acme

? What solver do you want to use ?  [Use arrows to move, type to filter, ? for more help]
  HTTP01
> DNS01

? What cloud dns provider do you will use ?  [Use arrows to move, type to filter, ? for more help]
> aws
  digitalocean
  custom-acme

? Type your Hostedzone id from Route53: [? for more help]

==============================
VKPR Cert-manager Install Routine
Provider: aws
Issuer Solver: DNS01
Email: default@vkpr.com
==============================
....
```

### Uninstalling the objects

To be deleting all dependencies of the installed script, it is necessary to run the following command:

```sh
vkpr whoami remove
```

## Docs

The Documentation can be viewed in the following [link](https://github.com/vertigobr/vkpr-cli).

## License

VKPR-CLI is licensed under the Apache License Version 2.0.
