module Pluginsync
  module Notify
    module Slack
      require "slack-ruby-client"

      def self.client
        @client ||= (
          ::Slack.configure do |config|
            file = File.join ENV["HOME"], ".slack"
            conf = YAML.load_file file rescue conf = {}
            config.token = ENV["SLACK_API_TOKEN"] || conf["API_TOKEN"] || raise(ArgumentError, "Missing slack api token in config: #{file}.")
          end

          ::Slack::Web::Client.new
        )
      end

      def self.message(channel, text)
        client.chat_postMessage(
          channel: channel,
          as_user: true,
          text: text,
        )
      end
    end
  end
end
