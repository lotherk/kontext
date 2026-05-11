#!/bin/sh
#
# kontext switch for the uberops.
#
# MIT License
#
# Copyright (c) 2024 Konrad Lother <konrad@lother.io>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

KONTEXT_VERSION='0.99.1'

if [ -z "$KONTEXT_HOME" ]; then
  KONTEXT_HOME="${HOME}/.kontext"
  export KONTEXT_HOME
fi

# Default workspace directory
if [ -z "$KONTEXT_DEFAULT_WORKSPACE" ]; then
  KONTEXT_DEFAULT_WORKSPACE="${HOME}/workspace"
  export KONTEXT_DEFAULT_WORKSPACE
fi

# Create workspace directory if it doesn't exist
if [ ! -d "${KONTEXT_DEFAULT_WORKSPACE}" ]; then
  mkdir -p "${KONTEXT_DEFAULT_WORKSPACE}"
fi

if [ -z "$KONTEXT_CONFIG" ] && [ -r "${KONTEXT_HOME}/config.sh" ]; then
  KONTEXT_CONFIG="${KONTEXT_HOME}/config.sh"
  export KONTEXT_CONFIG
fi

# Built-in subcommands (hardcoded for POSIX compatibility)
__KONTEXT_BUILTINS="cd create list load status unload version"

# Helper function, thanks to
# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
__is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
    case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else
    case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1
}

  if [ -z "$KONTEXT_HOME" ]; then
  echo 'KONTEXT_HOME must be set' > /dev/stderr
  __is_sourced && return 1 || exit 1
fi

# Print usage
__usage() {
  echo "Usage: kontext [options] [subcommand] [subcommand_options] args..."
}

# Print help
__help() {

cat <<EOM_HEADER
kontext ${KONTEXT_VERSION}, copyright 2014 Konrad Lother <konrad@lother.io>

  options:
    -D          - enable debug
    -c name     - set kontext to name
    -h          - print this help

EOM_HEADER

  echo 'available subcommands'

  for c in $(__kontext_list_subcommands); do
    echo '    '$c
  done

  echo
  echo 'See kontext <subcommand> -h for additional informations'

  echo
  __usage
  return 1
}

__debug() {
  [ ! -z $KONTEXT_DEBUG ] && [ $KONTEXT_DEBUG -gt 0 ] && __log -s DEBUG $@
}

__echo() {
  echo $@
}

__log() {
  __echo $@
}

__kontext_prompt() {
  if [ ! -z "$KONTEXT" ]; then
    echo "[${KONTEXT}]"
  fi
}

