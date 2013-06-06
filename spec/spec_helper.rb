# encoding: UTF-8

require "gjp"
require "logger"

Gjp.logger = ::Logger.new(STDERR)
Gjp.logger.level = ::Logger::INFO
Gjp.logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity.chars.first}: #{msg}\n"
end
