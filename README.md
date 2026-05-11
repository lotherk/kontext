# kontext - Advanced Context Management

**Version 0.99.1** - Powerful shell-based context switching with workspace management

## Installation

Download [kontext.sh](kontext.sh) and source it in your shell startup file (e.g., `.bashrc`, `.zshrc`):

```bash
source /path/to/kontext.sh
```

## Quick Start

```bash
# Create a new context
kontext create myproject

# Load the context (activates environment)
kontext load myproject

# Unload the context
kontext unload

# List all contexts
kontext list
```

## Features

### 🎯 Core Context Management
- **Environment Isolation**: Each context has its own environment variables and PATH
- **Prompt Integration**: Shows active context in shell prompt `[context-name]`
- **Nested Contexts**: Support for paths like `corpex/services`, `uberops/dev`
- **Environment Snapshots**: Prevents variable leaks when switching contexts

### 🚀 Workspace Management
- **Default Workspace**: `~/workspace/` (configurable via `KONTEXT_DEFAULT_WORKSPACE`)
- **Auto-cd**: Automatically change to workspace directory when loading context (`KONTEXT_AUTOCD=1`)
- **Git Integration**: Auto-initialize git repos with comprehensive `.gitignore`
- **Project Scaffolding**: Creates README.md and basic project structure

### 🔌 Extensibility
- **Hooks System**: `.hooks/load.sh` and `.hooks/unload.sh` for lifecycle management
- **Plugins**: Extend functionality with executable scripts in `~/.kontext/plugins/`
- **Auto-loading**: `.kontextrc` files automatically sourced when entering directories

### 🔒 Safety & Control
- **Strict Mode**: Confirm before loading `.kontextrc` files (`KONTEXT_STRICT=1`)
- **Environment Restoration**: Clean unloading with no variable leaks
- **Debug Mode**: Detailed logging with `KONTEXT_DEBUG=1`

## Configuration

Create `~/.kontext/config.sh` to set global options:

```bash
# Auto-load contexts on create
KONTEXT_AUTOLOAD=1

# Auto-change to workspace directory on load
KONTEXT_AUTOCD=1

# Auto-create missing contexts on load
KONTEXT_AUTOCREATE=1

# Auto-initialize git repositories (default: 1 if git installed)
KONTEXT_GIT=1

# Ask before loading .kontextrc files
KONTEXT_STRICT=0

# Custom workspace directory
KONTEXT_DEFAULT_WORKSPACE="${HOME}/projects"
```

## Magic Files

Kontext automatically loads these files from `$KONTEXT_PATH`:

### Context Configuration
- `env.sh`: Environment variables
- `path.sh`: PATH modifications  
- `kubeconfig.yaml`: Sets `KUBECONFIG` for Kubernetes
- `.envrc`: direnv configuration (if direnv installed)

### Hooks (in `.hooks/` directory)
- `.hooks/load.sh`: Executed when context loads
- `.hooks/unload.sh`: Executed when context unloads

### Workspace Files (auto-created)
- `.gitignore`: Comprehensive ignore patterns
- `README.md`: Project documentation template
- `.git/`: Git repository (if `KONTEXT_GIT=1`)

## .kontextrc Auto-loading

Kontext overrides the `cd` command to automatically source `.kontextrc` files:

```bash
# Create a .kontextrc file
echo 'export PROJECT_NAME="myproject"' > .kontextrc
chmod +x .kontextrc

# Load a kontext to enable auto-loading
kontext load myproject

# Now cd will auto-load .kontextrc files
cd /path/to/project  # Automatically sources .kontextrc
```

**Strict Mode**: Set `KONTEXT_STRICT=1` to confirm before loading `.kontextrc` files.

## Advanced Usage

### Nested Contexts
```bash
# Create nested context structure
kontext create corpex/services/api
kontext create corpex/services/web

# Load nested context
kontext load corpex/services/api
```

### Auto-creation
```bash
# Auto-create and load context
KONTEXT_AUTOCREATE=1 kontext load newproject
```

### Environment Management
```bash
# Set variables that persist only in this context
echo 'export API_KEY="secret"' > ~/.kontext/myproject/.hooks/load.sh
echo 'unset API_KEY' > ~/.kontext/myproject/.hooks/unload.sh
```

### Workspace Integration
```bash
# Auto-cd to workspace on load
KONTEXT_AUTOCD=1 kontext load myproject

# Access workspace path
cd $KONTEXT_DEFAULT_WORKSPACE/myproject
```

## Built-in Subcommands

| Command | Description |
|---------|-------------|
| `cd` | Change to context directory |
| `create <name>` | Create new context |
| `list` | List all contexts |
| `load <name>` | Load a context |
| `status` | Show active context |
| `unload` | Unload current context |
| `version` | Show version |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KONTEXT_HOME` | `~/.kontext` | Context storage directory |
| `KONTEXT_DEFAULT_WORKSPACE` | `~/workspace` | Project workspace directory |
| `KONTEXT_AUTOLOAD` | `0` | Auto-load on create |
| `KONTEXT_AUTOCD` | `0` | Auto-cd to workspace |
| `KONTEXT_AUTOCREATE` | `0` | Auto-create contexts |
| `KONTEXT_GIT` | `1` (if git installed) | Auto-init git repos |
| `KONTEXT_STRICT` | `0` | Confirm .kontextrc loading |
| `KONTEXT_DEBUG` | `0` | Enable debug output |

## Examples

### Project Workflow
```bash
# Create project context and workspace
kontext create my-api

