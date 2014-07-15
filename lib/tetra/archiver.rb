# encoding: UTF-8

module Tetra
  # generates file archives that accompany spec files
  class Archiver
    include Logging

    def initialize(project)
      @project = project
    end

    # generates an archive for the kit package
    def archive_kit
      destination_dir = File.join(@project.full_path, "output", "#{@project.name}-kit")
      FileUtils.mkdir_p(destination_dir)

      archive_single("kit", File.join(destination_dir, "#{@project.name}-kit.tar.xz"))
    end

    # generates an archive for a project's package based on its file list
    def archive_package(name)
      destination_dir = File.join(@project.full_path, "output", name)
      FileUtils.mkdir_p(destination_dir)

      archive_single(File.join("src", name), File.join(destination_dir, "#{name}.tar.xz"))
    end

    # archives a directory's contents to the destination file
    def archive_single(source_directory, destination_file)
      log.debug "creating #{destination_file}"
      @project.from_directory source_directory do
        `tar -cJf #{destination_file} *`
      end

      destination_file
    end
  end
end
