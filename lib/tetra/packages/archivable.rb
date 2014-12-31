# encoding: UTF-8

module Tetra
  # adds methods to generate a tarball from a package object
  module Archivable
    include Logging

    # generates an archive and returns its name
    # this will archive files in source_dir in
    # destination_dir/name/name.tar.xz
    def _to_archive(project, name, source_dir, destination_dir)
      full_destination_dir = File.join(project.full_path, destination_dir, name)
      log.debug "creating #{full_destination_dir}"
      FileUtils.mkdir_p(full_destination_dir)

      project.from_directory(source_dir) do
        destination_path = File.join(full_destination_dir, "#{name}.tar.xz")
        log.debug "tarring to #{destination_path}"

        `tar -cJf #{destination_path} *`

        destination_path
      end
    end
  end
end
