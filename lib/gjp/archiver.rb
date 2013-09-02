# encoding: UTF-8

module Gjp
  # generates file archives that accompany spec files
  class Archiver
    include Logger

    def initialize(project)
      @project = project
    end

    # generates an archive for the project's kit package based on
    # its file list
    def archive_kit
      list_file = File.join(@project.full_path, "file_lists/kit")
      if not File.exist? list_file
        return nil
      end
      destination_file = File.join(@project.full_path, "archives/#{@project.name}-kit.tar.xz")

      @project.from_directory "kit" do
        archive list_file, destination_file
      end
      
      Pathname.new(destination_file).relative_path_from Pathname.new(@project.full_path)
    end

    # generates an archive for a project's source package based on
    # its file list
    def archive_src(name)
      list_file = File.join(@project.full_path, "file_lists/#{name}_input")
      if not File.exist? list_file
        return nil
      end
      destination_file = File.join(@project.full_path, "archives/#{@project.name}-#{name}.tar.xz")

      @project.from_directory File.join("src", name) do
        archive list_file, destination_file
      end

      Pathname.new(destination_file).relative_path_from Pathname.new(@project.full_path)
    end

    # compresses files specified in the list file to the destination file
    def archive(list_file, destination_file)
      `tar --files-from=#{list_file} -cJf #{destination_file}`
    end
  end
end
