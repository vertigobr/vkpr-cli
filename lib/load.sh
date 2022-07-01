#!/bin/bash

for i in $(ls src/lib/$1); do
  source src/lib/$1/$i
done