# encoding: UTF-8

require "logger"

module Gjp

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new('/dev/null')
  end

  def logger
    Gjp.logger
  end

end
