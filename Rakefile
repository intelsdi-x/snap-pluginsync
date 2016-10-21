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
end
task :default => :help

namespace :plugin do
  desc "generate plugin catalog"
  task :catalog do
    puts Pluginsync::Plugins.catalog
  end

  desc "generate plugin metadata"
  task :metadata do
    puts JSON.pretty_generate Pluginsync::Plugins.metadata
  end

  desc "generate plugin wishlist"
  task :wishlist do
    puts Pluginsync::Plugins.wishlist
  end

  desc "generate plugin json for github.io page"
  task :github_io do
    data = Pluginsync::Plugins.metadata
    result = data.collect do |i|
      {
        name: i["name"],
        type: i["type"].slice(0,1).capitalize + i["type"].slice(1..-1),
        description: i["description"],
        url: i["repo_url"],
      }
    end

    puts "myfcn(\n" + JSON.pretty_generate(result) + "\n)"
  end

  desc "generate pull request for plugin_metadata.json"
  task :pull_request do
    Pluginsync::Plugins.pull_request
  end
end

namespace :notify do
  desc "send a slack notification"
  task :slack do
    Pluginsync::Notify::Slack.message "#build-snap", "Snap packages version <https://packagecloud.io/nanliu/snap|#{@snap.pkgversion} now available.>"
  end
end
