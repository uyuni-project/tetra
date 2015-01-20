# encoding: UTF-8

module Tetra
  # adds methods to generate a tarball from a package object
  module Archivable
    include Logging

    # generates an archive and returns its name
    # this will archive files in source_dir in
    # destination_dir/name/name.tar.xz
    def _to_archive(project, name, source_dir, destination_dir)
      project.from_directory do
        full_destination_dir = File.join(destination_dir, name)
        Tetra::Tar.new.archive(name, source_dir, full_destination_dir)
      end
    end
  end
end
