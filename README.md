# atpm

The Anarchy Tools Package Manager.

# Building

To build atpm "from scratch", simply `./bootstrap/build.sh`.

Then you can check the program was built successfully:

```bash
$ ./atpm --help
atpm - Anarchy Tools Package Manager 0.1.0-dev
https://github.com/AnarchyTools
© 2016 Anarchy Tools Contributors.

Usage:
atpm [task]
    task: ["info", "fetch", "update", "add", "install", "uninstall"]
```

# Usage

## info

`atpm info` just dumps information about dependencies of a package (mainly the git URLs)

## fetch

`atpm fetch` downloads all external dependencies into `external/<pkgname>`, it does not touch already downloaded dependencies

## update

`atpm update` updates all external dependencies in `external/`, it does not download new or missing dependencies

## add (not implemented yet)

`atpm add <GIT-URL>` dumps information about how to add the external dependency that can be found at `<GIT-URL>`

## install (not implemented yet)

`atpm install <GIT-URL>` fetches and compiles the package from `<GIT-URL>` into `install/`

Add parameter `--destination <dest>` after the URL to install to another directory

## uninstall (non implemented yet)

`atpm install <GIT-URL>` fetches the package from `<GIT-URL>` and removes all files the package installed

Add parameter `--destination <dest>` after the URL to specify a different destination directory (see install above)

# Configuration

To configure a dependency in a `build.atpkg` file add the following statements to the top level (just after `:name`):

```clojure
:externals [
    {
        :url "https://github.com/AnarchyTools/atpkg.git"
        :branch "master"
    }
]
```

- `:url` is required and a valid URL to a git repository
- `:branch` is optional and defines which branch to check out
- `:tag` is optional and defines which git tag to check out
- `:commit` defines a commit id
- `:version` defines a version, use a vector like `["<1.3" ">=1.2"]`

You need one of `:branch`, `:tag`, `:commit` or `:version`

# Usage in `build.atpkg`

All dependencies are handled as if you issued a `:import ["externals/<pkgname>/build.atpkg"]` statement in the build file.

Example:

```clojure
(package
  :name "test"

  :externals [
    {
      :url "https://github.com/AnarchyTools/atpkg.git"
      :branch "master"
    }
  ]

  :tasks {
    :default {
        :tool "atllbuild"
        :source ["src/**.swift"]
        :name "test"
        :outputType "executable"
        :linkWithProduct ["atpkg.a"]
        :dependencies ["atpkg.atpkg"]
    }
  }
)
```