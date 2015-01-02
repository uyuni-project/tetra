# encoding: UTF-8

module Tetra
  # a packaged set of binary build-time dependencies
  class KitPackage
    extend Forwardable
    include Archivable
    include Speccable

    attr_reader :name
    attr_reader :version
    def_delegator :@project, :name, :project_name

    def initialize(project)
      @project = project

      @name = "#{project.name}-kit"
      @version = "#{project.version}"
    end

    def to_archive
      _to_archive(@project, name, "kit",
                  @project.packages_dir)
    end

    def to_spec
      _to_spec(@project, name, "kit.spec",
               @project.packages_dir)
    end
  end
end
