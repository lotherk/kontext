# kontext.sh

## Installation

Download [kontext.sh](kontext.sh) and source it.

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
    unload
    version

See kontext <subcommand> -h for additional informations

Usage: kontext [options] [subcommand] [subcommand_options] args...
```

## Magic

`kontext` knows magic. for example it can set `KUBECONFIG` if it finds a `kubeconfig.yaml` file in `$KONTEXT_PATH`.

## Plugins

you can extend `kontext`s functionallity with plugins. a plugin is a shell function or executable found in `$PATH` that follows the naming convention `kontext-YOURPLUGIN`.

for example:
```
kontext-myplug() {
    echo 'this is my plugin' $@
}
```

becomes

```
$ kontext myplug 1 2 3
this is my plugin 1 2 3
```

### Built-in plugins

| name | description |
| ---- | ----------- |
| cd | change directory to `$KONTEXT_PATH`
| list | print a list of kontexts
| create | create a kontext
| load | load a kontext, only useful if `kontext.sh` is sourced
| unload | unload a kontext, only useful if `kontext.sh` is sourced
| version | print kontext.sh version
