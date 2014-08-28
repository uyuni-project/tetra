# encoding: UTF-8

module Tetra
  # represents a package of binary dependencies
  class Kit
    extend Forwardable
    include SpecGenerator
    include Archiver
    include Logging

    def_delegator :@project, :name
    def_delegator :@project, :version

    def initialize(project)
      @project = project
    end

    def binary_packages
      @project.from_directory(File.join("kit", "m2")) do
        files_in_dir = {}
        poms = []
        Find.find(".") do |file|
          dir = File.dirname(file)
          if files_in_dir.key?(dir)
            files_in_dir[dir] << file
          else
            files_in_dir[dir] = [file]
          end

          if file =~ /\.pom$/
            log.debug "pom found in #{file}"
            poms << file
          end
        end

        poms.map do |pom|
          Tetra::BinaryPackage.new(pom, files_in_dir[File.dirname(pom)] - [pom])
        end
      end
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

    # needed by Archiver
    def archive_source_dir
      "kit"
    end

    def archive_destination_dir
      "#{@project.name}-kit"
    end
  end
end
