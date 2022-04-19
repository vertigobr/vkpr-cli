# VKPR postgres install

## Description

Install Postgresql into cluster. For more information about Postgresql, click [here.](https://www.postgresql.org/)

## Commands

Interactive inputs:

```
  vkpr postgres install [flags]
```
Non-interactive without setting values or using ```VKPR Values```:

```
  vkpr postgres install --default
```

## Parameters

```
  --default        Set all values with default.
  --HA             Specifies if the application will have High Availability.   Default: false
```

## Values File Parameters

```yaml
vkpr.yaml
```
```yaml
global:
  postgres:
    namespace:   <String>
    HA:          <Boolean>
    metrics:     <Boolean>
    helmArgs:    <Object>
```
