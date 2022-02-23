# Contributing

We are grateful that you would like to contribute to the VKPR-CLI. But before you start, check the existing issues to see if the bug or feature request has not been submitted yet.

When opening an issue, open it for the following cases:
- Something isn't working the way it should
- Suggestions of what can be added or changed
- New formulas to be created

Please avoid:
- Opening pull request for issues marked `blocked`, `needs-investigation` or `needs-design`

## Building the Project

Pre requisites:
- Unix environment
- [Ritchie CLI](https://ritchiecli.io/)
- OpenSSL

Build with: `make init`

Run tests with: `make test <application>`

## Submitting a PR

1. Create a new branch: `git checkout -b my-branch-name`
2. Make your change, create tests and ensure tests pass
3. Submit a pull request

## Commit message

Commit message example: 
```md
<type>: <description>
```

`<type>`
This describes the kind of change that this commit is providing

- feat (feature)
- fix (bug fix)
- docs (documentation)
- style (formatting code)
- refactor(restructuring codebase)
- test (when adding missing tests)

`<description>`
This is a short description about the change

- use imperative
- don't capitalize the message
- no dot (.) at the end

Message final example:
```txt
feat(keycloak): create new import formula
```

## Creating / Updating Formulas

- Clone the repository (or fork if you don't have write access)
- Create a branch following the instructions above
  - To create your formula, you need to run the command `vkpr create formula`
- Commit and Push your branch with the changes: `git push origin <project_name>/<location>`
- Open a pull request on the repository for analysis.

Example to create new formulas:
```sh
vkpr create formula --vkpr_formula="<name-of-formula>"
```

>WARNING: When creating a new formula, pay attention to the pattern used to create them.
>
>`vkpr + application + method`
