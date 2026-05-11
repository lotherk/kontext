#!/bin/sh
# Environment plugin for kontext
# Manages environment variables

# Load hook - called when context is loaded
env_load() {
  echo "Environment plugin: Load hook called"
}

# Main function - called when plugin is executed
env_main() {
  local subcommand="$1"
  shift
  
  case "$subcommand" in
    list|ls)
      env_list "$@"
      ;;
    set)
      env_set "$@"
      ;;
    get)
      env_get "$@"
      ;;
    unset|rm)
      env_unset "$@"
      ;;
    *)
      echo "Usage: kontext env [list|set|get|unset] [args...]"
      ;;
  esac
}

# Unload hook - called when context is unloaded
env_unload() {
  echo "Environment plugin: Unload hook called"
}

# List environment variables
env_list() {
  local pattern="$1"
  if [ -z "$pattern" ]; then
    env | sort
  else
    env | grep "$pattern" | sort
  fi
}

# Set environment variable
env_set() {
  local name="$1"
  local value="$2"
  
  if [ -z "$name" ]; then
    echo "Usage: kontext env set <name> <value>"
    return 1
  fi
  
  export "$name=""$value"""
  echo "Set $name=""$value"""
}

# Get environment variable
env_get() {
  local name="$1"
  
  if [ -z "$name" ]; then
    echo "Usage: kontext env get <name>"
    return 1
  fi
  
  if [ -z "${!name}" ]; then
    echo "Variable $name is not set"
    return 1
  else
    echo "${!name}"
  fi
}

# Unset environment variable
env_unset() {
  local name="$1"
  
  if [ -z "$name" ]; then
    echo "Usage: kontext env unset <name>"
    return 1
  fi
  
  unset "$name"
  echo "Unset $name"
}
