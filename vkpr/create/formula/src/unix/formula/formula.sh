#!/usr/bin/env bash

runFormula() {
  local APP_NAME REAL_FORMULA REAL_WORKSPACE_PATH REAL_FORMULA_PATH REAL_WORKSPACE_NAME;

  APP_NAME=$(echo $VKPR_FORMULA | cut -d " " -f2)
  APP_OPERATION=$(echo $VKPR_FORMULA | cut -d " " -f3)

  REAL_FORMULA="rit $VKPR_FORMULA"

  REAL_WORKSPACE_PATH=$VKPR_WORKSPACE_PATH
  [ -z "$VKPR_WORKSPACE_PATH" ] && REAL_WORKSPACE_PATH="$CURRENT_PWD"

  REAL_FORMULA_PATH="$REAL_WORKSPACE_PATH/$VKPR_FORMULA_PATH"
  [ -z "$VKPR_FORMULA_PATH" ] && REAL_FORMULA_PATH="$REAL_WORKSPACE_PATH/${VKPR_FORMULA// //}"

  REAL_WORKSPACE_NAME=$(getWorkspaceName "$REAL_WORKSPACE_PATH")

  cat << EOF |
  {
    "formulaCmd":"$REAL_FORMULA",
    "lang":"shell-bat",
    "workspace": { "name": "$REAL_WORKSPACE_NAME", "dir": "$REAL_WORKSPACE_PATH" },
    "formulaPath":"$REAL_FORMULA_PATH"
  }
EOF
  rit create formula --stdin > /dev/null # Todo: Change stdin, will be deprecated

  startInfos
  cleanupFormula "$REAL_FORMULA_PATH"
}

startInfos() {
  bold "=============================="
  boldInfo "VKPR Create Formula Routine"
  boldNotice "Formula Name: ${VKPR_FORMULA}"
  boldNotice "Formula Workspace: ${REAL_WORKSPACE_NAME}"
  boldNotice "Formula Path: ${REAL_FORMULA_PATH}"
  bold "=============================="
}

getWorkspaceName() {
  local workspacePath="$1"
  if [ -z "$workspacePath" ]; then
    echo >&2 "getWorkspaceName: workspace path cannot be empty."
    exit 1
  fi
  local result; result=$(rit list workspace | grep "$REAL_WORKSPACE_PATH" | awk '{print $1}')
  echo "$result"
}

# removes all things non-shell
cleanupFormula() {
  local formulaPath=$1
  if [ ! -f "${formulaPath}/config.json" ]; then
    error "cleanupFormula: This isn't a formula path (no 'config.json' file), bailing out."
    exit 1
  fi

  # Create Files
  cat > "${formulaPath}"/help.json <<EOF
{
  "short": "",
  "long": ""
}
EOF
  mkdir -p "${formulaPath}"/src/utils
  touch "${formulaPath}"/src/utils/$APP_NAME.yaml

  # Delete Files
  rm -f "${formulaPath}/Dockerfile"
  rm -f "${formulaPath}/Makefile"
  rm -f "${formulaPath}/set_umask.sh"
  rm -f "${formulaPath}/build.bat"
  rm -f "${formulaPath}/src/main.bat"
  rm -Rf "${formulaPath}/src/windows"

  # No inputs in config.json
  cp "${formulaPath}/config.json" "${formulaPath}/config.json.tmp"
  $VKPR_JQ '.inputs=[] | del(.dockerImageBuilder)' "${formulaPath}"/config.json.tmp > "${formulaPath}"/config.json
  rm "${formulaPath}"/config.json.tmp

  # Only local executing
  cp "${formulaPath}/metadata.json" "${formulaPath}/metadata.json.tmp"
  $VKPR_JQ '.execution=["local"]' "${formulaPath}/metadata.json.tmp" > "${formulaPath}"/metadata.json
  rm "${formulaPath}"/metadata.json.tmp

  # Update files
  echo "" > "${formulaPath}"/README.md
  changeBuildFile
  changeMainFile
  case $APP_OPERATION in
    install)
      changeConfigInstall
      changeFormulaInstall
      ;;
    remove)
      changeFormulaRemove
      ;;
    *)
      changeFormula
      ;;
  esac
}

