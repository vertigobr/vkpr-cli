#!/bin/sh

runFormula() {
  $VKPR_GLAB auth login -h "gitlab.com" -t "$GITLAB_TOKEN"
  $VKPR_GLAB repo fork vkpr/aws-eks
  $VKPR_GLAB variable set "AWS_ACCESS_KEY" -m -v "$AWS_ACCESS_KEY" -R $GITLAB_USERNAME/aws-eks 
  $VKPR_GLAB variable set "AWS_SECRET_KEY" -m -v "$AWS_SECRET_KEY" -R $GITLAB_USERNAME/aws-eks 
  $VKPR_GLAB variable set "AWS_REGION" -m -v "$AWS_REGION" -R $GITLAB_USERNAME/aws-eks
  $VKPR_GLAB ci run -R $GITLAB_USERNAME/aws-eks
}
