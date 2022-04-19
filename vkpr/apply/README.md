# VKPR Apply

## Description

VKPR apply is a simpler method of installing all the tools you want with VKPR. With a yaml file informing the values that the applications will use, it will run all the necessary formulas to create the scenario that was specified in the yaml file.

## Commands

Interactive inputs:

```bash
vkpr apply [flags]
```

Non-interactive:

```bash
vkpr apply --path_to_file="/path/to/values"
```

## Example Values

```yaml
vkpr.yaml
```
```yaml

global:
  APP:
    enabled:    <Boolean>
```
