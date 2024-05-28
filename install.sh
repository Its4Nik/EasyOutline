#!/bin/env/bash

set -euo pipefail

logs="$(mktemp)"
path_to_outline=""
raw_setup_file="https://raw.githubusercontent.com/Its4Nik/EasyOutline/main/setup.sh"
raw_defaults="https://raw.githubusercontent.com/Its4Nik/EasyOutline/main/default-params.txt"

run_and_log(){
  echo "# Executing $1" >> $logs
  $1 && echo "# OK" >> $logs || echo ">>> $1 unseccesful please try troubbleshooting" >> $logs
}

get_install_location(){
  echo "Where do you want to place outline? (Full path)"
  run_and_log "read -r -p \"> \" path_to_outline"
  run_and_log "confirm \"get_install_location\" \"$path_to_outline\""
}

fail(){
  echo ">>> Last Operation unsuccessfull. Please have a look at the logs: $logs"
}

confirm(){
  local function="$1"
  local value="$2"
  echo
  echo "Is this correct? $value"
  read -p "(y/n) " -r -n 1 yn
  case $yn in
    y|Y) echo && echo "Continuing..." ;;
    n|N) echo && echo "Try again" && $function ;;
    *) echo && echo "Unknwon value, please try again" && $function ;;
  esac
}

echo ">>> Changing directory to: $path_to_outline"
run_and_log "cd $path_to_outline" || fail



