#!/bin/bash
# kontext installation script

set -e

# Default installation directory
INSTALL_DIR="${HOME}/.kontext"
BIN_DIR="${HOME}/.local/bin"

# Create directories
echo "Creating kontext directories..."
mkdir -p "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}/context"
mkdir -p "${INSTALL_DIR}/plugins"
mkdir -p "${INSTALL_DIR}/hooks"
mkdir -p "${BIN_DIR}"

# Copy kontext script
echo "Installing kontext script..."
cp "$(dirname "$0")/kontext.sh" "${INSTALL_DIR}/kontext.sh"
ln -sf "${INSTALL_DIR}/kontext.sh" "${BIN_DIR}/kontext"
chmod +x "${INSTALL_DIR}/kontext.sh"
chmod +x "${BIN_DIR}/kontext"

# Install default plugins
echo "Installing default plugins..."
if [ -d "$(dirname "$0")/plugins" ]; then
  cp "$(dirname "$0")/plugins/"* "${INSTALL_DIR}/plugins/"
  chmod +x "${INSTALL_DIR}/plugins/"*.sh
fi

# Create default workspace
echo "Creating default workspace..."
WORKSPACE_DIR="${HOME}/workspace"
if [ ! -d "${WORKSPACE_DIR}" ]; then
  mkdir -p "${WORKSPACE_DIR}"
  echo "Created workspace directory: ${WORKSPACE_DIR}"
fi

# Create sample configuration
echo "Creating sample configuration..."
cat > "${INSTALL_DIR}/config.sh" << 'CONFIG'
# kontext configuration
# Set KONTEXT_AUTOLOAD=1 to automatically load contexts on creation
# KONTEXT_AUTOLOAD=1

# Set KONTEXT_AUTOCD=1 to automatically cd to workspace on context load
# KONTEXT_AUTOCD=1

# Set KONTEXT_AUTOCREATE=1 to automatically create contexts on load
# KONTEXT_AUTOCREATE=1

# Set KONTEXT_GIT=1 to automatically initialize git repositories (default: 1 if git installed)
# KONTEXT_GIT=1

# Set KONTEXT_STRICT=1 to ask before loading .kontextrc files
# KONTEXT_STRICT=0

# Custom workspace directory
# KONTEXT_DEFAULT_WORKSPACE="${HOME}/projects"
CONFIG

# Add to shell configuration
echo ""
echo "Installation complete!"
echo ""
echo "To use kontext, add this to your shell configuration file (e.g., ~/.bashrc, ~/.zshrc):"
echo "  source ${INSTALL_DIR}/kontext.sh"
echo ""
echo "Or symlink it to a directory in your PATH:"
echo "  ln -s ${INSTALL_DIR}/kontext.sh /usr/local/bin/kontext"
echo ""
echo "Try it out:"
echo "  kontext create myproject"
echo "  kontext load myproject"
echo "  kontext list"
