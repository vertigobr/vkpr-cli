# Contribute to VKPR CLI

## Creating Formulas

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

## Setting your Credentials

1. Run the Command `rit set credential`
2. This command will ask some few questions, such as:
   - Provider
     - Will be the github
   - username
     - vertigobr
   - email
     - Your Github Email
   - token
     - A Personal Token Access where you can generate [here](https://github.com/settings/tokens)
3. This will allow you to publish your formulas in the project.

## Publishing Formulas

1. Finish creating or updating formulas (see above)
2. Make sure you have Github credentials in Ritchie (`rit set credential`)
3. Run the command (`rit publish repo`) and you will need to inform some inputs:
   - Provider
     - Github
   - Repository Privacy
     - false
   - Repository Name
     - vkpr-cli
   - Local Repository Path
     - Path from the project
   - Release Version
     - Ex: v1.0.1
4. If you dont want to use the command, you still can merge your current branch to the main and commit
