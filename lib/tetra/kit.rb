# encoding: UTF-8

module Tetra
  # represents a package of binary dependencies
  class Kit
    extend Forwardable
    include SpecGenerator

    def_delegator :@project, :name
    def_delegator :@project, :version

    def initialize(project)
      @project = project
    end

    # needed by SpecGenerator
    attr_reader :project

    def package_name
      "#{@project.name}-kit"
    end

    def spec_path
      File.join("kit", package_name)
    end

    def template_spec_name
      "kit.spec"
    end

    def spec_tag
      "kit"
    end
  end
end
