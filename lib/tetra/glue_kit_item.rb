# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class GlueKitItem
    def initialize(project)
      @name = project.name
      @version = project.version
    end

    def provides_symbol
      "kit-glue(#{@name})"
    end

    def provides_version
      @version
    end
  end
end
