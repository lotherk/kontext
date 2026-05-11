#!/bin/sh
# Kubernetes plugin for kontext
# Manages Kubernetes contexts and configurations

# Load hook - called when context is loaded
kube_load() {
  echo "Kubernetes plugin: Load hook called"
  
  # Check if kubeconfig exists for this context
  if [ -f "${KONTEXT_PATH}/kubeconfig.yaml" ]; then
    export KUBECONFIG="${KONTEXT_PATH}/kubeconfig.yaml"
    echo "Set KUBECONFIG to ${KONTEXT_PATH}/kubeconfig.yaml"
  fi
}

# Main function - called when plugin is executed
kube_main() {
  local subcommand="$1"
  shift
  
  case "$subcommand" in
    contexts|ctx)
      kube_contexts "$@"
      ;;
    use|switch)
      kube_use "$@"
      ;;
    config)
      kube_config "$@"
      ;;
    *)
      echo "Usage: kontext kube [contexts|use|config] [args...]"
      ;;
  esac
}

# Unload hook - called when context is unloaded
kube_unload() {
  echo "Kubernetes plugin: Unload hook called"
  # Don't unset KUBECONFIG here as it might be set by the main kontext magic
}

# List Kubernetes contexts
kube_contexts() {
  if command -v kubectl >/dev/null 2>&1; then
    kubectl config get-contexts
  else
    echo "kubectl not found. Please install Kubernetes CLI."
    return 1
  fi
}

# Switch Kubernetes context
kube_use() {
  local context="$1"
  
  if [ -z "$context" ]; then
    echo "Usage: kontext kube use <context>"
    return 1
  fi
  
  if command -v kubectl >/dev/null 2>&1; then
    kubectl config use-context "$context"
  else
    echo "kubectl not found. Please install Kubernetes CLI."
    return 1
  fi
}

# Show Kubernetes configuration
kube_config() {
  if command -v kubectl >/dev/null 2>&1; then
    kubectl config view
  else
    echo "kubectl not found. Please install Kubernetes CLI."
    return 1
  fi
}
