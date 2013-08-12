# encoding: UTF-8

require "logger"

module Gjp
  module Logger
    @@logger = nil

    # returns a logger instance
    def self.log
      if @@logger == nil
        @@logger = ::Logger.new(STDERR)
        @@logger.datetime_format = "%Y-%m-%d %H:%M "
        @@logger.level = ::Logger::ERROR
        @@logger.formatter = proc do |severity, datetime, progname, msg|
          "#{severity.chars.first}: #{msg}\n"
        end
      end
      @@logger
    end

    # convenience instance method
    def log
      Gjp::Logger.log
    end
  end
end
