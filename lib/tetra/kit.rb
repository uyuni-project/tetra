# encoding: UTF-8

module Tetra
  # represents a set of binary dependency packages
  class Kit
    include Logging

    def initialize(project)
      @project = project
    end

    def items
      managed_items = maven_kit_items + jar_kit_items

      managed_items + glue_kit_items(managed_items)
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
      @project.from_directory(File.join("kit", "jars")) do
        Pathname.new(".").children.select do |child|
          child.to_s =~ /.jar$/
        end.sort.map do |jar|
          Tetra::JarKitItem.new(@project, jar)
        end
      end
    end

    def glue_kit_items(managed_items)
      managed_files = managed_items.map do |item|
        item.source_paths.map do |e|
          Pathname.new(File.join(item.source_dir, e)).cleanpath
        end
      end.flatten

      unmanaged_files = []

      @project.from_directory do
        Find.find("kit") do |file|
          pathname = Pathname.new(file)
          if !managed_files.include?(pathname) && !File.directory?(pathname)
            unmanaged_files << pathname.relative_path_from(Pathname.new("kit"))
          end
        end
      end

      [Tetra::GlueKitItem.new(@project, unmanaged_files)]
    end
  end
end
