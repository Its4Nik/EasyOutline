#!/bin/env/bash

set -euo pipefail

option="${1:-}"
logs="$(mktemp)"
path_to_outline=""
dependencies=("docker" "wget" "docker-compose" "git")
raw_files=("https://raw.githubusercontent.com/Its4Nik/EasyOutline/main/default-params.txt" "https://raw.githubusercontent.com/Its4Nik/EasyOutline/main/setup.sh")

# ----------------------------------

help() {
  echo "
Usage:
$0 => Runs the default installer.
$0 <parameter>
  -h | --help      - Shows this help message

To redo the whole setup run the setup.sh file located where you have outline installed but with another parameter:
\`bash setup.sh -r\` or \`bash setup.sh --redo\`
"
}

run_and_log() {
  local cmd="$1"
  echo "# Executing $cmd" >> "$logs"
  if eval "$cmd"; then
    echo "# OK" >> "$logs"
  else
    echo ">>> $cmd unsuccessful, please try troubleshooting" >> "$logs"
  fi
}

get_install_location() {
  echo "Where do you want to place outline? (Full path)"
  read -r -p "> " path_to_outline
  confirm "get_install_location" "$path_to_outline"
}

fail() {
  echo ">>> Last Operation unsuccessful. Please have a look at the logs: $logs"
}

confirm() {
  local function="$1"
  local value="$2"
  echo
  echo "Is this correct? $value"
  read -r -p "(y/n) " yn
  echo
  case $yn in
    y|Y) echo "Continuing..." ;;
    n|N) echo "Try again" && "$function" ;;
    *) echo "Unknown value, please try again" && "$function" ;;
  esac
}

run_setup() {
  local choice="$1"
  case $choice in
    *) run_first_install ;;
  esac
}

run_first_install() {
  # Install necessary files:
  for item in "${raw_files[@]}"; do
    filename=$(basename "$item")
    run_and_log "wget -O $filename $item"
  done
}

check_dependencies() {
  for dep in "${dependencies[@]}"; do
    if ! type "$dep" > /dev/null 2>&1; then
      echo "$dep not found. Please install it and try again."
      exit 1
    else
      echo "$dep found."
    fi
  done
}

install_outline() {
  echo "Installing outline to $path_to_outline..."
  run_and_log "cd \"$path_to_outline\""
  # Add installation commands here
}

# ----------------------------------

case "$option" in
  -h|--help) help ;;
  *) true ;;
esac

check_dependencies
get_install_location
install_outline "$option"
