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

if [ -z $KONTEXT_HOME ]; then
  export KONTEXT_HOME="${HOME}/.kontext"
fi

if [ -z $KONTEXT_CONFIG ] && [ -r "${KONTEXT_HOME}/.config" ]; then
  export KONTEXT_CONFIG="${KONTEXT_HOME}/.config"
fi

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
  local subcommands=""

  # check all functions
  for f in $(declare -f |grep -Eo '^kontext-\w+' | sed 's/kontext-//'); do
    subcommands="${subcommands} $f"
  done

  # check all aliases
  for f in $(alias |grep -Eo '^kontext-\w+' | sed 's/kontext-//'); do
    subcommands="${subcommands} $f"
  done

  echo $subcommands
}

# applies magic upon kontext load
__kontext_magic() {
  if [ -f "${KONTEXT_PATH}/env.sh" ]; then
    __debug "Loading env.sh"
    source "${KONTEXT_PATH}/env.sh"
  fi

  if [ -f "$KONTEXT_PATH/kubeconfig.yaml" ]; then
    __debug "Loading kubeconfig.yaml"
    export KUBECONFIG="${KONTEXT_PATH}/kubeconfig.yaml"
  fi

  export KONTEXT_PRESERVE_PS1="${PS1}"
  export PS1="[$KONTEXT] $PS1"
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

  local cmd=$1
  shift

  # check if $1 exists as kontext-$1 function
  type "kontext-${cmd}" 2>&1 > /dev/null
  if [ $? -eq 0 ]; then
    "kontext-${cmd}" $@
  else
    echo "${0}: unknown subcommand '${cmd}', try ${0} -h for help" > /dev/stderr
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

kontext-create() {
  local dest="${KONTEXT_HOME}/${1}"
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

  local kontext="${KONTEXT}"

  export PS1="${KONTEXT_PRESERVE_PS1}"

  unset KONTEXT_PATH KONTEXT KONTEXT_PRESERVE_PS1

  __echo "kontext '${kontext}' unloaded."
}

if [ ! -z "$KONTEXT_CONFIG" ]; then
  if [ -f "$KONTEXT_CONFIG" ]; then
    source "$KONTEXT_CONFIG"
  fi
fi

if [ $__SOURCED -eq 0 ]; then
  kontext $@
  ret=$?
  __is_sourced && return $ret || exit $ret
fi

