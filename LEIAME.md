# VKPR CLI tool

This repo holds the CLI to manage a VKPR cluster. This CLI is based on Ritchie.

## Why Ritchie?

This CLI is based on Ritchie formulas. Using Ritchie we could create our own CLI following the pattern `vkpr + object + verb + name` and implement it with plain shell scripts.

## Contributing

When cloning this repo please add its folder as a workspace:

```
rit add workspace --name vkpr-formulas --path $(pwd)
```

Ritchie must be installed:

```
curl -fsSL https://commons-repo.ritchiecli.io/install.sh | bash
```

## Using containers

You can use temporary containers to test your formulas in a clean environment:

```
docker run --rm -ti -v $(pwd):/opt centos
```

Install Ritchie in it and configure the workspace:

```
curl -fsSL https://commons-repo.ritchiecli.io/install.sh | sed -e 's/sudo//g' | bash
rit set formula-runner --runner=local
rit add workspace --name vkpr-formulas --path /opt
```
