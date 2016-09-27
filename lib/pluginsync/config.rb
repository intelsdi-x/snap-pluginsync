module Pluginsync
  class Config
    attr_reader :plugins_yml, :org, :path

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
      @org = settings["namespace"]
    end

    def default
      {
        "plugins.yml" => {
          "repo" =>  "intelsdi-x/snap",
          "path" => "docs/plugins.yml",
        },
        "org" => "intelsdi-x",
      }
    end
  end
end
