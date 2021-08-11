#!/bin/sh
printf \
"apiVersion: v1
kind: Secret
metadata:
  name: digitalocean-dns
data:
  access-token: " > $1