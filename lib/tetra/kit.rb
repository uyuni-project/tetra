# encoding: UTF-8

module Tetra
  # represents a package of binary dependencies
  class Kit
    extend Forwardable
    include SpecGenerator
    include Logging

    def_delegator :@project, :name
    def_delegator :@project, :version

    # implement to_archive
    include Archiver
    attr_reader :source_dir
    attr_reader :source_paths
    attr_reader :destination_dir

    def initialize(project)
      @project = project

      @source_dir = "kit"
      @source_paths = ["*"]
      @destination_dir = "#{@project.name}-kit"
    end

    def items
      maven_kit_items + jar_kit_items + glue_kit_items
    end

    def maven_kit_items
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
          Tetra::MavenKitItem.new(@project, pom, files_in_dir[File.dirname(pom)])
        end
      end
    end

    def jar_kit_items
      @project.from_directory(File.join("kit")) do
        Pathname.new("jars").children.select do |child|
          child.to_s =~ /.jar$/
        end.sort.map do |jar|
          Tetra::JarKitItem.new(@project, jar)
        end
      end
    end

    def glue_kit_items
      [Tetra::GlueKitItem.new(@project)]
    end

    # needed by SpecGenerator
    attr_reader :project

    def package_name
      "#{@project.name}-kit"
    end

    def spec_dir
      "kit"
    end

    def template_spec_name
      "kit.spec"
    end
  end
end
