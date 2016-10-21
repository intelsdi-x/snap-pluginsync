require 'erb'
require 'set'
require 'pluginsync'
require 'pluginsync/github'

module Pluginsync
  module Plugins
    @github = Pluginsync::Github
    @config = Pluginsync.config
    @log = Pluginsync.log

    def self.repos
      @repos ||= Set.new plugins.collect do |p|
        begin
          Pluginsync::Github::Repo.new p
        rescue ArgumentError => e
          @log.error e.message
          nil
        end
      end
      @repos.reject{|p| p.nil?}
    end

    def self.plugins
      plugin_repo = Pluginsync::Github::Repo.new @config.plugins_yml["repo"]
      plugin_repo.yml_content @config.plugins_yml["path"]
    end

    def self.metadata
      repos.collect{|r| r.metadata}
    end

    def self.catalog
      template = File.read(File.join(@config.path, "PLUGIN_CATALOG.md"))
      @catalog ||= ERB.new(template, nil, '-').result
    end

    def self.wishlist
      data = []

      snap_issues = @github.issues 'intelsdi-x/snap'

      wishlist = snap_issues.find_all{|issue| issue.labels.find{|label| label.name =~ /^plugin-wishlist/}}
      wishlist.each do |issue|
        wish_label = issue.labels.find{|l| l.name =~ /^plugin-wishlist/}
        type = wish_label['name'].split('/').last
        data << {
          "number" => issue.number,
          "url" => "https://github.com/intelsdi-x/snap/issues/#{issue.number}",
          "description" => issue.title,
          "body" => issue.body,
          "type" => type,
        }
      end
      data
    end

    def self.pull_request
      catalog_repo = @config.plugin_catalog_md["repo"]
      catalog_path = @config.plugin_catalog_md["path"]

      fork_name = @config.plugin_catalog_md["fork"] || raise("Please configure plugin_catalog.md['fork'] in configuration.")

      origin_repo = Pluginsync::Github::Repo.new catalog_repo
      fork_repo = Pluginsync::Github::Repo.new fork_name

      fork_repo.sync_branch(@config.branch)

      current_catalog = origin_repo.content catalog_path

      if catalog != current_catalog
        @log.info "Updating plugins_catalog.md in #{fork_name} branch #{@config.branch}"
        fork_repo.update_content(catalog_path, catalog, :branch => @config.branch)

        pr = fork_repo.create_pull_request(@config.branch, "Updating plugins_catalog.md by pluginsync. [ci skip]")
        @log.info "Creating pull request: #{pr.html_url}"
      else
        puts "No new updates to plugin_catalog.md."
      end
    end
  end
end
