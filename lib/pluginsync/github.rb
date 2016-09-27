require 'netrc'
require 'octokit'

module Pluginsync
  module Github
    INTEL_ORG = Pluginsync.config.org

    Octokit.auto_paginate = true
    @@client = Octokit::Client.new(:netrc => true) if File.exists? File.join(ENV["HOME"], ".netrc")

    begin
      require 'faraday-http-cache'
      stack = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache, :serializer => Marshal
        builder.use Octokit::Response::RaiseError
        builder.adapter Faraday.default_adapter
      end
      Octokit.middleware = stack
    rescue LoadError
    end

    def self.client
      @@client || Octokit
    end

    def self.issues name
      client.issues name
    end

    def self.repo name
      client.repo name
    end

    class Repo
      attr_reader :name 

      def initialize(name)
        @name = name
        @gh = Pluginsync::Github.client
        @repo = @gh.repo name
        @owner = @repo.owner.login
      end

      def content(path, default=nil)
        file = @gh.contents(@name, :path=>path)
        YAML.load(Base64.decode64(file.content))
      rescue
        default
      end

      def plugin_name
        @name.match(/snap-plugin-(collector|processor|publisher)-(.*)$/)
        @plugin_name = Pluginsync::Util.plugin_capitalize($2) || raise(ArgumentError, "Unable to parse plugin name from repo: #{@name}")
      end

      def plugin_type
        @plugin_type ||= case @name
          when /collector/
            "collector"
          when /processor/
            "processor"
          when /publisher/
            "publisher"
          else
            "unknown"
          end
      end

      def sync_yml
        @sync_yml ||= fetch_sync_yml.extend Hashie::Extensions::DeepFetch
      end

      ##
      # For intelsdi-x plugins merge pluginsync config_defaults with repo .sync.yml
      #
      def fetch_sync_yml
        if @owner == Pluginsync::Github::INTEL_ORG
          path = File.join(Pluginsync::PROJECT_PATH, 'config_defaults.yml')
          config = Pluginsync::Util.load_yaml(path)
          config.extend Hashie::Extensions::DeepMerge
          config.deep_merge(content('.sync.yml', {}))
        else
          {}
        end
      end

      def metadata
        result = {
          "name" => plugin_name,
          "type" =>  plugin_type,
          "description" => @repo.description || 'No description available.',
          "maintainer" => @owner,
          "repo_name" => @repo.name,
          "repo_url" => @repo.html_url,
        }

        metadata = content('metadata.yml', {})

        if @owner == Pluginsync::Github::INTEL_ORG
          metadata["download"] = {
            "s3_latest"       => s3_url('latest'),
            "s3_latest_build" => s3_url('latest_build'),
          }
        end

        metadata["github_release"] = @repo.html_url + "/releases/latest" if @gh.releases(@name).size > 0
        metadata["maintainer"] = "intelsdi-x" if metadata["maintainer"] == "core"

        result.merge(metadata)
      end

      def s3_url(build)
        matrix = sync_yml.deep_fetch :global, "build", "matrix"
        matrix.collect do |go|
          arch = if go["GOARCH"] == "amd64"
                   "x86_64"
                 else
                   go["GOARCH"]
                 end
          { "#{go['GOOS']}/#{arch}" => "http://snap.ci.snap-telemetry.io/plugins/#{@repo.name}/#{build}/#{go['GOOS']}/#{arch}/#{@repo.name}" }
        end
      end
    end
  end
end
