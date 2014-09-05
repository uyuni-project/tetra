# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class JarKitItem
    attr_reader :provides_symbol
    attr_reader :provides_version

    def initialize(path)
      _, name = Pathname.new(path).split
      @provides_symbol = "jar(#{name})"
      @provides_version = Digest::SHA1.file(path).hexdigest
    end
  end
end
