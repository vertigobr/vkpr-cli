#!/usr/bin/env bash

for i in $(ls src/lib/$1); do
  [ ! -f src/lib/$1/$i ] && return
  source src/lib/$1/$i
done
