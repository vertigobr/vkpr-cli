#!/bin/bash

verifyExistingEnv(){
  aux=0
  for i in "$@"
  do
    if [ -z $(cat $VKPR_GLOBALS/.env | grep $i) ]; then
      if (( $aux % 2 == 0 )); then
        printf "VKPR_ENV_${i}=" >> $VKPR_GLOBALS/.env
        else
        printf "${i}\n" >> $VKPR_GLOBALS/.env
      fi
      let "aux++"
    fi
  done
}