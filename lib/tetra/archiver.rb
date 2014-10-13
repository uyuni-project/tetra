# encoding: UTF-8

module Tetra
  # implements a to_archive method
  module Archiver
    include Logging
    # expected attributes:
    #   project (Tetra::Project)
    #   package_name (string)
    #   source_dir (string)
    #   source_paths ([string])
    #   destination_dir (string)

    # generates an archive and returns its name
    # this will archive source_paths starting from source_dir in
    # destination_dir + package_name + extension
    def to_archive
      full_destination_dir = File.join(project.full_path, "output", destination_dir)
      FileUtils.mkdir_p(full_destination_dir)

      project.from_directory(source_dir) do
        destination_path = File.join(full_destination_dir, "#{package_name}.tar.xz")
        log.debug "creating #{destination_path}"

        `tar -cJf #{destination_path} #{source_paths.join(" ")}`

        destination_path
      end
    end
  end
end
