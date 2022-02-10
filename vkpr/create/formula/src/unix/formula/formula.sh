#!/bin/sh

runFormula() {   
  local REAL_FORMULA="rit $VKPR_FORMULA" 
  local VKPR_FORMULA_LANGUAGE="shell-bat" # Possible to use another languages in future
  local REAL_WORKSPACE_PATH="$VKPR_WORKSPACE_PATH"
  local REAL_FORMULA_PATH="$REAL_WORKSPACE_PATH/$VKPR_FORMULA_PATH"

  if [ -z "$VKPR_WORKSPACE_PATH" ]; then
    REAL_WORKSPACE_PATH="$CURRENT_PWD"
  fi
  #echo "DEBUG VKPR_FORMULA_PATH='$VKPR_FORMULA_PATH'"
  #echo "DEBUG VKPR_FORMULA='$VKPR_FORMULA'"

  if [ -z "$VKPR_FORMULA_PATH" ]; then
    REAL_FORMULA_PATH="$REAL_WORKSPACE_PATH/${VKPR_FORMULA// //}"
  fi

  local REAL_WORKSPACE_NAME=$(getWorkspaceName "$REAL_WORKSPACE_PATH")

  startInfos

  cat << EOF |
  {
    "formulaCmd":"$REAL_FORMULA", 
    "lang":"shell-bat",
    "workspace": { "name": "$REAL_WORKSPACE_NAME", "dir": "$REAL_WORKSPACE_PATH" },
    "formulaPath":"$REAL_FORMULA_PATH"
  }
EOF
  rit create formula --stdin > /dev/null # Todo: Change stdin, will be deprecated
  cleanupFormula "$REAL_FORMULA_PATH"
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Create Formula Routine")"
  echoColor "bold" "$(echoColor "blue" "Formula Name:") ${VKPR_FORMULA}"
  echoColor "bold" "$(echoColor "blue" "Formula Language:") ${VKPR_FORMULA_LANGUAGE}"
  echoColor "bold" "$(echoColor "blue" "Formula Workspace:") ${REAL_WORKSPACE_NAME}"
  echoColor "bold" "$(echoColor "blue" "Formula Path:") ${REAL_FORMULA_PATH}"
  echo "=============================="
}

getWorkspaceName() {
  local workspacePath="$1"
  if [ -z "$workspacePath" ]; then
    echo >&2 "getWorkspaceName: workspace path cannot be empty."
    exit 1
  fi
  local result=$(rit list workspace | grep "$REAL_WORKSPACE_PATH" | awk '{print $1}')
  echo "$result"
}

# removes all things non-shell
cleanupFormula() {
  local formulaPath=$1
  if [ ! -f "${formulaPath}/config.json" ]; then
    echoColor "red" "cleanupFormula: This isn't a formula path (no 'config.json' file), bailing out."
    exit 1
  fi

  # Create Files
  cat > ${formulaPath}/help.json <<EOF
{
  "short": "",
  "long": ""
}
EOF
  mkdir -p ${formulaPath}/src/utils

  # Delete Files
  rm -f "${formulaPath}/Dockerfile"
  rm -f "${formulaPath}/Makefile"
  rm -f "${formulaPath}/set_umask.sh"
  rm -f "${formulaPath}/build.bat"
  rm -f "${formulaPath}/src/main.bat"
  rm -Rf "${formulaPath}/src/windows"

  # Change Files
  sed -i.tmp '/BINARY_NAME_WINDOWS/d' "${formulaPath}/build.sh"
  sed -i.tmp '/ENTRY_POINT_WINDOWS/d' "${formulaPath}/build.sh"
  echo "$(head -n 11 ${formulaPath}/build.sh)" > "${formulaPath}/build.sh"
  rm ${formulaPath}/build.sh.tmp

  # No inputs in config.json
  cp "${formulaPath}/config.json" "${formulaPath}/config.json.tmp"
  $VKPR_JQ '.inputs=[] | del(.dockerImageBuilder)' ${formulaPath}/config.json.tmp > ${formulaPath}/config.json
  rm ${formulaPath}/config.json.tmp

  # Only local executing
  cp "${formulaPath}/metadata.json" "${formulaPath}/metadata.json.tmp"
  $VKPR_JQ '.execution=["local"]' "${formulaPath}/metadata.json.tmp" > ${formulaPath}/metadata.json
  rm ${formulaPath}/metadata.json.tmp

  echo "" > ${formulaPath}/README.md

  # Change entire file
  changeMainFile
  changeFormula
}

changeFormula() {
  cat > ${formulaPath}/src/unix/formula/formula.sh <<EOF
#!/bin/bash

runFormula() {
  echo "Hello World"
}
EOF
}

changeMainFile() {
  cat > ${formulaPath}/src/main.sh.tmp <<EOF
#!/bin/bash

VKPR_SCRIPTS=~/.vkpr/src

source $\VKPR_SCRIPTS/log.sh
source $\VKPR_SCRIPTS/var.sh
source $\VKPR_SCRIPTS/helper.sh

. "$\(dirname "$\0")"/unix/formula/formula.sh --source-only

runFormula
EOF

  sed 's/\\//g' ${formulaPath}/src/main.sh.tmp > ${formulaPath}/src/main.sh
  rm ${formulaPath}/src/main.sh.tmp
}