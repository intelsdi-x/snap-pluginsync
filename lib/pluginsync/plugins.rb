require 'erb'
require 'set'
require 'pluginsync'
require 'pluginsync/github'

module Pluginsync
  module Plugins
    @github = Pluginsync::Github
    @config = Pluginsync.config

    def self.repos
      @repos ||= Set.new plugins.collect{ |p| Pluginsync::Github::Repo.new(p) }
    end

    def self.plugins
      plugin_repo = Pluginsync::Github::Repo.new @config.plugins_yml["repo"]
      result = plugin_repo.content @config.plugins_yml["path"]
    end

    def self.metadata
      repos.collect{|r| r.metadata}
    end

    def self.catalog
      template = File.read(File.join(@config.path, "PLUGINS_CATALOG.md"))
      ERB.new(template, nil, '-').result
    end

    def self.wishlist
      data = []

      snap_issues = @github.issues 'intelsdi-x/snap'

      wishlist = snap_issues.find_all{ |issue| issue.labels.find{|label| label.name=='plugin-wishlist'} }
      wishlist.each do |issue|
        data << {
          "number" => issue.number,
          "url" => "https://github.com/intelsdi-x/snap/issues/#{issue.number}",
          "description" => issue.title,
          "body" => issue.body,
        }
      end
      data
    end

  end
end
