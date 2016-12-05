module Pluginsync
  class Config
    attr_reader :plugins_yml, :plugin_catalog_md, :plugin_list_js, :org, :path, :branch, :log_level

    def initialize
      @path = File.expand_path(File.join(File.dirname(__FILE__), "../.."))
      config = File.join @path, 'modulesync.yml'

      if File.exists? config
        settings = Pluginsync::Util.load_yaml(config)
        settings = default.merge settings
      else
        settings = default
      end

      @plugins_yml = settings["plugins.yml"]
      @plugin_catalog_md = settings["plugin_catalog.md"]
      @plugin_list_js = settings["plugin_list.js"]
      @org = settings["namespace"]
      @branch = settings["branch"]
      @log_level = settings["log_level"] || Logger::INFO
    end

    def default
      {
        "plugins.yml" => {
          "repo" =>  "intelsdi-x/snap",
          "path" => "docs/plugins.yml",
        },
        "plugin_catalog.md" => {
          "repo" =>  "intelsdi-x/snap",
          "path" => "docs/PLUGIN_CATALOG.md",
        },
        "org" => "intelsdi-x",
        "fork" => ENV["GITHUB_USERNAME"] || ENV["USERNAME"],
      }
    end
  end
end
