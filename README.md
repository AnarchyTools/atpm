# atpm

The Anarchy Tools Package Manager.

# Building

To build atpm "from scratch", simply `./bootstrap/build.sh`.

Then you can check the program was built successfully:

```bash
$ ./atpm --help
atpm - Anarchy Tools Package Manager 1.0.0-GM1
https://github.com/AnarchyTools
© 2016 Anarchy Tools Contributors.

Usage: atpm [command]

    info
        show information for all package dependencies

    fetch
        fetch new packages, does not touch already fetched packages

    update
        update already fetched packages (if they are not pinned)

    pin <package-name>
        pin current package status of <package-name> and record in lock file

    unpin <package-name>
        unpin status of <package-name>

    override <package-name> <new-url>
        override git url of <package-name> to <new-url>

    restore <package-name>
        remove git url override of <package-name>

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

## restore

`atpm restore <packagename>` remove URL override for a package

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

  :external-packages [
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
