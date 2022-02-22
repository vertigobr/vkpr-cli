# VKPR aws eks destroy

## Description

Destroy the EKS cluster created by the GitOps pipeline.
Commands#

Non-interactive:

```
  vkpr aws eks destroy [flags]
```

## Parameters

```
  --gitlab_token         Specifies your Gitlab Access-Token
  --gitlab_username      Specifies your Gitlab Username
```

## Setting Credentials manually

### Gitlab

```
  rit set credential --provider="gitlab" --fields="token,username" --values="your-token,your-username"
```
