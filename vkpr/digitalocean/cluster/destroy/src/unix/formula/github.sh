#!/usr/bin/env bash

setproviderrun() {
  githubWorflowDestroy "${CLUSTER_NAME}" "$GITHUB_TOKEN"
}