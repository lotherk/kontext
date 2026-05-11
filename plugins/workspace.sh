#!/bin/sh
# Workspace plugin for kontext
# Manages workspace directories

# Load hook - called when context is loaded
workspace_load() {
  echo "Workspace plugin: Load hook called"
  
  # Auto-cd to workspace if enabled
  if [ ! -z "${KONTEXT_AUTOCD}" ] && [ "${KONTEXT_AUTOCD}" -gt 0 ]; then
    local workspace_dir="${KONTEXT_DEFAULT_WORKSPACE}/${KONTEXT}"
    if [ -d "$workspace_dir" ]; then
      echo "Auto-changing to workspace: $workspace_dir"
      builtin cd "$workspace_dir"
    fi
  fi
}

# Main function - called when plugin is executed
workspace_main() {
  local subcommand="$1"
  shift
  
  case "$subcommand" in
    cd|open)
      workspace_cd "$@"
      ;;
    create)
      workspace_create "$@"
      ;;
    list|ls)
      workspace_list "$@"
      ;;
    path)
      workspace_path "$@"
      ;;
    *)
      echo "Usage: kontext workspace [cd|create|list|path] [args...]"
      ;;
  esac
}

# Unload hook - called when context is unloaded
workspace_unload() {
  echo "Workspace plugin: Unload hook called"
}

# Change to workspace directory
workspace_cd() {
  local workspace_dir="${KONTEXT_DEFAULT_WORKSPACE}/${KONTEXT}"
  
  if [ ! -d "$workspace_dir" ]; then
    echo "Workspace directory does not exist: $workspace_dir"
    return 1
  fi
  
  echo "Changing to workspace: $workspace_dir"
  builtin cd "$workspace_dir"
}

# Create workspace directory
workspace_create() {
  local workspace_dir="${KONTEXT_DEFAULT_WORKSPACE}/${KONTEXT}"
  
  if [ -e "$workspace_dir" ]; then
    echo "Workspace already exists: $workspace_dir"
    return 0
  fi
  
  echo "Creating workspace: $workspace_dir"
  mkdir -p "$workspace_dir"
  
  # Initialize git if enabled
  if [ ! -z "${KONTEXT_GIT}" ] && [ "${KONTEXT_GIT}" -gt 0 ]; then
    if command -v git >/dev/null 2>&1; then
      echo "Initializing git repository"
      git init "$workspace_dir" >/dev/null 2>&1
      
      # Create default files
      cat > "${workspace_dir}/.gitignore" <<'GITIGNORE'
.DS_Store
*.swp
node_modules/
GITIGNORE
      
      cat > "${workspace_dir}/README.md" <<README
# ${KONTEXT} Workspace

Created by kontext workspace plugin
README
    fi
  fi
}

# List workspace contents
workspace_list() {
  local workspace_dir="${KONTEXT_DEFAULT_WORKSPACE}/${KONTEXT}"
  
  if [ ! -d "$workspace_dir" ]; then
    echo "Workspace directory does not exist: $workspace_dir"
    return 1
  fi
  
  echo "Contents of workspace ${KONTEXT}:"
  ls -la "$workspace_dir"
}

# Show workspace path
workspace_path() {
  echo "${KONTEXT_DEFAULT_WORKSPACE}/${KONTEXT}"
}
