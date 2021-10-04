#!/bin/sh

runFormula() {
  echo "VKPR create formula"
  echoColor "green" "(assumes 'shell' language and current path as workspace if none provided)"
  if [ -z "$VKPR_WORKSPACE_PATH" ]; then
    REAL_WORKSPACE_PATH="$CURRENT_PWD"
  else
    REAL_WORKSPACE_PATH="$VKPR_WORKSPACE_PATH"
  fi
  if [ -z "$VKPR_FORMULA_PATH" ]; then
    REAL_FORMULA_PATH="$REAL_WORKSPACE_PATH/${VKPR_FORMULA// //}" # dumb ' ' for '/' replacement (no rit prefix)
  else
    REAL_FORMULA_PATH="$REAL_WORKSPACE_PATH/$VKPR_FORMULA_PATH"
  fi
  REAL_FORMULA="rit $VKPR_FORMULA" # needs rit prefix
  REAL_WORKSPACE_NAME=$(getWorkspaceName "$REAL_WORKSPACE_PATH")
  echo "Creating formula '$REAL_FORMULA' in workspace '$REAL_WORKSPACE_NAME' ('$REAL_WORKSPACE_PATH')"
  # 'rit create formula' input flags are unknown, so we use stdin
  cat << EOF |
  {
    "formulaCmd":"$REAL_FORMULA", 
    "lang":"shell-bat",
    "workspace": { "name": "$REAL_WORKSPACE_NAME", "dir": "$REAL_WORKSPACE_PATH" },
    "formulaPath":"$REAL_FORMULA_PATH"
  }
EOF
  rit create formula --stdin
  cleanupFormula "$REAL_FORMULA_PATH"
}

# removes all things non-shell
cleanupFormula() {
  formulaPath=$1
  if [ ! -f "$formulaPath/config.json" ]; then
    echoColor "red" "cleanupFormula: This is not a formula path (no 'config.json' file), bailing out."
    exit 1
  fi
  # create file
  touch "$formulaPath/help.json"
  # delete files
  rm -f "$formulaPath/build.bat"
  rm -f "$formulaPath/Dockerfile"
  rm -f "$formulaPath/Makefile"
  rm -f "$formulaPath/set_umask.sh"
  rm -Rf "$formulaPath/src/windows"
  # change files
  sed -i.bak '/BINARY_NAME_WINDOWS/d' "$formulaPath/build.sh" # sao duas
  sed -i.bak '/^ENTRY_POINT_WINDOWS/d' "$formulaPath/build.sh"
  sed -i.bak '/Dockerfile/d' "$formulaPath/build.sh" # sao duas
  rm -f "$formulaPath/build.sh.bak"
  # no inputs
  cp "$formulaPath/config.json" "$formulaPath/config.json.bak"
  $VKPR_JQ '.inputs=[]' "$formulaPath/config.json.bak" > "$formulaPath/config.json"
  rm "$formulaPath/config.json.bak"
  # only local
  cp "$formulaPath/metadata.json" "$formulaPath/metadata.json.bak"
  $VKPR_JQ '.execution=["local"]' "$formulaPath/metadata.json.bak" > "$formulaPath/metadata.json"
  rm "$formulaPath/metadata.json.bak"
}

getWorkspaceName() {
  workspacePath="$1"
  if [ -z "$workspacePath" ]; then
    echo >&2 "getWorkspaceName: workspace path cannot be empty."
    exit 1
  fi
  local result=$(rit list workspace | grep "$REAL_WORKSPACE_PATH" | awk '{print $1}')
  echo "$result"
}
