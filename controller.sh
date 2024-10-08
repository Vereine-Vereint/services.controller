#!/bin/bash
CONTROLLER_VERSION="v0.3"

CONTROLLER_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SERVICES_DIR=$(cd -- "$(dirname -- "$CONTROLLER_DIR")" &>/dev/null && pwd)
SERVICES_ORG=$(basename $SERVICES_DIR | cut -d '.' -f 2)
echo "[SERVICES] $SERVICES_ORG ($(cd $SERVICES_DIR && git rev-parse --short HEAD))"
echo "[CONTROLLER] $CONTROLLER_VERSION ($(cd $CONTROLLER_DIR && git rev-parse --short HEAD))"
set -e

# COMMANDS
declare -A commands=(
  [help]=":Show this help message"
)
cmd_help() {
  print_help "" "commands"
}

# FUNCTIONS
# source $CONTROLLER_DIR/core/func_env.sh
source $CONTROLLER_DIR/core/func_help.sh

# MAIN
main() {
  local command="$1"

  if [[ ! " ${!commands[@]} " =~ " $command " ]]; then
    cmd_help
    if ! [[ -z "$command" ]]; then
      echo
      echo "Unknown command: $command"
    fi
    exit 1
  fi

  # load_env "$1"
  echo

  cd $SERVICES_DIR
  shift
  cmd_$command "$@"
}

# COMMANDS
commands+=([add]="<github url>:Add a new service")
cmd_add() {
  local url="$1"
  # check url is not empty
  if [[ -z $url ]]; then
    echo "Usage: add <github url>"
    exit 1
  fi

  # check url is in ssh format, not https
  if [[ $url == "https://"* ]]; then
    echo "Please use the ssh format for the git url"
    exit 1
  fi
  local service_name=$(basename $url | cut -d '.' -f 2)
  
  # clone the repo
  git submodule add $url $service_name
  cd $service_name
  git submodule update --init --recursive
  cd ..

  # add to README
  printf "\n### $service_name [documentation](./$service_name/README.md)\n" >> README.md

  echo "[ OK ] Service added: $service_name"
}

commands+=([update]=":Update all services to the services repo")
cmd_update() {
  echo "Resetting all services..."
  git fetch --all && git restore . && git clean -fd && git checkout main && git pull
  git submodule foreach --recursive "git fetch --all && git restore . && git pull && git clean -fd && git reset --hard"
  git submodule update --init --recursive
}

commands+=([update-services]=":Update all services to the latest commit on main of each service")
cmd_update-services() {
  echo "Pulling all services..."
  git fetch --all && git restore . && git clean -fd && git checkout main && git pull
  git submodule foreach --recursive "git fetch --all && git restore . && git pull && git clean -fd && git reset --hard"
  git submodule foreach "git checkout main && git checkout main && git pull && git submodule update --init --recursive"
}

commands+=([update-all]=":Update all services and submodules of services to the latest commit on main of each service")
cmd_update-all() {
  echo "Pulling all services and submodules..."
  git fetch --all && git restore . && git clean -fd && git checkout main && git pull
  git submodule foreach --recursive "git fetch --all && git restore . && git clean -fd && git checkout main && git checkout main && git pull"
}

commands+=([backup]=":Backup all services using borg")
cmd_backup() {
  echo "Backing up all services..."
  git submodule foreach "./service.sh borg backup auto"
}

# EXECUTION
main "$@"
