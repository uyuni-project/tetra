# frozen_string_literal: true

module Tetra
  # a packaged set of binary build-time dependencies
  class KitPackage
    extend Forwardable
    include Speccable

    attr_reader :name

    def_delegator :@project, :version
    def_delegator :@project, :name, :project_name

    def initialize(project)
      @project = project

      @name = "#{project.name}-kit"
    end

    def to_spec
      _to_spec(@project, name, "kit.spec",
               @project.packages_dir)
    end
  end
end
