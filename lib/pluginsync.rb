module Pluginsync
  LIBDIR = File.expand_path(File.dirname(__FILE__))
  PROJECT_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "..")

  $:.unshift(LIBDIR) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(LIBDIR)

  require 'pluginsync/util'
  require 'pluginsync/config'

  @@config = Pluginsync::Config.new

  def self.config
    @@config
  end

  require 'pluginsync/github'
  require 'pluginsync/plugins'
  require 'pluginsync/notify'
end