# Call plugin hooks for all plugins
__call_plugin_hooks() {
  local hook_type="$1"
  
  # Call hooks for global plugins
  if [ -d "${KONTEXT_HOME}/plugins" ]; then
    for plugin_file in "${KONTEXT_HOME}/plugins"/*.sh; do
      [ ! -f "$plugin_file" ] && continue
      
      local plugin_name="$(basename "$plugin_file" .sh)"
      __debug "Checking ${hook_type} hook for global plugin ${plugin_name}"
      
      # Source the plugin to make its functions available
      . "$plugin_file"
      
      # Check if the hook function exists and call it
      if type "${plugin_name}_${hook_type}" 2>/dev/null; then
        __debug "Calling ${hook_type} hook for global plugin ${plugin_name}"
        "${plugin_name}_${hook_type}"
      fi
    done
  fi
  
  # Call hooks for context-specific plugins
  if kontext_loaded && [ -d "${KONTEXT_PATH}/.plugins" ]; then
    for plugin_file in "${KONTEXT_PATH}/.plugins"/*.sh; do
      [ ! -f "$plugin_file" ] && continue
      
      local plugin_name="$(basename "$plugin_file" .sh)"
      __debug "Checking ${hook_type} hook for context plugin ${plugin_name}"
      
      # Source the plugin to make its functions available
      . "$plugin_file"
      
      # Check if the hook function exists and call it
      if type "${plugin_name}_${hook_type}" 2>/dev/null; then
        __debug "Calling ${hook_type} hook for context plugin ${plugin_name}"
        "${plugin_name}_${hook_type}"
      fi
    done
  fi
}

# Run a plugin with lifecycle management
__run_plugin() {
  local plugin_file="$1"
  local plugin_name="$(basename "$plugin_file" .sh)"
  shift
  
  # Source the plugin file to get access to its functions
  . "$plugin_file"
  
  # Check if the plugin has the required main function
  if type "${plugin_name}_main" 2>/dev/null; then
    # Call load hook if it exists
    if type "${plugin_name}_load" 2>/dev/null; then
      __debug "Calling load hook for plugin ${plugin_name}"
      "${plugin_name}_load" "$@"
    fi
    
    # Call the main function with arguments
    __debug "Executing plugin ${plugin_name}"
    "${plugin_name}_main" "$@"
    
    # Call unload hook if it exists
    if type "${plugin_name}_unload" 2>/dev/null; then
      __debug "Calling unload hook for plugin ${plugin_name}"
      "${plugin_name}_unload" "$@"
    fi
  else
    echo "Plugin ${plugin_name} is missing required main() function" >&2
    return 1
  fi
}

__kontext_list_subcommands() {
  subcommands="$__KONTEXT_BUILTINS"
  
  # Check for global plugin scripts in ~/.kontext/plugins
  if [ -d "${KONTEXT_HOME}/plugins" ]; then
    for f in "${KONTEXT_HOME}/plugins"/*.sh; do
      if [ -f "$f" ]; then
        subcommands="${subcommands} $(basename "$f" .sh)"
      fi
    done
  fi
  
  # Check for context-specific plugin scripts in .plugins directory
  if kontext_loaded && [ -d "${KONTEXT_PATH}/.plugins" ]; then
    for f in "${KONTEXT_PATH}/.plugins"/*.sh; do
      if [ -f "$f" ]; then
        subcommands="${subcommands} $(basename "$f" .sh)"
      fi
    done
  fi
  
  # Check for global executable plugins (backward compatibility)
  if [ -d "${KONTEXT_HOME}/plugins" ]; then
    for f in "${KONTEXT_HOME}/plugins"/*; do
      if [ -x "$f" ] && [ -f "$f" ] && [[ "$f" != *.sh ]]; then
        subcommands="${subcommands} $(basename "$f")"
      fi
    done
  fi
  
  # Check for context-specific executable plugins (backward compatibility)
  if kontext_loaded && [ -d "${KONTEXT_PATH}/.plugins" ]; then
    for f in "${KONTEXT_PATH}/.plugins"/*; do
      if [ -x "$f" ] && [ -f "$f" ] && [[ "$f" != *.sh ]]; then
        subcommands="${subcommands} $(basename "$f")"
      fi
    done
  fi
  
  echo $subcommands
}

# applies magic upon kontext load
__kontext_magic() {
  # Take environment snapshot before modifying environment
  if [ -z "${KONTEXT_ENV_SNAPSHOT}" ]; then
    __debug "Taking environment snapshot"
    KONTEXT_ENV_SNAPSHOT="$(env | grep -v '^KONTEXT' | grep -v '^PS1' | grep -v '^KONTEXT_ENV_SNAPSHOT' | sort)"
    export KONTEXT_ENV_SNAPSHOT
  fi

  # Run global load hooks from ~/.kontext/hooks/
  if [ -d "${KONTEXT_HOME}/hooks" ]; then
    if [ -f "${KONTEXT_HOME}/hooks/load.sh" ]; then
      __debug "Running global load hook from ${KONTEXT_HOME}/hooks/load.sh"
      . "${KONTEXT_HOME}/hooks/load.sh"
    fi
  fi

  # Load hooks from .hooks/ directory if they exist
  if [ -d "${KONTEXT_PATH}/.hooks" ]; then
    if [ -f "${KONTEXT_PATH}/.hooks/load.sh" ]; then
      __debug "Running load hook from ${KONTEXT_PATH}/.hooks/load.sh"
      . "${KONTEXT_PATH}/.hooks/load.sh"
    fi
  fi
  
  # Call load hooks for all loaded plugins
  __call_plugin_hooks "load"

  if [ -f "${KONTEXT_PATH}/env.sh" ]; then
    __debug "Loading env.sh"
    . "${KONTEXT_PATH}/env.sh"
  fi

  if [ -f "${KONTEXT_PATH}/path.sh" ]; then
    __debug "Loading path.sh"
    . "${KONTEXT_PATH}/path.sh"
  fi

  if [ -f "${KONTEXT_PATH}/kubeconfig.yaml" ]; then
    __debug "Loading kubeconfig.yaml"
    KUBECONFIG="${KONTEXT_PATH}/kubeconfig.yaml"
    export KUBECONFIG
  fi

  if command -v direnv >/dev/null 2>&1 && [ -f "${KONTEXT_PATH}/.envrc" ]; then
    __debug "Allowing .envrc for direnv"
    direnv allow "${KONTEXT_PATH}/.envrc"
  fi

  # Auto-initialize git repository if KONTEXT_GIT is enabled
  if [ -z "${KONTEXT_GIT}" ]; then
    # Default to 1 if git is installed
    if command -v git >/dev/null 2>&1; then
      KONTEXT_GIT=1
    else
      KONTEXT_GIT=0
    fi
  fi
  
  if [ ! -z "${KONTEXT_GIT}" ] && [ "${KONTEXT_GIT}" -gt 0 ]; then
    if [ ! -d "${KONTEXT_PATH}/.git" ]; then
      __debug "Initializing git repository in ${KONTEXT_PATH}"
      if command -v git >/dev/null 2>&1; then
        git init "${KONTEXT_PATH}" >/dev/null 2>&1
        # Create initial .gitignore if it doesn't exist
        if [ ! -f "${KONTEXT_PATH}/.gitignore" ]; then
          echo ".DS_Store" > "${KONTEXT_PATH}/.gitignore"
          echo "*.swp" >> "${KONTEXT_PATH}/.gitignore"
        fi
        # Create initial README if it doesn't exist
        if [ ! -f "${KONTEXT_PATH}/README.md" ]; then
          echo "# ${KONTEXT} Context" > "${KONTEXT_PATH}/README.md"
          echo "" >> "${KONTEXT_PATH}/README.md"
          echo "Auto-created by kontext" >> "${KONTEXT_PATH}/README.md"
        fi
      fi
    fi
  fi

  KONTEXT_PRESERVE_PS1="$PS1"
  export KONTEXT_PRESERVE_PS1
  PS1="[${KONTEXT}] ${PS1}"
  export PS1
  
  # Override cd function if not already overridden
  if [ -z "${KONTEXT_CD_OVERRIDDEN}" ]; then
    __debug "Overriding cd function for .kontextrc support"
    export KONTEXT_CD_OVERRIDDEN=1
  fi
}


__is_sourced && export __SOURCED=1 || export __SOURCED=0

kontext() {
  while getopts "c:hD" arg; do
    case "${arg}" in
      D) export KONTEXT_DEBUG=1
        ;;
      c)  KONTEXT="${OPTARG}"
        ;;
      h)  __help
        ;;
      *)  __usage
        return 1
        ;;
    esac
  done

  shift $((OPTIND-1))

  if [ $# -eq 0 ]; then
    return 0
  fi

  cmd=$1
  shift

  # Check if $cmd is a built-in function
  if type "kontext_${cmd}" 2>/dev/null; then
    "kontext_${cmd}" "$@"
  # Check if $cmd is a context-specific plugin
  elif kontext_loaded && [ -f "${KONTEXT_PATH}/.plugins/${cmd}.sh" ]; then
    __run_plugin "${KONTEXT_PATH}/.plugins/${cmd}.sh" "$@"
  # Check if $cmd is a global plugin
  elif [ -f "${KONTEXT_HOME}/plugins/${cmd}.sh" ]; then
    __run_plugin "${KONTEXT_HOME}/plugins/${cmd}.sh" "$@"
  # Check if $cmd is a context-specific executable plugin (backward compatibility)
  elif kontext_loaded && [ -x "${KONTEXT_PATH}/.plugins/${cmd}" ]; then
    "${KONTEXT_PATH}/.plugins/${cmd}" "$@"
  # Check if $cmd is a global executable plugin (backward compatibility)
  elif [ -x "${KONTEXT_HOME}/plugins/${cmd}" ]; then
    "${KONTEXT_HOME}/plugins/${cmd}" "$@"
  else
    echo "${0}: unknown subcommand '${cmd}', try ${0} -h for help" >/dev/stderr
    return 1
  fi

}
kontext_loaded() {
  if [ -z "$KONTEXT" ]; then
    return 1
  else
    return 0
  fi
}


kontext_cd() {
  kontext_loaded || return 1
  
  echo "${KONTEXT_PATH}"
  cd "${KONTEXT_PATH}"
}

# Override cd function to check for .kontextrc files
cd() {
  local new_dir="$1"
  
  # Change to the new directory using builtin cd
  builtin cd "$new_dir" || return 1
  
  # Check if .kontextrc exists and is executable
  if [ -f ".kontextrc" ] && [ -x ".kontextrc" ]; then
    if [ -z "${KONTEXT_STRICT}" ]; then
      KONTEXT_STRICT=0
    fi
    
    if [ "${KONTEXT_STRICT}" -gt 0 ]; then
      # Strict mode: ask for confirmation
      __debug "Found .kontextrc in $(pwd), strict mode enabled"
      # For now, skip in non-interactive shells
      if [ -t 0 ]; then
        while true; do
          echo -n "Found .kontextrc in $(pwd). Load it? [y/N] "
          read answer
          case "$answer" in
            [Yy]*)
              __debug "Loading .kontextrc in $(pwd)"
              source ".kontextrc"
              break
              ;;
            *)
              __debug "Skipping .kontextrc in $(pwd)"
              break
              ;;
          esac
        done
      else
        __debug "Skipping .kontextrc in $(pwd) - not interactive"
      fi
    else
      # Non-strict mode: auto-load
      __debug "Auto-loading .kontextrc in $(pwd)"
      source ".kontextrc"
    fi
  fi
}

# Store the original cd function if not already stored
if [ -z "${KONTEXT_ORIGINAL_CD}" ]; then
  KONTEXT_ORIGINAL_CD="$(type cd 2>/dev/null | head -1)"
  export KONTEXT_ORIGINAL_CD
fi

kontext_list() {
  # Use new context directory structure
  context_dir="${KONTEXT_HOME}/context"
  
  # Create context directory if it doesn't exist
  if [ ! -d "${context_dir}" ]; then
    mkdir -p "${context_dir}"
  fi
  
  # List contexts from new location
  if [ -d "${context_dir}" ]; then
    ls -1 "${context_dir}"
  fi
}
alias kontext-ls=kontext_list

kontext_version() {
  __echo 'kontext '$KONTEXT_VERSION' (c) 2024 Konrad Lother'
}

kontext_status() {
  if kontext_loaded; then
    __echo "Active kontext: ${KONTEXT}"
    __echo "Path: ${KONTEXT_PATH}"
    if [ -f "${KONTEXT_PATH}/env.sh" ]; then
      __echo "Env file loaded: ${KONTEXT_PATH}/env.sh"
    fi
    if [ -f "${KONTEXT_PATH}/kubeconfig.yaml" ]; then
      __echo "KUBECONFIG set: ${KONTEXT_PATH}/kubeconfig.yaml"
    fi
  else
    __echo "No active kontext"
  fi
}

kontext_create() {
  context_name="$1"
  if [ -z "${context_name}" ]; then
    __echo "Error: context name cannot be empty" >> /dev/stderr
    return 1
  fi
  
  # Use new context directory structure: ~/.kontext/context/
  context_dir="${KONTEXT_HOME}/context"
  dest="${context_dir}/${context_name}"
  
  # Create context directory (migrate old structure if needed)
  if [ ! -e "${dest}" ]; then
    mkdir -p "${dest}"
    __echo "kontext created at '${dest}'"
  else
    __echo "kontext already exists at '${dest}'"
  fi
  
  # Create workspace directory and initialize git
  workspace_dir="${KONTEXT_DEFAULT_WORKSPACE}/${context_name}"
  if [ ! -e "${workspace_dir}" ]; then
    mkdir -p "${workspace_dir}"
    
    # Initialize git repository
    if command -v git >/dev/null 2>&1; then
      __debug "Initializing git repository in workspace: ${workspace_dir}"
      git init "${workspace_dir}" >/dev/null 2>&1
      
      # Create default .gitignore
      cat > "${workspace_dir}/.gitignore" <<'EOF'
# Dependencies
node_modules/
bower_components/
vendor/

# Environment files
.env
.env.local
.env.*.local

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs generated by jscoverage/JSCover
lib-cov

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage (https://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# Bower dependency directory (https://bower.io/)
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons (https://nodejs.org/api/addons.html)
build/Release

# Dependency directories
jspm_packages/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn integrity file
.yarn-integrity

# dotenv environment variables file
.env.test

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next
out

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
# Comment in the public line in if your project uses Gatsby and not Next.js
# https://nextjs.org/blog/next-9-1#public-directory-support-and-opting-out-of-file-system-routing
# public

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless/

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# vscode extensions
.vscode/extensions

# Local History for Visual Studio Code
.history/

# Built Visual Studio Code Extensions
.out
vsix

# DART
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/

# IDE
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Python
__pycache__/
*.py[cod]
*$py.class

# Java
*.class

# C/C++
*.o
*.ko
*.obj
*.elf

# Rust
arget/

# Go
bin/
pkg/

# Docker
docker-compose.override.yml

# Local development
debug.log
*.stackdump

# Profiler output
*.heapdump
*.prof

# Project files
*.xcodeproj
*.xcworkspace

# SQL databases
*.sqlite
*.db
*.sqlite3
EOF
      
      # Create default README
      cat > "${workspace_dir}/README.md" <<EOF
# ${context_name}

Auto-created workspace by kontext on $(date)

## Getting Started

This workspace was automatically created by kontext.

## Features

- Git repository initialized
- Default .gitignore with common patterns
- Ready for development

## Usage

1. Start coding!
2. Commit your changes: `git add . && git commit -m "Initial commit"`
3. Push to remote: `git remote add origin <your-repo-url>`
EOF
    fi
  fi
  
  __echo "workspace created at '${workspace_dir}'"

  if [ ! -z "${KONTEXT_AUTOLOAD}" ] && [ "${KONTEXT_AUTOLOAD}" -gt 0 ]; then
    kontext_load "${context_name}"
  fi
}

kontext_load() {
  [ -z "$1" ] && return 1

  kontext_unload

  # Handle nested context names (e.g., "corpex/services")
  context_name="$1"
  
  # Use new context directory structure: ~/.kontext/context/
  context_dir="${KONTEXT_HOME}/context"
  context_path="${context_dir}/${context_name}"
  
  # Check if context exists in new location
  if [ -d "${context_path}" ]; then
    export KONTEXT="${context_name}"
    export KONTEXT_PATH="${context_path}"
    __kontext_magic
    return 0
  fi
  
  # Check if context exists in old location for backward compatibility
  legacy_context_path="${KONTEXT_HOME}/${context_name}"
  if [ -d "${legacy_context_path}" ]; then
    __debug "Found context in legacy location, migrating to new structure"
    # Migrate to new structure
    mkdir -p "${context_dir}"
    mv "${legacy_context_path}" "${context_path}"
    export KONTEXT="${context_name}"
    export KONTEXT_PATH="${context_path}"
    __kontext_magic
    return 0
  fi
  
  # Auto-create context if KONTEXT_AUTOCREATE is set
  if [ ! -z "${KONTEXT_AUTOCREATE}" ] && [ "${KONTEXT_AUTOCREATE}" -gt 0 ]; then
    __echo "Auto-creating kontext '${context_name}'"
    mkdir -p "${context_path}"
    export KONTEXT="${context_name}"
    export KONTEXT_PATH="${context_path}"
    __kontext_magic
    return 0
  fi
  
  __echo "kontext '${context_name}' does not exist." >&2

  return 1
}

kontext_unload() {
  kontext_loaded || return 0
  
  kontext="${KONTEXT}"
  
  # Call unload hooks for all plugins
  __call_plugin_hooks "unload"
  
  # Run context-specific unload hooks
  if [ -d "${KONTEXT_PATH}/.hooks" ] && [ -f "${KONTEXT_PATH}/.hooks/unload.sh" ]; then
    __debug "Running unload hook from ${KONTEXT_PATH}/.hooks/unload.sh"
    . "${KONTEXT_PATH}/.hooks/unload.sh"
  fi

  # Run global unload hooks from ~/.kontext/hooks/
  if [ -d "${KONTEXT_HOME}/hooks" ]; then
    if [ -f "${KONTEXT_HOME}/hooks/unload.sh" ]; then
      __debug "Running global unload hook from ${KONTEXT_HOME}/hooks/unload.sh"
      . "${KONTEXT_HOME}/hooks/unload.sh"
    fi
  fi

  # Restore cd function if it was overridden
  if [ ! -z "${KONTEXT_CD_OVERRIDDEN}" ]; then
    __debug "Restoring original cd function"
    # Remove the cd function definition
    unset -f cd 2>/dev/null || true
    unset KONTEXT_CD_OVERRIDDEN
    unset KONTEXT_ORIGINAL_CD
  fi
  
  # Restore environment snapshot if it exists
  if [ ! -z "${KONTEXT_ENV_SNAPSHOT}" ]; then
    __debug "Restoring environment snapshot"
    # First, find variables that were added by the context and should be unset
    # Get current environment variables
    current_env="$(env | sort)"
    
    # Find variables that exist now but didn't exist in the snapshot
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        var_name="${line%%=*}"
        # Skip kontext-related variables
        if [[ "$var_name" == KONTEXT* ]] || [ "$var_name" = "PS1" ]; then
          continue
        fi
        # Check if this variable exists in the snapshot
        if ! echo "${KONTEXT_ENV_SNAPSHOT}" | grep -q "^${var_name}="; then
          __debug "Unsetting context-added variable: ${var_name}"
          unset "$var_name"
        fi
      fi
    done <<EOF
${current_env}
EOF
    
    # Restore original values from snapshot
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        # Split key=value
        key="${line%%=*}"
        value="${line#*=}"
        
        # Handle unset variables (value is empty)
        if [ -z "$value" ] && [ "$line" = "${key}=" ]; then
          unset "$key"
        else
          export "$key=""$value"""
        fi
      fi
    done <<EOF
${KONTEXT_ENV_SNAPSHOT}
EOF
    unset KONTEXT_ENV_SNAPSHOT
  fi

  export PS1="${KONTEXT_PRESERVE_PS1}"

  unset KONTEXT_PATH KONTEXT KONTEXT_PRESERVE_PS1

  __echo "kontext '${kontext}' unloaded."
}

if [ -n "$KONTEXT_CONFIG" ] && [ -f "$KONTEXT_CONFIG" ]; then
  . "$KONTEXT_CONFIG"
fi

if [ $__SOURCED -eq 0 ]; then
  kontext $@
  ret=$?
  __is_sourced && return $ret || exit $ret
fi

