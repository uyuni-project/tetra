# encoding: UTF-8

module Tetra
  # implements a to_archive method
  module Archivable
    include Logging

    # generates an archive and returns its name
    # this will archive source_paths starting from source_dir in
    # output/package_name/package_name.extension
    def _to_archive(project, package_name, source_dir, source_paths)
      full_destination_dir = File.join(project.full_path, "output", package_name)
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
