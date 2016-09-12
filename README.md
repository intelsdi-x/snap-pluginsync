# Snap Pluginsync Utility

This repository contains common files synced across multiple snap plugin repos.

## Installation

MacOS:

* install rbenv and ruby 2.3.1
```
$ brew install rbenv
$ rbenv install 2.3.1
```

* ensure rbenv is in your shell startup

    `rbenv init` will recommend the appropriate file for your shell:
```
$ rbenv init
# Load rbenv automatically by appending
# the following to ~/.zshrc:
eval "$(rbenv init -)"
```

* clone repo, initialize local ruby version:
```
$ git clone https://github.com/intelsdi-x/snap-pluginsync
$ cd snap-pluginsync
$ rbenv local 2.3.1
```

* use bundler to install msync dependencies:
```
$ gem install bundler
$ bundle config path .bundle
$ bundle install
```

For more info see:
* [rbenv](https://github.com/rbenv/rbenv)
* [bundler](https://bundler.io/)

## Usage

Update one plugin and review changes:
```
$ bundle exec msync update -f {plugin_name} --noop
$ cd modules/{plugin_name}
```

Generate travis secrets for .travis.yml (replace $repo_name with github repo name):
```
$ bundle exec travis encrypt secret_api_key -r 'intelsdi-x/${repo_name}'
Please add the following to your .travis.yml file:

  secure: "REE..."
```

NOTE: travis secrets are encrypted per repo. see [travis documentation](https://docs.travis-ci.com/user/encryption-keys/) for more info.

## Pluginsync Configuration

Custom settings are maintained in each repo's .sync.yml file:

```
---
:global:
  build:
    matrix:
      - GOOS: linux
        GOARCH: amd64
.travis.yml:
  deploy:
    access_key_id: AKIAINMB43VSSPFZISAA
...
```

The settings are broken down into two sections:

* :global: this hash specifies settings that will be merged with all file settings.
* {file_name}: this hash specifies settings that will be applicable to a specific file template

There are two special hash keys for each file/directory:

* unmanaged: do not update the existing file/directory
```
README.md:
  unmanaged: true
```

* delete: remove the file/directory from the repository
```
.glide.lock
  delete: true
```

## Configuration Values

### Plugin Build Matrix

Under the global settings, specify an array of build matrix using [GOOS and GOARCH](https://golang.org/doc/install/source#environment). This will generate the appropriate build script and travis config.

```
---
:global:
  build:
    matrix:
      - GOOS: linux
        GOARCH: amd64
      - GOOS: darwin
        GOARCH: amd64
```

### .travis.yml

.travis.yml supports the following settings:

* addons: for installing additional software packages
```
.travis.yml:
  addons:
    apt:
      packages:
        - cmake
        - libgeoip-dev
        - protobuf-compiler
```

* env: global environment values and test matrix, i.e. small/medium/large (NOTE: build is always included)
```
.travis.yml:
  env:
    global:
      - GO15VENDOREXPERIMENT=1
    matrix:
      - TEST_TYPE=small
      - TEST_TYPE=medium
      - TEST_TYPE=large
```

* deploy: deployment github/s3 token (encrypted via travis cli):
```
.travis.yml:
  deploy:
    access_key_id: AKIAINMB43VSSPFZISAA
    secret_access_key:
      secure: ...
    api_key:
      secure: ...
```

NOTE: Be aware, custom settings are not merged with defaults, instead they replace the default values.

### contributing.md

The contributing.md suports the following settings:
* maintainers: core, community (defaults to community).

Since this may affect additional files, it's recommended to specify the setting in global:
```
:global:
  maintainers: core
```

## Special Files

### .pluginsync.yml

.pluginsync.yml will contain the pluginsync configuration version and a list of files managed by pluginsync:

```
pluginsync_config: '0.1.0'
managed_files:
- ".github"
- ".github/ISSUE_TEMPLATE.md"
- ".github/PULL_REQUEST_TEMPLATE.md"
- ".gitignore"
- ".pluginsync.yml"
- ".travis.yml"
- CONTRIBUTING.md
- LICENSE
- Makefile
- scripts
- scripts/build.sh
- scripts/common.sh
- scripts/deps.sh
- scripts/pre_deploy.sh
- scripts/test.sh
```
