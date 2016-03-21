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
  atpm [info|fetch|update|pin|unpin|override]
```

# Usage

## info

`atpm info` just dumps information about dependencies of a package (mainly the git URLs)

## fetch

`atpm fetch` downloads all external dependencies into `external/<pkgname>`, it does not touch already downloaded dependencies

## update

`atpm update` updates all external dependencies in `external/`, it does not download new or missing dependencies

## pin 

`atpm pin <packagename>` pin a package to a defined git commit id

## unpin

`atpm unpin <packagename>` unpin a commit id for a package

## override

`atpm override <packagename> <GIT-URL>` override the git repo URL for a package

`atpm override <packagename>` remove URL override for a package

# Configuration

To configure a dependency in a `build.atpkg` file add the following statements to the top level (just after `:name`):

```clojure
:external-packages [
    {
        :url "https://github.com/AnarchyTools/atpkg.git"
        :version [ "1.0.0" ]
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

All dependencies are handled as if you issued a `:import ["external/<pkgname>/build.atpkg"]` statement in the build file.

Example:

```clojure
(package
  :name "test"

  :externals [
    {
      :url "https://github.com/AnarchyTools/atpkg.git"
      :version [ "1.0.0" ]
    }
  ]

  :tasks {
    :default {
        :tool "atllbuild"
        :source ["src/**.swift"]
        :name "test"
        :output-type "executable"
        :link-with ["atpkg.a"]
        :dependencies ["atpkg.atpkg"]
    }
  }
)
```