module Pluginsync
  LIBDIR = File.expand_path(File.dirname(__FILE__))
  PROJECT_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "..")

  $:.unshift(LIBDIR) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(LIBDIR)

  require 'logger'
  require 'pluginsync/util'
  require 'pluginsync/config'

  @@config = Pluginsync::Config.new
  @@log = Logger.new(STDOUT)
  @@log.level = @@config.log_level

  def self.config
    @@config
  end

  def self.log
    @@log
  end

  require 'pluginsync/github'
  require 'pluginsync/plugins'
  require 'pluginsync/notify'
end

