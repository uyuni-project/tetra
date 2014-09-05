# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class GlueKitItem
    attr_reader :provides_symbol
    attr_reader :provides_version

    def initialize(project)
      @provides_symbol = "kit-glue(#{project.name})"
      @provides_version = project.version
    end
  end
end
