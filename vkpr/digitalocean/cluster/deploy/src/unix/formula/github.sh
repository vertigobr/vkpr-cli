#!/usr/bin/env bash

setproviderrun() {
  githubWorflowDeploy "${CLUSTER_NAME}" "$GITHUB_TOKEN"
}