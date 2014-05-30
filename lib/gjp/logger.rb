# encoding: UTF-8

require "singleton"
require "forwardable"
require "logger"

module Gjp
  # configures logging for this application
  class Logger
    include Singleton
    extend Forwardable

    def_delegators :@logger, :debug, :info, :warn, :error, :fatal, :level=

    def initialize
      @logger = ::Logger.new(STDERR)
      @logger.datetime_format = "%Y-%m-%d %H:%M "
      @logger.level = ::Logger::ERROR
      @logger.formatter = proc do |severity, _datetime, _progname, msg|
        "#{severity.chars.first}: #{msg}\n"
      end
    end
  end

  # convenience methods
  module Logging
    # convenience instance method
    def log
      Gjp::Logger.instance
    end
  end
end
