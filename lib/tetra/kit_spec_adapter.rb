# encoding: UTF-8

module Tetra
  # encapsulates details of a kit needed by the spec file
  # retrieving them from other objects
  class KitSpecAdapter
    attr_reader :name
    attr_reader :version

    def initialize(project)
      @name = project.name
      @version = project.version
    end

    def public_binding
      binding
    end
  end
end
