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
  * [Plugin Statistics](#plugin-statistics)
  * [Large Tests](#large-tests)
    * [File Layout](#file-layout)
    * [Docker Compose](#docker-compose)
    * [Example Tasks](#example-tasks)
    * [Running Large Tests](#running-large-tests)
    * [Travis CI](#travis-ci)
    * [Serverspec](#serverspec)
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

Container:

* install docker
* start the container via the command `./pluginsync.sh`
* pluginsync commands can be executed without `bundle exec`

```
$ ./pluginsync.sh
root@660c0d4c89d3:/plugins# rake -T
rake help              # Show the list of Rake tasks (rake -T)
rake notify:slack      # send a slack notification
rake plugin:catalog    # generate plugin catalog
rake plugin:github_io  # generate plugin json for github.io page
rake plugin:metadata   # generate plugin metadata
rake plugin:stats      # generate plugin download metric from github
rake plugin:wishlist   # generate plugin wishlist
rake pr:catalog        # generate pull request for PLUGIN_CATALOG.md
rake pr:github_io      # generate pull request for plugin_metadata.jso...
root@660c0d4c89d3:/plugins# travis settings
Settings for intelsdi-x/snap-pluginsync:
[-] builds_only_with_travis_yml    Only run builds with a .travis.yml
[+] build_pushes                   Build pushes
[+] build_pull_requests            Build pull requests
  0 maximum_number_of_builds       Maximum number of concurrent builds
root@660c0d4c89d3:/plugins# msync update -f snap-plugin-processor-statistics --noop
Syncing snap-plugin-processor-statistics
Cloning repository fresh
Cloning from git@github.com:intelsdi-x/snap-plugin-processor-statistics.git
Creating new branch pluginsync
Using no-op. Files in snap-plugin-processor-statistics may be changed but will not be committed.
Files changed:
diff --git a/.pluginsync.yml b/.pluginsync.yml
...
root@660c0d4c89d3:/plugins# exit
```

MacOS:

* install [rbenv](https://github.com/rbenv/rbenv) and ruby 2.3.1
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

* use [bundler](https://bundler.io/) to install msync dependencies:
```
$ gem install bundler
$ bundle config path .bundle
$ bundle install
```

## Usage

The repository provides several Snap plugin maintenance tools:

* repo plugin sync: update repos with the latest license, testing, and travis ci configs.
* update travis ci environment secret: update secret token for publishing binaries to s3 and github.
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

### Update travis secrets

We currently use the following three secret environment variables to deploy binary artifacts:
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY
* GITHUB_API_KEY

List repository secret environment variables:
```
$ travis env list -r intelsdi-x/snap-plugin-publisher-influxdb
# environment variables for intelsdi-x/snap-plugin-publisher-influxdb
GITHUB_API_KEY=[secure]
AWS_ACCESS_KEY_ID=[secure]
AWS_SECRET_ACCESS_KEY=[secure]
```

Set repository environment secrets
```
$ travis env -r intelsdi-x/reponame set GITHUB_API_KEY ...
```

NOTE: travis secrets are encrypted per repo. see [travis documentation](https://docs.travis-ci.com/user/encryption-keys/) for more info. When migrating a repo from private to public repo, the keys may need to be re-encrypted with the `--org` flag.

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

### Plugin Statistics

To obtain plugin download metrics:

1. Generate [github api token](https://github.com/settings/tokens) and populate [`${HOME}/.netrc` config](https://github.com/octokit/octokit.rb#using-a-netrc-file)

    ```
    machine api.github.com
      login <username>
      password <github_api_token>
    ```
    NOTE: You only need to grant public repo read permission for the API token, and use the Github API token in the password field (not your github password).

2. Run the `plugin:stats` rake task:

    ```
    $ bundle exec rake plugin:stats
    ---
    - intelsdi-x/snap-plugin-publisher-file:
        clones:
          count: 1187
          uniques: 131
        views:
          count: 78
          uniques: 30
        '2':
          snap-plugin-publisher-file_darwin_x86_64: 57
          snap-plugin-publisher-file_linux_x86_64: 1869
        v1.0.0:
          snap-plugin-publisher-file_darwin: 0
          snap-plugin-publisher-file_linux: 4
        total: 1930
    ...
    ```

### Large Tests

Running large tests require the following software on your development systems:

* docker
* docker-compose

The default large test performs the following actions:

* use environment variable to populate docker compose specification in: `scripts/test/docker_compose.yml`
* download the latest containers via `docker pull` and run them
* conditionally run `scripts/test/setup.rb` before any test (use this to create test database, test service etc)
* download and run the appropriate version of Snap per `$SNAP_VERSION`
* scan `examples/task/*.yml` for list of tasks and metrics
* load Snap plugins, first from the local `build/linux/x86_64/*` directory, then try `build.snap-telemetry.io` s3 bucket
* verify plugins are loaded successfully
* attempt to create, verify, and stop every yaml task in the examples directory.
* shutdown and cleanup containers

If this is not the appropriate behavior, you can write custom large test as `{test_name}_spec.rb` in the `scripts/test` directory.

#### File Layout

Pluginsync adds several files to support large test framework. Files names surrounded by {} are not created by pluginsync. Please review the comments to see how each file affects the large tests framework.

```
├── build
│   └── linux
│       └── x86_64                         # plugins missing from this directory will be fetched from s3
│           ├── {snap-plugin-plugin_name}  # make will build the current plugin for testing
│           └── {snap-plugin-custom_name}  # custom plugins can be copied here to take precedence over s3 binaries
├── examples
│   └── tasks
│       ├── {example.json}                 # json tasks are ignored and serve purely as examples
│       └── {example.yml}                  # yaml tasks are loaded and verified in the test framework
└── scripts
    ├── large.sh
    └── test
        ├── {docker-compose.yml}           # to be supplied by the developer
        ├── large_spec.rb                  # default large test, can be disabled by setting the file to `unmanaged`
        ├── {custom_spec.rb}               # additional spec tests can be written to compliment the default large test
        ├── {setup.rb}                     # optional setup executed before running large test
        ├── {verify.rb}                    # optional verify executed after running large test
        └── spec_helper.rb
```

#### Docker Compose

A default `docker_compose.yml` file should be supplied by the developer and placed in `./scripts/test` directory. This will be used by the default large spec test. Additional docker compose config files can be supplied for complex test scenarios and they require their own custom_spec.rb test.

Currently these environment variables are passed to the Snap container (we are investigating ways to pass additional/arbitrary ENV variable values):
* OS: any os available in [snap-docker repo](https://github.com/intelsdi-x/snap-docker) (default: alpine)
* SNAP_VERSION: any Snap version, or git sha1 that's available in the s3 bucket (default: latest)
* PLUGIN_PATH: used by large test framework, this must be included in the Snap container

Single container:
```
version: '2'
services:
   snap:                              # NOTE: do not change the snap container name
    image: intelsdi/snap:${OS}_test
    environment:
      SNAP_VERSION: "${SNAP_VERSION}"
    volumes:
      - "${PLUGIN_PATH}:/plugin"
```

Multiple container:
```
version: '2'
services:
  snap:                                 # NOTE: do not change the snap container name
    image: intelsdi/snap:alpine_test    # OS can be locked down to a specific version
    environment:
      SNAP_VERSION: "${SNAP_VERSION}"
      INFLUXDB_HOST: "${INFLUXDB_HOST}" # Custom environment variables require updates to large.sh
    volumes:
      - "${PLUGIN_PATH}:/plugin"
    links:
      - influxdb
  influxdb:
    image: influxdb:1.0
    expose:
      - "8083"
      - "8086"
```

#### Example Tasks

The default `large_spec.rb` test will verify all yaml example tasks in the plugin's `examples/task` folder. The large test ignores json tasks, so they can be used as examples to demonstrate features that are not tested. There are no restrictions when you write custom tests, and here's some recommendations:

* examples tasks _must_ set `max-failures: 1` because we only check if a task is in running state, higher max-failures values will mask failures since it takes multiple collect attempts to toggle the task to disabled state.
* avoid using mock plugins whenever possible
* when mock plugins are required, download the appropriate binary in the build directory (mock vs. mock2)
* use a fixtures directory to simulate the content of the `/proc` directory instead of depending on the test system
* use environment variables in task manifest instead of ipaddresses (such as `"${INFLUXDB_HOST}"`) and pass setting via `docker-compose.yml`

#### Running Large Tests

When the previous steps have been completed, you can verify the large tests works locally by executing:
```
$ make test-large
```

Custom environment variables can be supplied such as:
```
OS=trusty SNAP_VERSION=1.0.0 make test-large
```

A subset of tasks can be selected for testing via the TASK environment variable:
```
TASK="psutil*.yml" make test-large
```

To troubleshoot a failing large test, enable the debug flag:
```
DEBUG=true make test-large
```

When the test encounters any failures in debug mode, it will be paused at a [pry session](http://pryrepl.org/). The test containers will remain running and available for further examination. When the problem has been identified, simply `exit` the debug session to resume testing, or use `exit-program` to quit immediately.

To spin up the environment in demo mode and pause after loading the first task:
```
DEMO=true make test-large
```

A specific task can be selected for usage in demo mode:
```
DEMO=true TASK="psutil-file.yml" make test-large
```

When you are done checking out the containers, simply type `exit-program`.

NOTE: some useful commands once the containers are running in debug or demo mode:
* login to Snap container:
    ```
$ docker exec -it $(docker ps | sed -n 's/\(\)\s*intelsdi\/snap.*/\1/p') /bin/bash
bash-4.3# snaptel --version
snaptel version test-f2f7c09
    ```
* view Snap daemon log:
    ```
$ docker logs $(docker ps | sed -n 's/\(\)\s*intelsdi\/snap.*/\1/p')
    ```

#### Travis CI

To enable large tests on Travis CI, please enable sudo, docker, and add the appropriate test matrix settings in `.sync.yml`:
```
.travis.yml:
  sudo: true # large tests require travis.ci VMs instead of containers (enabled via sudo: true)
  services:  # this ensures docker/docker-compose is installed on the travis agent
    - docker
  env:
    global:  # If you change the matrix, please preserve environment globals:
      - ORG_PATH=/home/travis/gopath/src/github.com/intelsdi-x
      - SNAP_PLUGIN_SOURCE=/home/travis/gopath/src/github.com/${TRAVIS_REPO_SLUG}
    matrix:
      - TEST_TYPE: small             # preserve existing small tests
      - TEST_TYPE: medium            # preserve existing medium tests (make sure they exist)
      # if SNAP_VERSION:latest and OS:alpine is sufficient simply add TEST_TYPE: large
      - TEST_TYPE: large
      # if multiple SNAP_VERSION, OS needs to be tested, provide an array of versions:
      - SNAP_VERSION=latest OS=xenial TEST_TYPE=large
      - SNAP_VERSION=latest_build OS=centos7 TEST_TYPE=large
  matrix:
    # travis doesn't have an easy way to exclude large tests with a regex, so
    # please list every large test to exclude it from running on go 1.6.x
    exclude:
      - go: 1.6.x
        env: TEST_TYPE=large
      - go: 1.6.x
        env: SNAP_VERSION=latest OS=xenial TEST_TYPE=large
      - go: 1.6.x
        env: SNAP_VERSION=latest_build OS=centos7 TEST_TYPE=large
```

NOTE: If you did not set `sudo: true` and enable docker services, in travis.ci large test will fail with the following error:
```
2017-02-06 23:00:35 UTC [    error] docker needs to be installed
```

#### Serverspec

The large tests are written using [serverspec](http://serverspec.org/) as the system test framework. An example installing and testing `ping`:

```
set :docker_compose_container, :snap                       # required if you use the os["family"] detection functionality

context "network is functional" do
  if os["family"] == "ubuntu"
    describe package("iputils-ping") do
      it { should be_installed }
    end
  elsif os["family"] == "redhat"
    describe package("iputils") do
      it { should be_installed }
    end
  end

  describe command('ping -c1 8.8.8.8') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain(/1 packets received/) }
  end
end
```

If you have more than one container specified in docker compose, tests can be executed in each container separately:
```
describe docker_compose('./docker_compose.yml') do
  its_container(:snap) do
    # these tests would only run in the snap container
  end

  its_container(:influxdb) do
    # these tests would only run in the influxdb container
  end
end
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

One special environment variable is `NO_GO_TEST`. By default we filter out the following directory from testing:
* .* or \_* hidden directories
* Godeps or vendor directories

There may be reasons to exclude other directories or have custom exclusions, and it can be configured by specifying this environment variable:
```
.travis.yml:
  env:
    global:
      - GO15VENDOREXPERIMENT=1
      - NO_GO_TEST='-not -path "./.*" -not -path "*/_*" -not -path "./Godeps/*" -not -path "./vendor/*" -not -path "./custom_dir/*"'
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
