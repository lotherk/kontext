#!/bin/sh
# Git plugin for kontext
# Provides git-related functionality

# Load hook - called when context is loaded
git_load() {
  echo "Git plugin: Load hook called"
  # You could set git config here
  # git config user.name "Your Name"
  # git config user.email "your@email.com"
}

# Main function - called when plugin is executed
git_main() {
  local subcommand="$1"
  shift
  
  case "$subcommand" in
    status)
      git_status "$@"
      ;;
    commit)
      git_commit "$@"
      ;;
    push)
      git_push "$@"
      ;;
    *)
      echo "Usage: kontext git [status|commit|push]"
      ;;
  esac
}

# Unload hook - called when context is unloaded
git_unload() {
  echo "Git plugin: Unload hook called"
  # Clean up any git-related settings
}

# Git status with context awareness
git_status() {
  local dir="$1"
  if [ -z "$dir" ]; then
    dir="."
  fi
  
  if [ -d "$dir/.git" ]; then
    echo "Git status for $(pwd):"
    git -C "$dir" status --short
  else
    echo "Not a git repository: $dir"
  fi
}

# Git commit with context awareness
git_commit() {
  local message="$1"
  if [ -z "$message" ]; then
    echo "Usage: kontext git commit <message>"
    return 1
  fi
  
  if [ -d ".git" ]; then
    git add .
    git commit -m "$message"
  else
    echo "Not a git repository"
    return 1
  fi
}

# Git push with context awareness
git_push() {
  local remote="${1:-origin}"
  local branch="${2:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"
  
  if [ -z "$branch" ]; then
    echo "Not on a git branch"
    return 1
  fi
  
  git push "$remote" "$branch"
}