changeBuildFile() {
  FORMULA_SIZE=$(echo "${VKPR_FORMULA}" | awk -F " " '{print NF}')
  FORMULA_NUMBER=$(seq "$FORMULA_SIZE" | tail -n1)
  path=""
  while [ "$FORMULA_NUMBER" -gt 0 ]; do
    path+="../"
    FORMULA_NUMBER=$(( FORMULA_NUMBER - 1 ))
  done

  cat > "${formulaPath}"/build.sh.tmp <<EOF
#!/usr/bin/env bash

BIN_FOLDER=bin
BINARY_NAME_UNIX=run.sh
ENTRY_POINT_UNIX=main.sh
LIB_RESOURCES="${path}lib"

#bash-build:
	mkdir -p $\BIN_FOLDER/src
	#shellcheck disable=SC2086
	cp -r $\LIB_RESOURCES $\BIN_FOLDER/src
	cp -r src/* $\BIN_FOLDER
	mv $\BIN_FOLDER/$\ENTRY_POINT_UNIX $\BIN_FOLDER/$\BINARY_NAME_UNIX
	chmod +x $\BIN_FOLDER/$\BINARY_NAME_UNIX
EOF

  sed 's/\\//g' "${formulaPath}"/build.sh.tmp > "${formulaPath}"/build.sh
  rm "${formulaPath}"/build.sh.tmp
}

changeMainFile() {
  cat > "${formulaPath}"/src/main.sh.tmp <<EOF
#!/usr/bin/env bash

# shellcheck source=/dev/null
source src/lib/load.sh "validator"
source src/lib/load.sh "functions"
source src/lib/log.sh
source src/lib/var.sh
source src/lib/versions.sh

. "$\(dirname "$\0")"/unix/formula/formula.sh --source-only

globalInputs
verifyActualEnv
runFormula
EOF

  sed 's/\\//g' "${formulaPath}"/src/main.sh.tmp > "${formulaPath}"/src/main.sh
  rm "${formulaPath}"/src/main.sh.tmp
}

changeConfigInstall() {
  cat > "${formulaPath}"/config.json.tmp <<EOF
  {
  "inputs": [
    {
      "tutorial": "Simulate an install",
      "label": "Dry-run ?",
      "name": "dry_run",
      "type": "bool",
      "default": "false",
      "items": [
        "false",
        "true"
      ]
    }
  ],
  "template": "shell-bat",
  "templateRelease:": "2.16.2"
}
EOF

  sed 's|\\||g' "${formulaPath}"/config.json.tmp > "${formulaPath}"/config.json
  rm "${formulaPath}"/config.json.tmp
}

changeFormulaInstall() {
  cat > "${formulaPath}"/src/unix/formula/formula.sh.tmp <<EOF
#!/usr/bin/env bash

runFormula() {
  local VKPR_${APP_NAME^^}_VALUES HELM_ARGS;
  formulaInputs
  validateInputs

  VKPR_${APP_NAME^^}_VALUES=$\(dirname "$\0")/utils/${APP_NAME}.yaml

  startInfos
  setting${APP_NAME^}
  [ $\DRY_RUN = false ] && registerHelmRepository _repo_name_ _repo_url_
  ## Add the version of the application in vkpr-cli/lib/versions.sh
  installApplication "${APP_NAME}" "_repo_name_/_repo_application_" "$\VKPR_ENV_${APP_NAME^^}_NAMESPACE" "$\VKPR_${APP_NAME^^}_VERSION" "$\VKPR_${APP_NAME^^}_VALUES" "$\HELM_ARGS"
}

## Add here some usefull info about the formula
startInfos() {
  bold "=============================="
  boldInfo "VKPR ${APP_NAME^} Install Routine"
  bold "=============================="
}

## Add here values that can be used by the globals (env, vkpr values, input...)
formulaInputs() {
  checkGlobalConfig "$\VKPR_ENV_GLOBAL_NAMESPACE" "$\VKPR_ENV_GLOBAL_NAMESPACE" "${APP_NAME}.namespace" "${APP_NAME^^}_NAMESPACE"
}

## Add here the validators from the inputs
#validateInputs() {}

# Add here a configuration of application
setting${APP_NAME^}() {
  YQ_VALUES=""

  setting${APP_NAME^}Environment

  debug "YQ_CONTENT = $\YQ_VALUES"
}

# Add here a configuration of application in specific envs
setting${APP_NAME^}Environment() {
  if [[ "$\VKPR_ENVIRONMENT" == "okteto" ]]; then
    HELM_ARGS="--cleanup-on-fail"
    YQ_VALUES="$\YQ_VALUES"
  fi
}
EOF

  sed 's|\\||g' "${formulaPath}"/src/unix/formula/formula.sh.tmp > "${formulaPath}"/src/unix/formula/formula.sh
  rm "${formulaPath}"/src/unix/formula/formula.sh.tmp
}


changeFormulaRemove() {
  cat > "${formulaPath}"/src/unix/formula/formula.sh.tmp <<EOF
#!/usr/bin/env bash

runFormula() {
  info "Removing ${APP_NAME^}..."

  HELM_FLAG="-A"
  [[ "$\VKPR_ENVIRONMENT" == "okteto" ]] && HELM_FLAG=""
  ${APP_NAME^^}_NAMESPACE=$\($\VKPR_HELM ls -o=json $\HELM_FLAG | $\VKPR_JQ -r '.[] | select(.name | contains("${APP_NAME}")) | .namespace' | head -n1)

  $\VKPR_HELM uninstall ${APP_NAME} -n "\$${APP_NAME^^}_NAMESPACE" 2> /dev/null || error "VKPR ${APP_NAME^} not found"
}
EOF

  sed 's|\\||g' "${formulaPath}"/src/unix/formula/formula.sh.tmp > "${formulaPath}"/src/unix/formula/formula.sh
  rm "${formulaPath}"/src/unix/formula/formula.sh.tmp
}


changeFormula() {
  cat > "${formulaPath}"/src/unix/formula/formula.sh.tmp <<EOF
#!/usr/bin/env bash

runFormula() {
  info "Hello World!"
}
EOF

  sed 's|\\||g' "${formulaPath}"/src/unix/formula/formula.sh.tmp > "${formulaPath}"/src/unix/formula/formula.sh
  rm "${formulaPath}"/src/unix/formula/formula.sh.tmp
}
