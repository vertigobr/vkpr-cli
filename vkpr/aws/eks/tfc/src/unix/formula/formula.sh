#!/bin/bash

runFormula() {
  rit vkpr aws eks init --terraform_state="Terraform Cloud" --tf_cloud_token="$API_TERRAFORM_TOKEN" --default
  createOrganizationInTFCloud
  updateRepoFiles
}

createOrganizationInTFCloud() {
  # create organization vkpr
  local TF_CLOUD_RESPONSE_ORGANIZATION=$(curl -si -X POST \
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
      }' https://app.terraform.io/api/v2/organizations | head -n 1 | awk -F' ' '{print $2}')
  if [[ $TF_CLOUD_RESPONSE_ORGANIZATION = 401 ]]; then
    echoColor "red" "Unauthorized: Token or email invalid"
    exit
  fi
  [[ $TF_CLOUD_RESPONSE_ORGANIZATION = 422 ]] && echoColor "yellow" "Organization already created" || echoColor "green" "Created Organization in TF Cloud named VKPR"

  # create workspace aws-eks
  local TF_CLOUD_RESPONSE_WORKSPACE=$(curl -si -X POST \
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
      }' https://app.terraform.io/api/v2/organizations/vkpr/workspaces | head -n 1 | awk -F' ' '{print $2}')
  [[ $TF_CLOUD_RESPONSE_WORKSPACE = 422 ]] && echoColor "yellow" "Workspace already created" || echoColor "green" "Created workspace in TF Cloud in VKPR Organization named aws-eks"

  # create api-token organization vkpr
  local TERRAFORM_ORGANIZATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $API_TERRAFORM_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
    https://app.terraform.io/api/v2/organizations/vkpr/authentication-token | $VKPR_JQ -r '.data.attributes.token')
  
  # get workspace id from aws-eks
  local TF_CLOUD_WORKSPACE_ID=$(curl -s \
  -H "Authorization: Bearer $TERRAFORM_ORGANIZATION_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
    https://app.terraform.io/api/v2/organizations/vkpr/workspaces | $VKPR_JQ -r '.data[0].id')

  # create access key variable in aws-eks workspace
  local AWS_ACCESS_KEY=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r '.credential.accesskeyid')
  local TF_CLOUD_RESPONSE_VARIABLE_ACCESS_KEY=$(curl -si -X POST \
  -H "Authorization: Bearer $TERRAFORM_ORGANIZATION_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
        "data": {
          "type":"vars",
          "attributes": {
            "key":"aws_access_key",
            "value":"'$AWS_ACCESS_KEY'",
            "description":"Access Key from AWS",
            "category":"terraform",
            "hcl":false,
            "sensitive":true
          }
        }
      }' https://app.terraform.io/api/v2/workspaces/$TF_CLOUD_WORKSPACE_ID/vars | head -n 1 | awk -F' ' '{print $2}')
  [[ $TF_CLOUD_RESPONSE_WORKSPACE = 422 ]] && echoColor "yellow" "Variable already created" || echoColor "green" "Created Variable aws_access_key in aws-eks workspace"

  # create secret key variable in aws-eks workspace
  local AWS_SECRET_KEY=$(cat ~/.rit/credentials/default/aws | $VKPR_JQ -r '.credential.secretaccesskey')
  local TF_CLOUD_RESPONSE_VARIABLE_SECRET_KEY=$(curl -si -X POST \
  -H "Authorization: Bearer $TERRAFORM_ORGANIZATION_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
        "data": {
          "type":"vars",
          "attributes": {
            "key":"aws_secret_key",
            "value":"'$AWS_SECRET_KEY'",
            "description":"Secret Key from AWS",
            "category":"terraform",
            "hcl":false,
            "sensitive":true
          }
        }
      }' https://app.terraform.io/api/v2/workspaces/$TF_CLOUD_WORKSPACE_ID/vars | head -n 1 | awk -F' ' '{print $2}')
  [[ $TF_CLOUD_RESPONSE_WORKSPACE = 422 ]] && echoColor "yellow" "Variable already created" || echoColor "green" "Created Variable aws_secret_key in aws-eks workspace"

}

updateRepoFiles() {
  local GITLAB_USERNAME=$(cat ~/.rit/credentials/default/gitlab | jq -r '.credential.username')
  git clone -b eks-sample https://gitlab.com/$GITLAB_USERNAME/aws-eks.git && cd aws-eks
  sed -i.tmp 's/gitlab.com/app.terraform.io/g' .gitlab-ci.yml
  sed -i.tmp 's/CI_JOB_TOKEN/TF_CLOUD_TOKEN/g' .gitlab-ci.yml
  sed -i.tmp 's/GitLab-Backend/TerraformCloud-Backend/g' .gitlab-ci.yml
  rm .gitlab-ci.yml.tmp
  cat > backend.tf <<EOF
terraform {
  backend "remote" {
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