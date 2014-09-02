# encoding: UTF-8

module Tetra
  # implements a to_archive method
  module Archiver
    include Logging
    # expected attributes:
    #   project (Tetra::Project)
    #   package_name (string)
    #   archive_source_dir (string)
    #   archive_destination_dir (string)

    # generates an archive and returns its name
    def to_archive
      destination_dir = File.join(project.full_path, "output", archive_destination_dir)
      FileUtils.mkdir_p(destination_dir)

      project.from_directory(archive_source_dir) do
        archive(archive_source_dir, File.join(destination_dir, "#{package_name}.tar.xz"))
      end
    end

    # archives a directory's contents to the destination file
    def archive(_source_directory, destination_file)
      log.debug "creating #{destination_file}"
      `tar -cJf #{destination_file} *`

      destination_file
    end
  end
end
