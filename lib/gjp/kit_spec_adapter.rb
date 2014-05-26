# encoding: UTF-8

module Gjp
  # encapsulates details of a kit needed by the spec file
  # retrieving them from other objects
  class KitSpecAdapter
    attr_reader :name
    attr_reader :version
    attr_reader :archives

    def initialize(project)
      @name = project.name
      @version = project.version

      @archives =
        project.from_directory do
          ["#{name}-kit.tar.xz"] +
          Dir.entries("output/#{name}-kit")
            .select { |f| f =~ /_[0-9]+.tar.xz$/ }
            .sort
        end
    end

    def public_binding
      binding
    end
  end
end

