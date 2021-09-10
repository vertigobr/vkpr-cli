# Description

Create a Cluster EKS in AWS with [Gitops Terraform Module](https://gitlab.com/vkpr/terraform-aws-eks).

## Commands

Interactive inputs:

```bash
vkpr aws eks deploy
```

Non-interactive:

```bash
rit set credential --fields="token,username" --provider="gitlab" --values="<your-gitlab-token>,<your-gitlab-username>"
vkpr aws eks deploy
```

**Note**: If you set the credentials of gitlab in formula `vkpr aws eks up`, you dont need to set again.
