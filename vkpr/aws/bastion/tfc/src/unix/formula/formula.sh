#!/usr/bin/env bash

runFormula() {
  local TF_CLOUD_RESPONSE_ORGANIZATION TF_CLOUD_RESPONSE_WORKSPACE TERRAFORM_ORGANIZATION_TOKEN TF_CLOUD_WORKSPACE_ID;
  setCredentials
  validateInputs

  [[ -f "$CURRENT_PWD"/vkpr.yaml ]] && cp "$CURRENT_PWD"/vkpr.yaml "$(dirname "$0")"
  rit vkpr aws eks init --terraform_state="Terraform Cloud" --terraformcloud_api_token="$TERRAFORMCLOUD_API_TOKEN" --default

  createOrganizationInTFCloud
  generateTokens
  setVariablesTFC "aws_access_key" "Access Key from AWS" "$AWS_ACCESS_KEY"
  setVariablesTFC "aws_secret_key" "Secret Key from AWS" "$AWS_SECRET_KEY"
  updateRepoFiles
}

setCredentials() {
  GITLAB_USERNAME=$($VKPR_JQ -r '.credential.username' "$VKPR_CREDENTIAL"/gitlab)
  AWS_SECRET_KEY=$($VKPR_JQ -r '.credential.secretaccesskey' "$VKPR_CREDENTIAL"/aws)
  AWS_ACCESS_KEY=$($VKPR_JQ -r '.credential.accesskeyid' "$VKPR_CREDENTIAL"/aws)
}

validateInputs() {
  validateAwsSecretKey "$AWS_SECRET_KEY"
  validateAwsAccessKey "$AWS_ACCESS_KEY"
  validateGitlabUsername "$GITLAB_USERNAME"
}

createOrganizationInTFCloud() {
  # create organization vkpr
  TF_CLOUD_RESPONSE_ORGANIZATION=$(curl -si -X POST \
  -H "Authorization: Bearer ${TERRAFORMCLOUD_API_TOKEN}" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
        "data": {
          "type": "organizations",
          "attributes": {
            "name": "vkpr",
            "email": "'"$TERRAFORMCLOUD_EMAIL"'"
          }
        }
      }' https://app.terraform.io/api/v2/organizations | head -n 1 | awk -F' ' '{print $2}')

  case $TF_CLOUD_RESPONSE_ORGANIZATION in
    201)
      info "Created Organization in TF Cloud named VKPR"
      ;;
    401)
      error "Unauthorized: Token or email invalid"
      ;;
    422)
      warn "Organization already created"
      ;;
    *)
      error "Something wrong"
      ;;
  esac

  TF_CLOUD_RESPONSE_WORKSPACE=$(curl -si -X POST \
  -H "Authorization: Bearer ${TERRAFORMCLOUD_API_TOKEN}" \
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

  if [[ "$TF_CLOUD_RESPONSE_WORKSPACE" == "422" ]]; then
    warn "Workspace already created"
    else
    info "Created workspace in TF Cloud in VKPR Organization named aws-eks"
  fi
}

generateTokens() {
  TERRAFORM_ORGANIZATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer ${TERRAFORMCLOUD_API_TOKEN}" \
  -H "Content-Type: application/vnd.api+json" \
    https://app.terraform.io/api/v2/organizations/vkpr/authentication-token | $VKPR_JQ -r '.data.attributes.token')

  TF_CLOUD_WORKSPACE_ID=$(curl -s \
  -H "Authorization: Bearer ${TERRAFORM_ORGANIZATION_TOKEN}" \
  -H "Content-Type: application/vnd.api+json" \
    https://app.terraform.io/api/v2/organizations/vkpr/workspaces | $VKPR_JQ -r '.data[0].id')
}

setVariablesTFC() {
  RESPONSE=$(curl -si -X POST \
  -H "Authorization: Bearer ${TERRAFORM_ORGANIZATION_TOKEN}" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{
        "data": {
          "type":"vars",
          "attributes": {
            "key":"$1",
            "value":"'"$3"'",
            "description":"$2",
            "category":"terraform",
            "hcl":false,
            "sensitive":true
          }
        }
      }' https://app.terraform.io/api/v2/workspaces/"$TF_CLOUD_WORKSPACE_ID"/vars | head -n 1 | awk -F' ' '{print $2}')

  if [[ "$RESPONSE" == "422" ]]; then
    warn "Variable already created"
    else
    info "Created Variable $1 in aws-eks workspace"
  fi
}

updateRepoFiles() {
  git clone -b eks-sample https://gitlab.com/"$GITLAB_USERNAME"/aws-eks.git && cd aws-eks || return
  sed -i.tmp 's/gitlab.com/app.terraform.io/g ; s/CI_JOB_TOKEN/TF_CLOUD_TOKEN/g ; s/GitLab-Backend/TerraformCloud-Backend/g' .gitlab-ci.yml
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