# Load context (auto-cds if KONTEXT_AUTOCD=1)
kontext load my-api

# Work in the project
cd $KONTEXT_DEFAULT_WORKSPACE/my-api
npm init

# Unload when done
kontext unload
```

### Team Collaboration
```bash
# Create team context structure
kontext create acme/web-frontend
kontext create acme/api-backend
kontext create acme/mobile-app

# Each team member loads their context
kontext load acme/web-frontend
```

### Cloud Development
```bash
# Create cloud project with kubernetes config
echo 'export AWS_PROFILE="production"' > ~/.kontext/prod-aws/env.sh
cp ~/.kube/config ~/.kontext/prod-aws/kubeconfig.yaml

# Load cloud context
kontext load prod-aws
```

## Plugins

Kontext includes a powerful plugin system with lifecycle hooks. Plugins can be installed globally or per-context.

### Plugin Locations
- **Global plugins**: `~/.kontext/plugins/` - Available to all contexts
- **Context plugins**: `~/.kontext/context/<context>/.plugins/` - Available only in specific context

### Plugin Structure

Plugins are shell scripts with special functions:

```bash
#!/bin/sh
# Plugin name: example

# Load hook - called when context is loaded
example_load() {
  echo "Plugin loaded"
  export PLUGIN_VAR="value"
}

# Main function - called when plugin is executed
example_main() {
  echo "Plugin main function"
  # Your plugin logic here
}

# Unload hook - called when context is unloaded
example_unload() {
  echo "Plugin unloaded"
  unset PLUGIN_VAR
}
```

### Lifecycle Hooks

- **load()**: Called when context is loaded (before main environment setup)
- **main()**: Called when plugin is executed via `kontext plugin_name`
- **unload()**: Called when context is unloaded (after main environment teardown)

### Built-in Plugins

Kontext ships with several useful plugins:

#### Git Plugin (`git.sh`)
```bash
kontext git status      # Show git status
kontext git commit "msg" # Commit changes
kontext git push        # Push to remote
```

#### Environment Plugin (`env.sh`)
```bash
kontext env list        # List all environment variables
kontext env get VAR     # Get specific variable
kontext env set VAR val # Set variable
kontext env unset VAR   # Unset variable
```

#### Kubernetes Plugin (`kube.sh`)
```bash
kontext kube contexts   # List Kubernetes contexts
kontext kube use ctx    # Switch Kubernetes context
kontext kube config     # Show Kubernetes config
```

#### Workspace Plugin (`workspace.sh`)
```bash
kontext workspace cd     # Change to workspace directory
kontext workspace path   # Show workspace path
kontext workspace list   # List workspace contents
```

### Creating Custom Plugins

1. Create a plugin file:
   ```bash
   mkdir -p ~/.kontext/plugins
   touch ~/.kontext/plugins/mygit.sh
   chmod +x ~/.kontext/plugins/mygit.sh
   ```

2. Add plugin functions:
   ```bash
   #!/bin/sh
   mygit_load() {
     echo "Custom git plugin loaded"
   }
   
   mygit_main() {
     echo "Custom git functionality"
     git --version
   }
   
   mygit_unload() {
     echo "Custom git plugin unloaded"
   }
   ```

3. Use your plugin:
   ```bash
   kontext mygit
   ```

### Plugin Execution Flow

1. Context load → Plugin load hooks called → Main environment setup
2. Plugin execution → Plugin main function called with arguments
3. Context unload → Plugin unload hooks called → Environment cleanup

## Installation

### Quick Install

```bash
git clone https://github.com/your-repo/kontext.git
cd kontext
./install.sh
```

### Manual Install

1. Copy kontext.sh to your home directory:
   ```bash
   cp kontext.sh ~/.kontext/kontext.sh
   ```

2. Create symlink in your PATH:
   ```bash
   ln -s ~/.kontext/kontext.sh ~/.local/bin/kontext
   chmod +x ~/.kontext/kontext.sh
   ```

3. Source in your shell startup:
   ```bash
   echo 'source ~/.kontext/kontext.sh' >> ~/.bashrc
   # or for zsh:
   echo 'source ~/.kontext/kontext.sh' >> ~/.zshrc
   ```

### Installing Plugins

The install script copies default plugins to `~/.kontext/plugins/`:

```bash
# List available plugins
ls ~/.kontext/plugins/

# Use a plugin
kontext git status
kontext env list
```

## Migration from 0.1.0

### New Features
- **Workspace Management**: Contexts now create corresponding workspace directories
- **Git Auto-init**: Git repositories created automatically
- **Hooks System**: `.hooks/load.sh` and `.hooks/unload.sh` for lifecycle management
- **Environment Snapshots**: Prevents variable leaks
- **Nested Contexts**: Full support for `corpex/services` style paths
- **Auto-loading**: `.kontextrc` files automatically sourced

### Backward Compatibility
All existing functionality is preserved. Existing contexts will continue to work without modification.

## License

MIT License - Copyright (c) 2024 Konrad Lother

See the LICENSE file for full license text.
