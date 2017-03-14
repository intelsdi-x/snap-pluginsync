# NOTE: Using rake instead of writing a shell script because Ruby seems
# unavoidable between FPM and homebrew.

require "rake"
require_relative "lib/pluginsync"

begin
  require "pry"
rescue LoadError
end

desc "Show the list of Rake tasks (rake -T)"
task :help do
  sh "rake -T"
  puts "rake tasks may take several minutes to complete"
end
task :default => :help

namespace :plugin do
  desc "generate plugin catalog"
  task :catalog do
    puts "Collecting plugin catalog ..."
    puts Pluginsync::Plugins.catalog
  end

  desc "generate plugin catalog diff"
  task :diff do
    puts "Collecting github repo info ..."
    puts Pluginsync::Plugins.diff
  end

  desc "generate plugin metadata"
  task :metadata do
    puts "Collecting plugin metadata ..."
    puts JSON.pretty_generate Pluginsync::Plugins.metadata
  end

  desc "generate plugin wishlist"
  task :wishlist do
    puts Pluginsync::Plugins.wishlist
  end

  desc "generate plugin json for github.io page"
  task :github_io do
    puts "Collecting plugin data ..."
    puts Pluginsync::Plugins.githubio_json
  end

  desc "generate plugin download metric from github"
  task :stats do
    puts "Collecting repo metrics ..."
    puts Pluginsync::Plugins.stats.to_yaml
  end
end

namespace :pr do
  desc "generate pull request for PLUGIN_CATALOG.md"
  task :catalog do
    puts "Collecting repo data for pull request ..."
    Pluginsync::Plugins.catalog_pr
  end

  desc "generate pull request for plugin_metadata.json in github.io"
  task :github_io do
    puts "Collecting repo data for pull request ..."
    Pluginsync::Plugins.githubio_pr
  end
end

namespace :notify do
  desc "send a slack notification"
  task :slack do
    Pluginsync::Notify::Slack.message "#build-snap", "Snap packages version <https://packagecloud.io/intelsdi-x/snap|#{@snap.pkgversion} now available.>"
  end
end
