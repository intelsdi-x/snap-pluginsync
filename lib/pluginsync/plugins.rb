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
      template = File.read(File.join(@config.path, "PLUGIN_CATALOG.md.erb"))
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

    def self.githubio_json
      result = metadata.collect do |i|
        {
          name: i["name"],
          type: i["type"].slice(0,1).capitalize + i["type"].slice(1..-1),
          description: i["description"],
          url: i["repo_url"],
        }
      end

      "myfcn(\n" + JSON.pretty_generate(result) + "\n)"
    end

    def self.pull_request(repo, repo_fork, branch, feature_branch, path, content, msg)
      source = Pluginsync::Github::Repo.new repo
      remote = Pluginsync::Github::Repo.new repo_fork

      remote.sync_branch(feature_branch, :branch => branch)

      current = source.content(path)

      if current != content
        @log.info "Updating #{path} in #{repo_fork} branch #{feature_branch}"

        remote.update_content(path, content, :branch => feature_branch)
        pr = remote.create_pull_request(branch, feature_branch, msg)
        @log.info "Creating pull request: #{pr.html_url}"
      else
        @log.info "No new updates to #{path}"
      end
    end

    def self.catalog_pr
      content = catalog
      pull_request(
        @config.plugin_catalog_md['repo'],
        @config.plugin_catalog_md['fork'],
        @config.plugin_catalog_md['branch'],
        @config.plugin_catalog_md['feature_branch'],
        @config.plugin_catalog_md['path'],
        content,
        "Updating plugins_catalog.md from plugins.yml"
      )
    end

    def self.githubio_pr
      content = githubio_json
      pull_request(
        @config.plugin_list_js['repo'],
        @config.plugin_list_js['fork'],
        @config.plugin_list_js['branch'],
        @config.plugin_list_js['feature_branch'],
        @config.plugin_list_js['path'],
        content,
        "Updating parsed plugin list from plugins.yml"
      )
    end

    def self.stats
      intel_repos = repos.reject{|r| r.owner != Pluginsync::Github::INTEL_ORG}
      intel_repos.collect{|r| r.metric}
    end
  end
end
