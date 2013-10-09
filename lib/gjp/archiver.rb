# encoding: UTF-8

module Gjp
  # generates file archives that accompany spec files
  class Archiver
    include Logger

    def initialize(project)
      @project = project
    end

    # generates an archive for the kit package
    def archive_kit
      destination_dir = File.join(@project.full_path, "output", "#{@project.name}-kit")
      FileUtils.mkdir_p(destination_dir)
      destination_file = File.join(destination_dir, "#{@project.name}-kit.tar.xz")

      archive("kit", destination_file)
      
      Pathname.new(destination_file).relative_path_from Pathname.new(@project.full_path)
    end

    # generates an archive for a project's package based on its file list
    def archive_package(name)
      destination_dir = File.join(@project.full_path, "output", name)
      FileUtils.mkdir_p(destination_dir)
      destination_file = File.join(destination_dir, "#{name}.tar.xz")

      archive(File.join("src", name), destination_file)

      Pathname.new(destination_file).relative_path_from Pathname.new(@project.full_path)
    end

    # archives a folder's contents to the destination file
    def archive(folder, destination_file)
      @project.from_directory folder do
        `tar -cJf #{destination_file} *`
      end
    end
  end
end
