
# Contribute to VKPR CLI

## Creating formulas

1. Clone the repository (or fork if you don't have write access)
2. Create a branch: `git checkout -b <branch_name>`
3. Check the step by step of [how to create formulas on Ritchie](https://docs.ritchiecli.io/tutorials/formulas/how-to-create-formulas)
4. Add your formulas to the repository and commit your implementation: `git commit -s -m '<commit_message>'`
5. Push your branch: `git push origin <project_name>/<location>`
6. Open a pull request on the repository for analysis.

## Updating Formulas

1. Clone the repository (or fork if you don't have write access)
2. Create a branch: `git checkout -b <branch_name>`
3. Add the cloned repository to your workspaces (`rit add workspace`) with a highest priority (for example: 1).
4. Check the step by step of [how to implement formulas on Ritchie](https://docs.ritchiecli.io/tutorials/formulas/how-to-implement-a-formula)
and commit your implementation: `git commit -m '<commit_message>`
5. Push your branch: `git push origin <project_name>/<location>`
6. Open a pull request on the repository for analysis.

Ex:

```
rit add workspace --name vkpr-formulas --path $(pwd)
```

## Publishing Formulas

1. Finish creating or updating formulas (see above)
2. Make sure you have Github credentials in Ritchie (`rit set credential `)