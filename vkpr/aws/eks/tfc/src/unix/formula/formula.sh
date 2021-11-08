#!/bin/bash

runFormula() {
  createOrganizationInTFCloud
  # create api-token organization
  local TERRAFORM_ORGANIZATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $API_TERRAFORM_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/vkpr/authentication-token | $VKPR_JQ -r '.data.attributes.token')
  rit vkpr aws eks init --terraform_state="Terraform Cloud" --tf_cloud_token="$TERRAFORM_ORGANIZATION_TOKEN" --default
  updateRepoFiles
}

createOrganizationInTFCloud() {
  # create organization
  curl -s -X POST \
  -H "Authorization: Bearer $API_TERRAFORM_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
        "data": {
          "type": "organizations",
          "attributes": {
            "name": "vkpr",
            "email": "'$API_TERRAFORM_EMAIL'"
          }
        }
      }' https://app.terraform.io/api/v2/organizations | echoColor "green" "Created Organization in TF Cloud named VKPR"
  # create workspace
  curl -s -X POST \
  -H "Authorization: Bearer $API_TERRAFORM_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
        "data": {
          "attributes": {
            "name": "aws-eks",
            "resource-count": 0,
            "updated-at": "2017-11-29T19:18:09.976Z"
          },
          "type": "workspaces"
        }
      }' https://app.terraform.io/api/v2/organizations/vkpr/workspaces | echoColor "green" "Created workspace in TF Cloud in VKPR Organization named aws-eks"
}

updateRepoFiles() {
  local GITLAB_USERNAME=$(cat ~/.rit/credentials/default/gitlab | jq -r '.credential.username')
  git clone -b eks-sample https://gitlab.com/$GITLAB_USERNAME/aws-eks.git && cd aws-eks
  sed -i.tmp 's/gitlab.com/app.terraform.io/g' .gitlab-ci.yml
  sed -i.tmp 's/CI_JOB_TOKEN/TF_CLOUD_TOKEN/g' .gitlab-ci.yml
  rm .gitlab-ci.yml.tmp
  cat > backend.tf <<EOF
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "vkpr"

    workspaces {
      name = "aws-eks"
    }
  }
}
EOF
  git add .
  git commit -m "[skip ci] Att repository to use Terraform Cloud"
  git push
  cd .. && rm -rf aws-eks
}