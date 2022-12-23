# VKPR loki install

## Description

Install Loki into cluster. For more information about Loki, click [here.](https://grafana.com/oss/loki/)

Commands

Interactive inputs:

```
  vkpr loki install [flags]
```

Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr loki install --default
```

## Parameters

```
  --default        Set all values with default.
```

## Values File Parameters

```
global:
  loki:
    namespace:   <String>
    metrics:     <Boolean>
    helmArgs:    <Object>
```
