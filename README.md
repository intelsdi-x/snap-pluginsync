# Snap Pluginsync Utility

This repository contains common files synced across multiple snap plugin repos.

## Installation

MacOS:

```
$ brew install rbenv
$ rbenv install 2.3.1
$ git clone https://github.com/intelsdi-x/snap-pluginsync
$ cd snap-pluginsync
$ rbenv local 2.3.1
$ gem install bundler
$ bundle config path .bundle
$ bundle install
```

## Usage

Update one plugin and review changes:

```
$ bundle exec msync update -f {plugin_name} --noop
$ cd modules/{plugin_name}
```
