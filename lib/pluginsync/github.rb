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
      @log = Pluginsync.log

      attr_reader :name

      def initialize(name)
        @name = name
        @gh = Pluginsync::Github.client
        raise(ArgumentError, "#{name} is not a valid github repository (or your account does not have access to this private repo)") unless @gh.repository? name
        @repo = @gh.repo name
        @owner = @repo.owner.login
      end

      def content(path, default=nil)
        file = @gh.contents(@name, :path=>path)
        Base64.decode64 file.content
      rescue
        nil
      end

      def upstream
        if @repo.fork?
          @repo.parent.full_name
        else
          nil
        end
      end

      def ref_sha(ref, repo=@name)
        refs = @gh.refs repo
        if result = refs.find{ |r| r.ref == ref }
          result.object.sha
        else
          nil
        end
      end

      def sync_branch(branch, opt={})
        parent = opt[:origin] || upstream || raise(ArgumentError, "Repo #{@name} is not a fork and no origin specified for syncing.")
        origin_branch = opt[:branch] || 'master'

        origin_sha = ref_sha("refs/heads/#{origin_branch}", parent)

        fork_ref = "heads/#{branch}"
        fork_sha = ref_sha("refs/heads/#{branch}")

        if ! fork_sha
          @gh.create_ref(@name, fork_ref, origin_sha)
        elsif origin_sha != fork_sha
          begin
            @gh.update_ref(@name, fork_ref, origin_sha)
          rescue Octokit::UnprocessableEntity
            @log.warn "Fork #{name} is out of sync with #{parent}, syncing to #{name} #{origin_branch}"
            origin_sha = ref_sha("refs/heads/#{origin_branch}")
            @gh.update_ref(@name, fork_ref, origin_sha)
          end
        end
      end

      def update_content(path, content, opt={})
        branch = opt[:branch] || "master"

        raise(Argument::Error, "This tool cannot directly commit to #{INTEL_ORG} repos") if @name =~ /^#{INTEL_ORG}/
        raise(Argument::Error, "This tool cannot directly commit to master branch") if branch == 'master'

        message = "update #{path} by pluginsync tool"
        content = Base64.encode64 content

        ref = "heads/#{branch}"
        latest_commit = @gh.ref(@name, ref).object.sha
        base_tree = @gh.commit(@name, latest_commit).commit.tree.sha

        sha = @gh.create_blob(@name, content, "base64")
        new_tree = @gh.create_tree(
          @name,
          [ {
            :path => path,
            :mode => "100644",
            :type => "blob",
            :sha => sha
          } ],
          { :base_tree => base_tree }
        ).sha

        new_commit = @gh.create_commit(@name, message, new_tree, latest_commit).sha
        @gh.update_ref(@name, ref, new_commit) if branch
      end

      def create_pull_request(branch, message)
        @gh.create_pull_request(upstream, "master", "#{@repo.owner.login}:#{branch}", message)
      end

      def yml_content(path, default={})
        YAML.load(content(path))
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
          config.deep_merge(yml_content('.sync.yml'))
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
          "maintainer_url" => @repo.owner.html_url,
          "repo_name" => @repo.name,
          "repo_url" => @repo.html_url,
        }

        metadata = yml_content('metadata.yml')

        if @owner == Pluginsync::Github::INTEL_ORG
          metadata["download"] = {
            "s3_latest"       => s3_url('latest'),
            "s3_latest_build" => s3_url('latest_build'),
          }
        end

        metadata["name"] = Pluginsync::Util.plugin_capitalize metadata["name"] if metadata["name"]
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
          { "#{go['GOOS']}/#{arch}" => "https://s3-us-west-2.amazonaws.com/snap.ci.snap-telemetry.io/plugins/#{@repo.name}/#{build}/#{go['GOOS']}/#{arch}/#{@repo.name}" }
        end
      end
    end
  end
end
