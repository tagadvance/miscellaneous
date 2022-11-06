#!/bin/bash

##
## Scan current working directory and all parents for Gradle Wrapper. If found all aguments will be
## proxied to the Gradle Wrapper.
##

# https://unix.stackexchange.com/a/22215/102941
find_up() {
  current_path=$PWD
  while [[ "$current_path" != "" && ! -e "$current_path/$1" ]]; do
    current_path=${current_path%/*}
  done

  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  if [[ "$script_dir" == "$current_path" ]]; then
    printf '%s\n' "DO NOT CALL $1 FROM $script_dir!" >&2
    exit 1
  fi

  gradlew="$current_path/$1"
}

find_up 'gradlew'
if [[ -f "$gradlew" ]]; then
  eval "$gradlew" "$@"
else
  echo "$search not found in current directory or any parent"
fi
