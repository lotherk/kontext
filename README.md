# kontext.sh

## Installation

Download [kontext.sh](kontext.sh) and source it in your shell startup file (e.g., `.bashrc`, `.zshrc`).

```bash
source /path/to/kontext.sh
```

## help
```
$ kontext -h
kontext 0.1.0, copyright 2014 Konrad Lother <konrad@lother.io>

  options:
    -D          - enable debug
    -c name     - set kontext to name
    -h          - print this help

available subcommands
    cd
    create
    list
    load
    status
    unload
    version

See kontext <subcommand> -h for additional informations

Usage: kontext [options] [subcommand] [subcommand_options] args...
```

## Configuration

Create `~/.kontext/config.sh` to set global options. For example:
```bash
KONTEXT_AUTOLOAD=1  # Auto-load contexts on create
```

## Magic

Kontext automatically configures your environment when loading a context. It sources these files if they exist in `$KONTEXT_PATH`:
- `env.sh`: General environment variables
- `path.sh`: PATH modifications
- `kubeconfig.yaml`: Sets `KUBECONFIG`

If [direnv](https://direnv.net/) is installed, it will allow `.envrc` files for automatic environment loading.

It also updates your shell prompt to show the active context.

## Plugins

You can extend kontext's functionality with plugins. Plugins are executable scripts placed in `~/.kontext/plugins/`. The script name becomes the subcommand.

For example, create `~/.kontext/plugins/myplug` with:
```bash
#!/bin/sh
echo 'this is my plugin' "$@"
```

Then run:
```
$ kontext myplug 1 2 3
this is my plugin 1 2 3
```

Plugins can also be shell functions defined in your shell startup, following the naming convention `kontext-YOURPLUGIN`.

### Built-in subcommands

| name | description |
| ---- | ----------- |
| cd | change directory to `$KONTEXT_PATH`
| create | create a new kontext directory
| list | print a list of available kontexts
| load | load a kontext (sets environment and path)
| status | show current kontext status
| unload | unload the current kontext
| version | print kontext.sh version
