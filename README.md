# Snap Pluginsync Utility

This repository contains common files synced across multiple Snap plugin repos, and tools for managing Snap plugins.

## Table of Contents
* [Installation](#installation)
* [Usage](#usage)
  * [Update Snap plugin repository](#update-snap-plugin-repository)
    * [New Plugins](#new-plugins)
    * [Private Plugins](#private-plugins)
  * [Generate travis secret](#generate-travis-secret)
  * [Update plugin metadata](#update-plugin-metadata)
* [Pluginsync Configuration](#pluginsync-configuration)
  * [Configuration Values](#configuration-values)
    * [Plugin Build Matrix](#plugin-build-matrix)
    * [\.travis\.yml](#travisyml)
    * [scripts/build\.sh](#scriptsbuildsh)
    * [scripts/deps\.sh](#scriptsdepssh)
    * [contributing\.md](#contributingmd)
  * [Special Files](#special-files)
    * [\.pluginsync\.yml](#pluginsyncyml)

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

The repository provides several Snap plugin maintenance tools:

* repo plugin sync: update repos with the latest license, testing, and travis ci configs.
* generate travis ci secret: create secret token for publishing binaries
* catalog metadata: update github plugin_catalog and snap-telemetry.io page with latest github plugin metadata.

### Update Snap plugin repository

Global updates to all repositories are typically done when there are changes to settings or templates in this repository, such as go version 1.7.3 -> 1.7.4, or updates to the contributor readme file.

To update all plugin repositories (must use the noop option for now):
```
$ bundle exec msync update --noop
$ cd modules/{plugin_name}
```

Individual plugins are updated when we add a new Snap plugin, or a plugin's `.sync.yml` configuration has been updated. For customization options review the [`.sync.yml` configuration options](#pluginsync-configuration).

Update one plugin repository (typically when that plugin's `.sync.yml` config is updated) and review changes:
```
$ bundle exec msync update -f {plugin_name} --noop
$ cd modules/{plugin_name}
```
NOTE: The plugin_name is the full repo name, such as 'snap-plugin-collector-ethtool'.

#### New Plugins

To run pluginsync against a new plugin:

* create a new repo on github (create the repo with a README or push an initial commit)
* add new plugin repo name to the list of plugins in [managed_modules.yml](./managed_modules.yml)
* run `msync update` command per usage above

#### Private Plugins

Currently, private repos are not listed in managed_modules.yml. To run pluginsync against a private repo, add the plugin repo name to managed_modules.yml but do not commit this change. In addition, please ensure you have configured ssh key or token based github access.

See github documentation for more information:

* [Generating and using a ssh key](https://help.github.com/articles/generating-an-ssh-key/)
* [Generating access token for command line usage](https://help.github.com/articles/creating-an-access-token-for-command-line-use/)

NOTE: an alternative option is to install and use the [hub cli tool](https://github.com/github/hub) which provides a convenient way to generate and save github access token.

### Generate travis secret

Generate travis secrets for .travis.yml (replace $repo_name with github repo name):
```
$ bundle exec travis encrypt ${secret_api_key} -r 'intelsdi-x/${repo_name}'
Please add the following to your .travis.yml file:

  secure: "REE..."
```

This is typically used to encrypt our s3 bucket access key so we can publish plugin binaries:

```
$ bundle exec travis encrypt S3_SECRET_ACCESS_KEY -r 'intelsdi-x/snap-plugin-publisher-file'
```

NOTE: travis secrets are encrypted per repo. see [travis documentation](https://docs.travis-ci.com/user/encryption-keys/) for more info. When migrating a repo from private to public repo, the keys need to be re-encrypted with the `--org` flag.

### Update plugin metadata

To update Snap's [plugin catalog readme](https://github.com/intelsdi-x/snap/blob/master/docs/PLUGIN_CATALOG.md) or snap-telemetry [github.io website](http://snap-telemetry.io/plugins.html):

1. Generate [github api token](https://github.com/settings/tokens) and populate [`${HOME}/.netrc` config](https://github.com/octokit/octokit.rb#using-a-netrc-file)

    ```
    machine api.github.com
      login <username>
      password <github_api_token>
    ```
    NOTE: You only need to grant public repo read permission for the API token, and use the Github API token in the password field (not your github password).

2. Fork [Snap](https://github.com/intelsdi-x/snap) repo on github and add your repo to [modulesync.yml](./modulesync.yml) in the pluginsync repo:

    ```
    plugin_catalog.md:
      fork: username/snap
    plugin_list.js:
      fork: username/snap
    ```

3. Review new catalog/wishlist/github_io (optional). The output of the catalog and wishlist is combined into the PLUGIN_CATALOG.md file in the pull request.

    ```
    $ bundle exec rake plugin:catalog
    $ bundle exec rake plugin:wishlist
    $ bundle exec rake plugin:github_io
    ```

4. Create the pull-request against the Snap repo:

    ```
    $ bundle exec rake pr:catalog
    $ bundle exec rake pr:github_io
    ```

    If there are any updates, a PR will be generated and it will go through normal review process. Otherwise the task will simply exit with no output.
    ```
    $ bundle exec rake pr:github_io
    I, [2017-01-11T13:01:32.907683 #91253]  INFO -- : Updating assets/catalog/parsed_plugin_list.js in username/snap branch pages
    I, [2017-01-11T13:01:38.154020 #91253]  INFO -- : Creating pull request: https://github.com/intelsdi-x/snap/pull/1468
    ```

## Pluginsync Configuration
Custom settings are maintained in each repo's .sync.yml file:

```
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

### Configuration Values

#### Plugin Build Matrix
Under the global settings, specify an array of build matrix using [GOOS and GOARCH](https://golang.org/doc/install/source#environment). This will generate the appropriate build script and travis config.

```
:global:
  build:
    matrix:
      - GOOS: linux
        GOARCH: amd64
      - GOOS: darwin
        GOARCH: amd64
```

#### .travis.yml
.travis.yml supports the following settings:

* sudo: enable/disable [container/VM build environment](https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments)
```
.travis.yml:
  sudo: true
```

* dist: select travis trusty VM (beta)
```
.travis.yml:
  dist: trusty
```

* addons: [custom ppa repositories and additional software packages](https://docs.travis-ci.com/user/installing-dependencies/#Installing-Packages-with-the-APT-Addon)
```
.travis.yml:
  addons:
    apt:
      packages:
        - cmake
        - libgeoip-dev
        - protobuf-compiler
```

* services: enable [docker containers](https://docs.travis-ci.com/user/docker/) and docker hub image push support
```
.travis.yml:
  services:
    - docker
```

* before_install: preinstall configs, typically environment varibles
```
.travis.yml:
  before_install:
    - LOG_LEVEL=7
```

* install: additional software to install, typically done in VM environment
```
.travis.yml:
  install:
    - 'sudo apt-get install facter'
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

* matrix.exclude: exclude specific environment combinations from the test matrix:
```
.travix.yml:
  matrix:
    exclude:
      - go: 1.6.3
        env: SNAP_VERSION=latest SNAP_OS=alpine TEST_TYPE=large
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

#### scripts/build.sh
build.sh supports the following settings:

* cgo_enabled: enable/disable CGO for builds (default: 0)
```
scripts/build.sh:
  cgo_enabled: true
```

#### scripts/deps.sh
deps.sh supports the following settings:

* packages: additional go package dependencies (please limit to test frameworks, software dependencies should be specified in godep or glide.yaml)
```
scripts/deps.sh:
  packages:
    - github.com/smartystreets/goconvey
    - github.com/stretchr/testify/mock
```

#### contributing.md
The contributing.md suports the following settings:
* maintainers: core, community, github username.

Since this may affect additional files, it's recommended to specify the setting in global:
```
:global:
  maintainer: core
```

### Special Files

#### .pluginsync.yml
.pluginsync.yml will contain the pluginsync configuration version and a list of files managed by pluginsync:

```
pluginsync_config: '0.1.0'
managed_files:
- .github
- .github/ISSUE_TEMPLATE.md
- .github/PULL_REQUEST_TEMPLATE.md
- .gitignore
- .pluginsync.yml
- .travis.yml
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
