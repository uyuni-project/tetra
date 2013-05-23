# encoding: UTF-8

require "logger"

def init_logger(level)
  $log = Logger.new(STDERR)
  $log.level = if level == nil
    if very_very_verbose?
      Logger::DEBUG
    elsif very_verbose?
      Logger::INFO
    elsif verbose?
      Logger::WARN
    else
      Logger::ERROR
    end
  else
    level
  end
  
  $log.formatter = proc do |severity, datetime, progname, msg|
    "#{severity.chars.first}: #{msg}\n"
  end
end
