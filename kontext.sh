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

KONTEXT_VERSION='0.1.0'

if [ -z "$KONTEXT_HOME" ]; then
  KONTEXT_HOME="${HOME}/.kontext"
  export KONTEXT_HOME
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

if [ -z $KONTEXT_HOME ]; then
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
    echo "[$KONTEXT]"
  fi
}

__kontext_list_subcommands() {
  subcommands="$__KONTEXT_BUILTINS"

  # Check for plugin executables in plugins directory
  if [ -d "${KONTEXT_HOME}/plugins" ]; then
    for f in "${KONTEXT_HOME}/plugins"/*; do
      if [ -x "$f" ] && [ -f "$f" ]; then
        subcommands="${subcommands} $(basename "$f")"
      fi
    done
  fi

  echo $subcommands
}

# applies magic upon kontext load
__kontext_magic() {
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

  KONTEXT_PRESERVE_PS1="$PS1"
  export KONTEXT_PRESERVE_PS1
  PS1="[$KONTEXT] $PS1"
  export PS1
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
  if type "kontext-${cmd}" 2>/dev/null; then
    "kontext-${cmd}" "$@"
  # Check if $cmd is a plugin executable
  elif [ -x "${KONTEXT_HOME}/plugins/${cmd}" ]; then
    "${KONTEXT_HOME}/plugins/${cmd}" "$@"
  else
    echo "${0}: unknown subcommand '${cmd}', try ${0} -h for help" >/dev/stderr
    return 1
  fi

}
kontext_loaded() {
  if [ -z $KONTEXT ]; then
    return 1
  else
    return 0
  fi
}


kontext-cd() {
  kontext_loaded || return 1

  echo "${KONTEXT_PATH}"
  cd "${KONTEXT_PATH}"
}

kontext-list() {
  ls -1 "${KONTEXT_HOME}"
}
alias kontext-ls=kontext-list

kontext-version() {
  __echo 'kontext '$KONTEXT_VERSION' (c) 2024 Konrad Lother'
}

kontext-status() {
  if kontext_loaded; then
    __echo "Active kontext: $KONTEXT"
    __echo "Path: $KONTEXT_PATH"
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

kontext-create() {
  dest="${KONTEXT_HOME}/${1}"
  if [ ! -e "${dest}" ]; then
    mkdir -p "${dest}"
  fi
  __echo "kontext created at '${dest}'"

  if [ ! -z $KONTEXT_AUTOLOAD ] && [ $KONTEXT_AUTOLOAD -gt 0 ]; then
    kontext-load "${1}"
  fi
}

kontext-load() {
  [ -z $1 ] && return 1

  kontext-unload

  if [ -d "${KONTEXT_HOME}/${1}" ]; then
    export KONTEXT="$1"
    export KONTEXT_PATH="${KONTEXT_HOME}/${1}"
    __kontext_magic
    return 0
  fi
  __echo "kontext '${1}' does not exist." >> /dev/stderr

  if [ -r "${KONTEXT_HOME}/.env" ]; then
    source "${KONTEXT_HOME}/.env"
  fi

  return 1
}

kontext-unload() {
  kontext_loaded || return 0

  kontext="${KONTEXT}"

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

